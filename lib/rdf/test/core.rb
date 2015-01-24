require 'linkeddata'
require 'sparql'
require 'restclient/components'
require 'rack/cache'
require 'fileutils'
require 'json-compare'

module RDF::Test
  ##
  # Core utilities used for generating and checking test cases
  module Core
    MANIFEST_FRAME = File.join(PUB_DIR, "context.jsonld")
    BASE           = "fix:me/"

    # Internal representation of manifest
    class Manifest < JSON::LD::Resource
      attr_accessor :options

      def initialize(json, options = {})
        STDERR.puts "Create manifest object"
        @options = options.merge(context: json['@context'])
        super
      end

      def entries
        # Map entries to resources
        STDERR.puts "Load entries" unless @entries
        @entries ||= attributes['entries'].map {|e| Entry.new(e, options)}
      end

      ##
      # Return test details, including doc text, sparql, and extracted results
      #
      # @param [String] uri of test
      # @return [Entry]
      def entry(uri)
        entries.detect {|te| te.id == uri}
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :test_uri

      def initialize(json, options = {})
        @options = options
        @test_uri = @options.fetch(:test_uri)
        super
      end

      def id; self.attributes['id']; end # because we don't use @id

      # Alias data and query
      def action_body
        @action_body ||= RestClient.get(action_loc.to_s)
      end

      def result_body
        @result_body ||= RestClient.get(result_loc.to_s)
      end

      def action_loc; test_uri.join(action).to_s; end
      def result_loc; test_uri.join(result).to_s; end

      def evaluate?
        Array(attributes['type']).join(" ").match(/Eval/)
      end

      def syntax?
        Array(attributes['type']).join(" ").match(/Syntax/)
      end

      def positive?
        !Array(attributes['type']).join(" ").match(/Negative/)
      end
      
      def negative?
        !positive?
      end

      def json?
        !Array(attributes['type']).join(" ").match(/json/i)
      end

      def sparql?
        !Array(attributes['type']).join(" ").match(/sparql/i)
      end

      def attributes
        super.merge(
          action_loc:     self.action_loc,
          action_body:    self.action_body,
          result_loc:     self.result_loc,
          result_body:    self.result_body
        )
      end

      def inspect
        super.sub('>', "\n" +
        "  json?: #{json?.inspect}\n" +
        "  sparql?: #{sparql?.inspect}\n" +
        "  syntax?: #{syntax?.inspect}\n" +
        "  positive?: #{positive_test?.inspect}\n" +
        "  evaluate?: #{evaluate?.inspect}\n" +
        ">"
      )
      end

      # Don't de-resolve
      def deresolve; attributes; end

      # Add context
      def to_json
        attributes.merge('@context' => context).to_json
      end

      # Context of this entry
      # @return [Hash{String => Object}]
      def context; @options[:context]; end

      ##
      # Performs a given unit test given the extractor URL.
      #
      # Updates this test with the result and test status of PASS/FAIL
      #
      # @override run(processor_url, options = {}, &block)
      #   @param [RDF::URI, String] processor_url The CSVW extractor web service.
      #   @param [Hash{Symbol => Object}] options
      #   @option options [Logger] logger
      #   @yield result_body, status
      #   @yieldparam [String] result_body Returned document
      #   @yieldparam [String] status Pass/Fail/Error result
      #   @return [Object] yield results
      #
      # @override run(processor_url)
      #   @param [RDF::URI, String] processor_url The CSVW extractor web service.
      #   @param [Hash{Symbol => Object}] options
      #   @option options [Logger] logger
      #   @return [Boolean] PASS/FAIL result
      def run(processor_url, options = {})
        logger = options.fetch(:logger) {
          l = Logger.new(STDOUT)  # In case we're not invoked from rack
          l.level = Logger::DEBUG
          l
        }
        # Build the RDF extractor URL
        # FIXME: include other processor control parameters
        processor_url = ::URI.decode(processor_url) + action_loc.to_s

        logger.info "Run #{self.inspect}"
        logger.debug "extract from: #{processor_url}"

        error = nil

        # Retrieve the remote graph
        # Use the actual result file if using the reflector
        processor_url = result_loc if processor_url.start_with?('http://example.org/reflector')
        begin
          # Indicate format requested; default uses standard RDF mime-types
          headers = json? ? {"Accept" => "application/json"} : {}

          extracted = RestClient.get(processor_url, headers.merge(cache_control: 'no-cache'))
          logger.debug "extracted:\n#{extracted}, content-type: #{extracted.headers[:content_type].inspect}"

          result = if json?
            # Read both as JSON and compare
            extracted_object = JSON.parse(extracted)
            result_object = JSON.parse(result_body)
            ::JsonCompare.get_diff(extracted_object, result_object).empty?
          else
            # parse extracted as RDF
            reader = RDF::Reader.for(sample: extacted_doc)
            graph = RDF::Graph.new << reader.new(extracted)
            logger.debug "extracted:\n#{graph.count} statements"
            if sparql?
              SPARQL::Grammer.open(result_loc) do |query|
                graph.query(query)
              end
            else
              result_graph = RDF::Graph.load(result_loc)
              graph.isomorphic?(result_graph)
            end
          end

          result = !result if negative?
          status = result ? "Pass" : "Fail"
        rescue RestClient::ResourceNotFound => e
          logger.error "Extraction error: #{e.message}"
          extracted, error, status = nil, e, "Error"
          result = false
        rescue
          logger.error "Extraction exception: #{$!.inspect}"
          error, status = $!, "Error"
          result = false
        end

        if block_given?
          yield extracted, status, error
        else
          result
        end
      end
    end

    ##
    # Proxy the Manifest resource
    #
    # @return [RestClient::Resource]
    def manifest_ttl
      RestClient.get(RDF::URI(settings.test_uri).join("manifest.ttl").to_s)
    end
    module_function :manifest_ttl

    ##
    # Return the Manifest source
    #
    # Generate a JSON-LD compatible with framing in MANIFEST_FRAME
    def manifest_json
      local_manifest = File.join(CACHE_DIR, "#{settings.short_name}-manifest.json")
      ttl_time = Time.parse(manifest_ttl.headers[:last_modified])
      unless File.exist?(local_manifest) && File.mtime(local_manifest) >= ttl_time
        FileUtils.mkdir_p(CACHE_DIR)
        File.open(local_manifest, "w") do |f|
          graph = RDF::Graph.new << RDF::Turtle::Reader.new(manifest_ttl)
          JSON::LD::API.fromRDF(graph) do |expanded|
            JSON::LD::API.frame(expanded, MANIFEST_FRAME) do |framed|
              # Extract first object in @graph
              framed = framed['@graph'].first.merge('@context' => framed['@context'])

              json = framed.to_json(JSON::LD::JSON_STATE).gsub(BASE, "")
              f.write json
            end
          end
        end
      end
      File.read(local_manifest)
    rescue
      FileUtils.rm local_manifest if File.exist?(local_manifest)
      raise
    end
    module_function :manifest_json
  end
end
