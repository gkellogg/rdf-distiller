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
    MANIFEST_FRAME = ::JSON.parse(File.read File.join(PUB_DIR, "context.jsonld")).freeze
    DEFAULT_MANIFEST = File.join(PUB_DIR, "manifest.ttl").freeze
    BASE           = "fix:me/"

    # Internal representation of manifest
    class Manifest < JSON::LD::Resource
      attr_accessor :options
      attr_accessor :local_manifest
      attr_accessor :remote_manifest

      # Find a (possibly cached) manifest based on it's ID by loading the graph at that location
      # @param [String] id
      # @param [Hash{Symbol => Object}] options
      # @option options [Logger] :logger
      def self.find(id, options = {})
        (@manfests ||= {})[id] ||= begin
          local_manifest = File.join(CACHE_DIR, "#{id.hash}-manifest.json")
          remote_manifest = id == 'default' ? DEFAULT_MANIFEST : id
          Manifest.new(local_manifest, remote_manifest, options)
        end
      end

      def title; attributes['rdfs:label']; end
      def description; attributes['rdfs:comment']; end

      ##
      # Initialize a Manifest object from its parsed JSON-LD representation
      # @param [String] local_manifest
      # @param [Hash{Symbol => Object}] options
      # @option options [Logger] :logger
      def initialize(local_manifest, remote_manifest, options = {})
        @local_manifest = local_manifest
        @remote_manifest = remote_manifest
        @options = options
        node = ::JSON.parse(self.to_json)
        STDERR.puts "Create manifest object"
        @options[:context] = node['@context']
        super(node)
      end

      def entries
        # Map entries to resources
        STDERR.puts "Load entries" unless @entries
        @entries ||= Array(attributes['entries']).map {|e| Entry.new(e, options)}
      end

      ##
      # Return test details, including doc text, sparql, and extracted results
      #
      # @param [String] uri of test
      # @return [Entry]
      def entry(uri)
        entries.detect {|te| te.id == uri}
      end

      # Return local manifest
      def to_json
        local_time = File.mtime(local_manifest) rescue Time.new(0)

        remote_time = case remote_manifest
        when DEFAULT_MANIFEST
         File.mtime(remote_manifest)
        else
          Time.parse(RestClient.get(remote_manifest).headers[:last_modified])
        end rescue Time.new(0)

        if options[:logger]
          options[:logger].debug "Manifest.find: local: #{local_manifest}(#{local_time}) remote: #{remote_manifest}(#{remote_time})"
        end

        unless local_time > remote_time
          # Build JSON-LD version of manifest
          FileUtils.mkdir_p(CACHE_DIR)
          File.open(local_manifest, "w") do |f|
            graph = RDF::Graph.load(remote_manifest)
            JSON::LD::API.fromRDF(graph) do |expanded|
              frame = MANIFEST_FRAME.dup
              # Make relative URIs
              frame['@context']['@base'] = remote_manifest unless remote_manifest == DEFAULT_MANIFEST
              JSON::LD::API.frame(expanded, frame) do |framed|
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

      # Create Turtle representation of manifest
      def to_ttl
        ::JSON::LD::Reader.new(@attributes) do |reader|
          reader.dump(:ttl, prefixes: reader.prefixes, standard_prefixes: true)
        end
        end
        ::JSON::LD::API.toRdf(@attributes) do |statement|
      end
    end

    class Entry < JSON::LD::Resource
      attr_accessor :base

      def initialize(json, options = {})
        @options = options
        @base = RDF::URI(@options.fetch(:context).fetch('@base'))
        super
      end

      def id; self.attributes['id']; end # because we don't use @id

      # Alias data and query
      def action_body
        @action_body ||= RDF::Util::File.open_file(action_loc.to_s).read
      end

      def result_body
        @result_body ||= RDF::Util::File.open_file(result_loc.to_s).read if result_loc
      end

      def action_loc; base.join(action).to_s; end
      def result_loc; base.join(result).to_s if result.is_a?(String); end

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
        Array(attributes['type']).join(" ").match(/(tojson|compacttest|expandtest|flattentest|frametest|fromrdftest)/i)
      end

      def sparql?
        Array(attributes['type']).join(" ").match(/sparql/i)
      end

      def attributes
        super.merge(
          action_loc:     self.action_loc,
          action_body:    self.action_body
        ).merge(
          {result_loc: self.result_loc, result_body: self.result_body}.keep_if {self.result}
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
      #   @param [RDF::URI, String] processor_url The RDF extractor web service or SPARQL endpoint.
      #   @param [Hash{Symbol => Object}] options
      #   @option options [Logger] :logger
      #   @yield result_body, status
      #   @yieldparam [String] result_body Returned document
      #   @yieldparam [String] status Pass/Fail/Error result
      #   @return [Object] yield results
      #
      # @override run(processor_url)
      #   @param [RDF::URI, String] processor_url The RDF extractor web service or SPARQL endpoint.
      #   @param [Hash{Symbol => Object}] options
      #   @option options [Logger] :logger
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
          headers = {
            "User-Agent"    => "Ruby-RDF-Test/#{RDF::Test::VERSION}",
            "Cache-Control" => "no-cache"
          }
          # Indicate format requested; default uses standard RDF mime-types
          headers['Accept'] = 'application/json' if json?

          extracted = RDF::Util::File.open_file(processor_url, use_net_http: true, headers: headers)
          content_type = extracted.content_type
          extracted = extracted.read
          logger.debug "extracted:\n#{extracted}, content-type: #{content_type.inspect}"

          result = if json?
            # Read both as JSON and compare
            extracted_object = JSON.parse(extracted)
            result_object = JSON.parse(result_body)
            ::JsonCompare.get_diff(extracted_object, result_object).empty?
          else
            # parse extracted as RDF
            reader = RDF::Reader.for(
              content_type: content_type,
              sample: extracted
            ) || RDF::NTriples::Reader
            graph = RDF::Repository.new << reader.new(extracted)
            logger.debug "extracted:\n#{graph.count} statements"
            if sparql?
              SPARQL::Grammer.open(result_loc) do |query|
                graph.query(query)
              end
            elsif evaluate?
              result_graph = RDF::Repository.load(result_loc)
              graph.isomorphic?(result_graph)
            else
              true
            end
          end

          result = !result if negative?
          status = result ? "Pass" : "Fail"
        rescue RestClient::ResourceNotFound, IOError => e
          logger.error "Extraction error: #{e.message}"
          extracted, error, status = nil, e, negative? ? "Pass" : "Error"
          result = negative?
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
  end
end
