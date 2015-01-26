require 'sinatra/sparql'
require 'sinatra/partials'
require 'sinatra/extensions'
require 'erubis'
require 'linkeddata'
require 'rdf/tabular' # experimental
require 'uri'
require 'haml'

module RDF::Distiller
  class Application < Sinatra::Base
    DOAP_NT = File.join(APP_DIR, 'etc/doap.nt')
    DOAP_JSON = File.join(APP_DIR, 'etc/doap.jsonld')

    configure do
      register Sinatra::SPARQL
      helpers Sinatra::Partials
      set :root, APP_DIR
      set :public_folder, PUB_DIR
      set :views, ::File.expand_path('../views',  __FILE__)
      set :app_name, "RDF Distiller"
      enable :logging
      disable :raise_errors, :show_exceptions if settings.environment == :production

      # Cache client requests
      RestClient.enable Rack::Cache,
        verbose:     true,
        metastore:   "file:" + ::File.join(APP_DIR, "cache/meta"),
        entitystore: "file:" + ::File.join(APP_DIR, "cache/body")

      register Sinatra::AssetPack

      mime_type :jsonld, "application/ld+json"
      mime_type :sparql, "application/sparql-query"
      mime_type :ttl, "text/turtle"
      mime_type "sse", "application/sse+sparql-query"

      # Asset pipeline
      assets do
        serve '/js', from: 'assets/js'
        serve '/css', from: 'assets/css'
        #serve '/images', from: 'assets/images'

        css :app, %w(/css/application.css)
        js :app, %w(/js/application.js)

        # Skip compression
        #js_compression  :jsmin
        #css_compression :simple
      end
    end

    configure :development do
      set :logging, ::Logger.new($stdout)
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = File.expand_path("../../../..", __FILE__)
    end

    configure :test do
      set :logging, ::Logger.new(StringIO.new)
    end

    helpers do
      # Set cache control
      def set_cache_header(options = {})
        options = {:max_age => ENV.fetch('max_age', 60*5)}.merge(options)
        cache_control(:public, :must_revalidate, options)
      end
    end

    before do
      request.logger.level = Logger::DEBUG unless settings.environment == :production
      request.logger.info "#{request.request_method} [#{request.path_info}], " +
        params.merge(Accept: request.accept.map(&:to_s)).map {|k,v| "#{k}=#{v}"}.join(" ") +
        "#{params.inspect}"
    end

    after do
      msg = "Status: #{response.status} (#{request.request_method} #{request.path_info}), Content-Type: #{response.content_type}"
      msg += ", Location: #{response.location}" if response.location
      request.logger.info msg
    end

    get '/' do
      cache_control :public, :must_revalidate, max_age: 60
      result = erb :index, locals: {title: "Ruby Linked Data Service"}
      etag result.hash
      result
    end

    get '/about.?:format?' do
      cache_control :public, :must_revalidate, max_age: 60
      haml :about, locals: {title: "About the Ruby Linked Data Service"}
    end

    get '/doap.?:format?' do
      cache_control :public, :must_revalidate, max_age: 60
      case format
      when :nt, :ntriples
        f = File.read(DOAP_NT).force_encoding(Encoding::UTF_8)
        etag f
        headers "Content-Type" => "application/n-triples; charset=utf-8"
        body f
      when :jsonld
        f = File.read(DOAP_JSON).force_encoding(Encoding::UTF_8)
        etag Digest::SHA1.hexdigest f
        headers "Content-Type" => "application/ld+json; charset=utf-8"
        body f
      when :html, :xhtml
        f = File.read(DOAP_JSON).force_encoding(Encoding::UTF_8)
        etag Digest::SHA1.hexdigest f
        projects = ::JSON.parse(f)['@graph']
        
        # Fix dc:created and doap:helper entries to be normalized
        projects.each do |p|
          devs = p['doap:developer'].inject({}) {|memo, h| memo[h['@id']] = h if h.is_a?(Hash); memo}
          p['dc:creator'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
          p['doap:helper'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
        end
        haml :doap, locals: {
          title:    "Project Information on included Gems",
          projects: projects
        }
      else
        etag Digest::SHA1.hexdigest File.read(DOAP_NT)
        settings.sparql_options.merge!(format: format, content_type: content_type)
        doap
      end
    end

    get '/distiller' do
      cache_control :public, :must_revalidate, max_age: 60
      distil
    end

    post '/distiller' do
      distil
    end
    
    get '/sparql' do
      cache_control :public, :must_revalidate, max_age: 60
      sparql
    end

    post '/sparql' do
      sparql
    end

    private

    # Handle GET/POST /distiller
    def distil
      writer_options = {
        standard_prefixes: true,
        prefixes: {},
        base_uri: params["uri"],
      }
      writer_options[:format] = params["fmt"] || params["format"] || "turtle"

      content = parse(writer_options)
      request.logger.debug "distil content: #{content.class}, as type #{(writer_options[:format] || format).inspect}"

      if writer_options[:format].to_s == "rdfa"
        # If the format is RDFa, use specific HAML writer
        haml_input = DISTILLER_HAML.dup
        root = request.url[0,request.url.index(request.path)]
        haml_input[:doc] = haml_input[:doc].gsub(/--root--/, root)
        writer_options[:haml] = haml_input
        writer_options[:haml_options] = {ugly: false}
      end
      settings.sparql_options.replace(writer_options.merge(content_type: content_type))

      if format != :html || params["raw"]
        format writer_options[:format]
        settings.sparql_options.merge!(format: format, content_type: content_type)
        # Return distilled content as is
        content
      else
        @output = case content
        when RDF::Enumerable
          # For HTML response, the "fmt" attribute may set the type of serialization
          fmt = (writer_options[:format] || content.contexts.empty? ? "turtle" : "trig").to_sym
          content.dump(fmt, writer_options)
        else
          content
        end
        @output.force_encoding(Encoding::UTF_8) if @output
        haml :distiller, locals: {title: "RDF Distiller", head: :distiller}
      end
    rescue
      if format != :html || params["raw"]
        status 400
        body $!.message
      else
        html :distiller, locals: {title: "RDF Distiller", head: :distiller}
      end
    end
    
    # Handle GET/POST /sparql
    def sparql
      writer_options = {
        standard_prefixes: true,
        prefixes: {
          ssd: "http://www.w3.org/ns/sparql-service-description#",
          void: "http://rdfs.org/ns/void#"
        }
      }
      # Override output format if the content-type is something like
      # application/sparql-results
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

      content = query
      params["fmt"] ||= format

      # Make sure we're using an appropriate content-type, it might have been set based on an RDF serialization type, rather than a query results type
      content_type SPARQL::Results::MIME_TYPES[params["fmt"].to_sym] unless content.is_a?(RDF::Queryable)

      if params["fmt"].to_s == "rdfa"
        # If the format is RDFa, use specific HAML writer
        haml = DISTILLER_HAML.dup
        root = request.url[0,request.url.index(request.path)]
        haml[:doc] = haml[:doc].gsub(/--root--/, root)
        writer_options[:haml] = haml
        writer_options[:haml_options] = {ugly: false}
      end
      writer_options.merge!(content_type: content_type)

      request.logger.info "sparql content: #{content.class}, as type #{format.inspect} with options #{writer_options.inspect}"
      if format != :html
        writer_options[:format] = params["fmt"]
        settings.sparql_options.replace(writer_options)
        content
      else
        serialize_options = {
          format: params["fmt"],
          content_types: request.accept
        }
        begin
          @output = if params["fmt"] == "sse"
            content
          else
            request.logger.debug "content-type: #{headers['Content-Type'].inspect}"
            SPARQL.serialize_results(content, serialize_options)
          end
        @output.force_encoding(Encoding::UTF_8) if @output
        rescue RDF::WriterError => e
          @error = "No results generated #{content.class}: #{e.message}"
          request.logger.error @error  # to log
        end
        erb :sparql, locals: {
          title: "SPARQL Endpoint",
          head: :distiller,
          doap_count: doap.count
        }
      end
    rescue
      if format != :html
        status 400
        body $!.message
      else
        html :sparql, locals: {title: "SPARQL Endpoint", head: :distiller}
      end
    end

    # Format symbols for RDF formats
    # @param [Symbol] reader_or_writer
    # @return [Array<Symbol>] List of format symbols
    def formats(reader_or_writer = nil)
      # Symbols for different input formats
      RDF::Format.each.to_a.map(&:reader).compact.map(&:to_sym)
    end

    # Negotiated format
    # @param [#to_sym] format (nil) allows a format to be specified
    # @return [Symbol]
    def format(format = nil)
      params[:format] = format.to_sym if format
      case
      when params[:format]
        content_type params[:format] == :json ? 'application/rdf+json' : params[:format]
        params[:format].to_sym
      when %w(application/xhtml+xml text/html */*).include?(Array(env['ORDERED_CONTENT_TYPES']).first)
        content_type env['ORDERED_CONTENT_TYPES'].first
        :html
      when !Array(env['ORDERED_CONTENT_TYPES']).empty?
        content_type env['ORDERED_CONTENT_TYPES'].first
        case env['ORDERED_CONTENT_TYPES'].first
        when 'application/sparql-results+json' then :json
        when 'text/html'                       then :html
        when 'application/sparql-results+xml'  then :xml
        when 'text/csv'                        then :csv
        when 'text/tab-separated-values'       then :tsv
        when 'application/rdf+json'            then :json
        else
          RDF::Format.for(content_type: env['ORDERED_CONTENT_TYPES'].first).to_sym
        end
      else
        content_type :html
        :html
      end
    end

    ## Default graph, loaded from DOAP file
    def doap
      @doap ||= begin
        request.logger.debug "load #{DOAP_NT}"
        RDF::Repository.load(DOAP_NT, encoding: Encoding::UTF_8)
      end
    end

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(options)
      reader_opts = options.merge(
        validate:        params["validate"],
        vocab_expansion: params["vocab_expansion"],
        rdfagraph:       params["rdfagraph"],
        verify_none:     params["verify_none"],
        headers:  {
          "User-Agent"    => "Ruby-RDF-Distiller/#{RDF::Distiller::VERSION}",
          "Cache-Control" => "no-cache"
        },
      )
      reader_opts.reject! {|k, v| k == :format}
      reader_opts[:format] = params["in_fmt"].to_sym unless (params["in_fmt"] || 'content') == 'content'
      reader_opts[:debug] = @debug = [] if params["debug"]
      
      graph = RDF::Repository.new
      in_fmt = params["in_fmt"].to_sym if params["in_fmt"]

      # Load data into graph
      case
      when !params["content"].to_s.empty?
        @content = ::URI.unescape(params["content"])
        request.logger.info "Open form data with format #{in_fmt} for #{@content.inspect}"
        reader = RDF::Reader.for(reader_opts[:format] || reader_opts) {@content}
        reader.new(@content, reader_opts) {|r| graph << r}
      when !params["uri"].to_s.empty?
        request.logger.info "Open uri <#{params["uri"]}> with format #{in_fmt}"
        reader = RDF::Reader.open(params["uri"], reader_opts) {|r| graph << r}
        params["in_fmt"] = reader.class.to_sym if in_fmt.nil? || in_fmt == :content
      else
        graph = ""
      end

      request.logger.info "parsed #{graph.count} statements" if graph.is_a?(RDF::Graph)
      graph
    rescue
      @error = "#{$!.class}: #{$!.message}"
      request.logger.error @error  # to log
      raise
      nil
    end

    # Perform a SPARQL query, either on the input URI or the form data
    def query
      sparql_opts = {
        base_uri: params["uri"],
        validate: params["validate"],
      }
      sparql_opts[:format] = params["fmt"].to_sym if params["fmt"]
      sparql_opts[:debug] = @debug = [] if params["debug"]

      sparql_expr = nil
      repo = nil

      case
      when !params["query"].to_s.empty?
        @query = params["query"]
        request.logger.info "Open form data: #{@query.inspect}"
        # Optimization for RDFa Test suite
        repo = RDF::Repository.new if @query.to_s =~ /ASK FROM/
        sparql_expr = SPARQL.parse(@query, sparql_opts)
      when !params["uri"].to_s.empty?
        request.logger.info "Open uri <#{params["uri"]}>"
        RDF::Util::File.open_file(params["uri"]) do |f|
          sparql_expr = SPARQL.parse(f, sparql_opts)
        end
      else
        # Otherwise, return service description
        request.logger.info "Service Description"
        return case format
        when :html
          ""  # Done in form
        else
          # Return service description graph
          service_description(repository: doap, endpoint: url("/sparql"))
        end
      end

      raise "No SPARQL query created" unless sparql_expr

      if params["fmt"].to_s == "sse"
        headers = ["Content-Type" => "application/sse+sparql-query; charset=utf-8"]
        return sparql_expr.to_sse
      end

      request.logger.debug "execute query"
      repo ||= doap
      sparql_expr.execute(repo, sparql_opts)
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      request.logger.error @error  # to log
      nil
    end

    ##
    # Lookup extension class version
    #
    # @param [String] class_name
    # @return [String]
    def class_version(str)

      str = case str
      when "RDF.rb"       then "RDF"
      when "SXP for Ruby" then "SXP"
      when "ebnf"         then "EBNF"
      else str
      end

      "#{str.sub('.rb', '')}::VERSION".split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end.to_s
    rescue
      "???"
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