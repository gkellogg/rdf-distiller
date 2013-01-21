require 'sinatra/sparql'
require 'sinatra/partials'
require 'sinatra/respond_to'
require 'erubis'
require 'linkeddata'
require 'rdf/distiller/extensions'
require 'uri'

module RDF::Distiller
  class Application < Sinatra::Base
    register Sinatra::RespondTo
    register Sinatra::SPARQL
    helpers Sinatra::Partials
    set :views, ::File.expand_path('../views',  __FILE__)
    DOAP_NT = File.expand_path("../../../../etc/doap.nt", __FILE__)
    DOAP_JSON = File.expand_path("../../../../etc/doap.jsonld", __FILE__)

    set :public_folder, File.expand_path("../../../../public", __FILE__)
    mime_type "sse", "application/sse+sparql-query"
    before do
      $logger.info "[#{request.path_info}], #{params.inspect}, #{format}, #{request.accept.inspect}"
    end

    get '/' do
      cache_control :public, :must_revalidate, :max_age => 60
      result = erb :index, :locals => {:title => "Ruby Linked Data Service"}
      etag result.hash
      result
    end

    get '/about' do
      cache_control :public, :must_revalidate, :max_age => 60
      haml :about, :locals => {:title => "About the Ruby Linked Data Service"}
    end

    get '/doap' do
      cache_control :public, :must_revalidate, :max_age => 60
      case format
      when :nt
        etag Digest::SHA1.hexdigest File.read(DOAP_NT)
        headers "Content-Type" => "application/n-triples"
        body File.read(DOAP_NT)
      when :json, :jsonld
        etag Digest::SHA1.hexdigest File.read(DOAP_JSON)
        headers "Content-Type" => format == :jsonld ? "application/ld+json" : "application/json"
        body File.read(DOAP_JSON)
      when :html
        etag Digest::SHA1.hexdigest File.read(DOAP_JSON)
        projects = ::JSON.parse(File.read(DOAP_JSON))['@graph']
        
        # Fix dc:created and doap:helper entries to be normalized
        projects.each do |p|
          devs = p['doap:developer'].inject({}) {|memo, h| memo[h['@id']] = h if h.is_a?(Hash); memo}
          p['dc:creator'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
          p['doap:helper'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
        end
        haml :doap, :locals => {
          :title => "Project Information on included Gems",
          :projects => projects
        }
      else
        etag Digest::SHA1.hexdigest File.read(DOAP_NT)
        doap
      end
    end

    get '/distiller' do
      cache_control :public, :must_revalidate, :max_age => 60
      distil
    end

    post '/distiller' do
      distil
    end
    
    get '/sparql' do
      cache_control :public, :must_revalidate, :max_age => 60
      sparql
    end

    post '/sparql' do
      sparql
    end

    private

    # Handle GET/POST /distiller
    def distil
      writer_options = {
        :standard_prefixes => true,
        :prefixes => {},
        :base_uri => params["uri"],
      }
      writer_options[:format] = params["fmt"] || params["format"] || "turtle"

      content = parse(writer_options)
      $logger.debug "distil content: #{content.class}, as type #{(writer_options[:format] || format).inspect}"

      if writer_options[:format].to_s == "rdfa"
        # If the format is RDFa, use specific HAML writer
        haml_input = DISTILLER_HAML.dup
        root = request.url[0,request.url.index(request.path)]
        haml_input[:doc] = haml_input[:doc].gsub(/--root--/, root)
        writer_options[:haml] = haml_input
        writer_options[:haml_options] = {:ugly => false}
      end
      settings.sparql_options.replace(writer_options)

      if format != :html || params["raw"]
        # Return distilled content as is
        content
      else
        @output = case content
        when RDF::Enumerable
          # For HTML response, the "fmt" attribute may set the type of serialization
          fmt = (writer_options[:format] || "turtle").to_sym
          content.dump(fmt, writer_options)
        else
          content
        end
        haml :distiller, :locals => {:title => "RDF Distiller", :head => :distiller}
      end
    end
    
    # Handle GET/POST /sparql
    def sparql
      writer_options = {
        :standard_prefixes => true,
        :prefixes => {
          :ssd => "http://www.w3.org/ns/sparql-service-description#",
          :void => "http://rdfs.org/ns/void#"
        }
      }
      # Override output format if the content-type is something like
      # application/sparql-results, as sinatra-respond_to won't find
      # the right extension.
      if request.accept.first =~ %r(application/sparql-results\+([^,;]+))
        params["fmt"] = (format $1.to_sym)
      end

      # Override output format if returning something that is raw, or if
      # the "fmt" argument is used and the output format isn't HTML
      params["fmt"] ||= params["format"] if params.has_key?("format") # likely alias
      format :xml if format == :xsl # Problem with content detection
      format params["fmt"] if params["raw"] && params.has_key?("fmt")
      format params["fmt"] if params.has_key?("fmt") && format != :html
      # Make sure we get a format symbol, not an extension
      params["fmt"] ||= RDF::Format.for(:file_extension => format) unless RDF::Format.for(format)

      content = query

      if params["fmt"].to_s == "rdfa"
        # If the format is RDFa, use specific HAML writer
        haml = DISTILLER_HAML.dup
        root = request.url[0,request.url.index(request.path)]
        haml[:doc] = haml[:doc].gsub(/--root--/, root)
        writer_options[:haml] = haml
        writer_options[:haml_options] = {:ugly => false}
      end

      $logger.info "sparql content: #{content.class}, as type #{format.inspect} with options #{writer_options.inspect}"
      if format != :html
        writer_options[:format] = params["fmt"]
        settings.sparql_options.replace(writer_options)
        content
      else
        serialize_options = {
          :format => params["fmt"],
          :content_types => request.accept
        }
        begin
          @output = if params["fmt"] == "sse"
            content
          else
            $logger.debug "content-type: #{headers['Content-Type'].inspect}"
            SPARQL.serialize_results(content, serialize_options)
          end
        rescue RDF::WriterError => e
          @error = "No results generated #{content.class}: #{e.message}"
        end
        erb :sparql, :locals => {
          :title => "SPARQL Endpoint",
          :head => :distiller,
          :doap_count => doap.count
        }
      end
    end

    # Format symbol for RDF formats
    # @param [Symbol] reader_or_writer
    # @return [Array<Symbol>] List of format symbols
    def formats(reader_or_writer = nil)
      # Symbols for different input formats
      RDF::Format.each.to_a.map(&:reader).compact.map(&:to_sym)
    end

    ## Default graph, loaded from DOAP file
    def doap
      @doap ||= begin
        $logger.debug "load #{DOAP_NT}"
        RDF::Repository.load(DOAP_NT)
      end
    end

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(options)
      reader_opts = options.merge(
        :validate        => params["validate"],
        :vocab_expansion => params["vocab_expansion"],
        :rdfagraph       => params["rdfagraph"]
      )
      reader_opts[:format] = params["in_fmt"].to_sym unless (params["in_fmt"] || 'content') == 'content'
      reader_opts[:debug] = @debug = [] if params["debug"]
      
      graph = RDF::Repository.new
      in_fmt = params["in_fmt"].to_sym if params["in_fmt"]

      # Load data into graph
      case
      when !params["content"].to_s.empty?
        raise RDF::ReaderError, "Specify input format" if in_fmt.nil? || in_fmt == :content
        @content = ::URI.unescape(params["content"])
        $logger.info "Open form data with format #{in_fmt} for #{@content.inspect}"
        reader = RDF::Reader.for(reader_opts[:format] || reader_opts)
        reader.new(@content, reader_opts) {|r| graph << r}
      when !params["uri"].to_s.empty?
        $logger.info "Open uri <#{params["uri"]}> with format #{in_fmt}"
        reader = RDF::Reader.open(params["uri"], reader_opts) {|r| graph << r}
        params["in_fmt"] = reader.class.to_sym if in_fmt.nil? || in_fmt == :content
      else
        graph = ""
      end

      $logger.info "parsed #{graph.count} statements" if graph.is_a?(RDF::Graph)
      graph
    rescue RDF::ReaderError => e
      @error = "RDF::ReaderError: #{e.message}"
      $logger.error @error  # to log
      nil
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      $logger.error @error  # to log
      nil
    end

    # Perform a SPARQL query, either on the input URI or the form data
    def query
      sparql_opts = {
        :base_uri => params["uri"],
        :validate => params["validate"],
      }
      sparql_opts[:format] = params["fmt"].to_sym if params["fmt"]
      sparql_opts[:debug] = @debug = [] if params["debug"]

      sparql_expr = nil
      repo = nil

      case
      when !params["query"].to_s.empty?
        @query = params["query"]
        $logger.info "Open form data: #{@query.inspect}"
        # Optimization for RDFa Test suite
        repo = RDF::Repository.new if @query.to_s =~ /ASK FROM/
        sparql_expr = SPARQL.parse(@query, sparql_opts)
      when !params["uri"].to_s.empty?
        $logger.info "Open uri <#{params["uri"]}>"
        RDF::Util::File.open_file(params["uri"]) do |f|
          sparql_expr = SPARQL.parse(f, sparql_opts)
        end
      else
        # Otherwise, return service description
        $logger.info "Service Description"
        return case format
        when :html
          ""  # Done in form
        else
          # Return service description graph
          service_description(:repository => doap, :endpoint => url("/sparql"))
        end
      end

      raise "No SPARQL query created" unless sparql_expr

      if params["fmt"].to_s == "sse"
        headers = ["Content-Type" => "application/sse+sparql-query"]
        return sparql_expr.to_sse
      end

      $logger.debug "execute query"
      repo ||= doap
      sparql_expr.execute(repo, sparql_opts)
    rescue SPARQL::Grammar::Parser::Error, SPARQL::MalformedQuery, TypeError
      @error = "#{$!.class}: #{$!.message}"
      $logger.error @error  # to log
      nil
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      $logger.error @error  # to log
      nil
    end
    
    private
    def format_version(format)
      if %w(RDF::NTriples::Format RDF::NQuads::Format).include?(format.to_s)
        return RDF::VERSION
      else
        format.to_s.split('::')[0..-2].inject(Kernel) {|mod, name| mod.const_get(name)}.const_get('VERSION')
      end
    end
  end
end