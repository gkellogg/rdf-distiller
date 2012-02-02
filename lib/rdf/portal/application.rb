require 'sinatra/linkeddata'
require 'sinatra/partials'
require 'sinatra/respond_to'
require 'erubis'
require 'rdf/microdata'
require 'rdf/turtle'
require 'rdf/trig'
require 'json/ld'

module RDF::Portal
  class Application < Sinatra::Base
    register Sinatra::RespondTo
    register Sinatra::LinkedData
    helpers Sinatra::Partials
    set :views, ::File.expand_path('../views',  __FILE__)
    DOAP_FILE = File.expand_path("../../../../etc/doap.nt", __FILE__)

    #mime_type "sse", "application/sse+sparql-query"
    before do
      puts "[#{request.path_info}], #{params.inspect}, #{format}, #{request.accept.inspect}"
      
      # Set the content type from Accept to get RespondTo to work properly
      fmt = Rack::Mime::MIME_TYPES.invert[request.accept.first]
      if fmt
        puts " set format to #{fmt[1..-1]}"
        content_type fmt[1..-1]
      end
      puts "  accept: #{request.accept.inspect}"
      puts "  content type: #{headers['Content-Type'].inspect}"
    end

    get '/' do
      cache_control :public, :must_revalidate, :max_age => 60
      erb :index, :locals => {:title => "Ruby Linked Data Service"}
    end

    get '/about' do
      cache_control :public, :must_revalidate, :max_age => 60
      erb :about, :locals => {:title => "About the Ruby Linked Data Service"}
    end

    get '/doap' do
      cache_control :public, :must_revalidate, :max_age => 60
      puts "doap format: #{format.inspect}"
      if format == :nt
        headers "Content-Type" => "text/plain"
        body File.read(DOAP_FILE)
      else
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
      content = parse
      # Override output format if returning something that is raw, or if
      # the "fmt" argument is used and the output format isn't HTML
      format params["fmt"] if params["raw"] && params.has_key?("fmt")
      format params["fmt"] if params.has_key?("fmt") && format != :html

      puts "distill content: #{content.class}, as type #{format.inspect}"

      if format != :html
        # Return distilled content as is
        content
      else
        @output = case content
        when RDF::Enumerable
          # For HTML response, the "fmt" attribute may set the type of serialization
          fmt = (params["fmt"] || "ttl").to_sym
          content.dump(fmt, :standard_prefixes => true)
        when Array
          @output = content.last
        else
          content
        end
        erb :distiller, :locals => {:title => "RDF Distiller", :head => :distiller}
      end
    end
    
    # Handle GET/POST /sparql
    def sparql
      # Override output format if returning something that is raw, or if
      # the "fmt" argument is used and the output format isn't HTML
      format :xml if format == :xsl # Problem with content detection
      format params["fmt"] if params["raw"] && params.has_key?("fmt")
      format params["fmt"] if params.has_key?("fmt") && format != :html
      params["fmt"] ||= format

      content = query

      puts "sparql content: #{content.class}, as type #{format.inspect}"
      if format != :html
        headers "Content-Type" => content.first
        body content.last
      else
        content = content.last if content.is_a?(Array)
        @output = content
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
      RDF::Format.select do |f|
        reader_or_writer != :reader || f.reader
        reader_or_writer != :writer || f.writer
      end.map(&:to_sym).sort_by(&:to_s)
    end

    ## Default graph, loaded from DOAP file
    def doap
      @doap ||= begin
        puts "load #{DOAP_FILE}"
        RDF::Repository.load(DOAP_FILE)
      end
    end

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse
      reader_opts = {
        :prefixes => {},
        :base_uri => params["uri"],
        :validate => params["validate"],
        :expand => params["expand"],
      }
      reader_opts[:format] = params["in_fmt"].to_sym unless params["in_fmt"].nil? || params["in_fmt"] == 'content'
      reader_opts[:debug] = @debug = [] if params["debug"]
      
      graph = RDF::Graph.new
      in_fmt = params["in_fmt"].to_sym if params["in_fmt"]

      case
      when !params["datafile"].to_s.empty?
        raise RDF::ReaderError, "Specify input format" if in_fmt.nil? || in_fmt == :content
        puts "Open datafile with format #{in_fmt}"
        tempfile = params["datafile"][:tempfile]
        RDF::Reader.for(in_fmt).new(tempfile, reader_opts) {|r| graph << r}
      when !params["content"].to_s.empty?
        raise RDF::ReaderError, "Specify input format" if in_fmt.nil? || in_fmt == :content
        puts "Open form data with format #{in_fmt}"
        @content = params["content"]
        RDF::Reader.for(in_fmt).new(@content, reader_opts) {|r| graph << r}
      when !params["uri"].to_s.empty?
        puts "Open uri <#{params["uri"]}> with format #{in_fmt}"
        reader = RDF::Reader.open(params["uri"], reader_opts) {|r| graph << r}
        params["in_fmt"] = reader.class.to_sym if in_fmt.nil? || in_fmt == :content
      else
        graph = ""
      end

      puts "parse: fmt: #{params['fmt'].inspect}"
      if graph.is_a?(RDF::Enumerable) && (params["fmt"].to_s == "rdfa")
        # If the format is RDFa, use specific HAML writer
        writer_opts = reader_opts.merge(:standard_prefixes => true)
        haml = DISTILLER_HAML.dup
        root = request.url[0,request.url.index(request.path)]
        haml[:doc] = haml[:doc].gsub(/--root--/, root)
        writer_opts[:haml] = haml
        writer_opts[:haml_options] = {:ugly => false}
        ["text/html", graph.dump(:rdfa, writer_opts)]
      else
        graph
      end
    rescue RDF::ReaderError => e
      @error = "RDF::ReaderError: #{e.message}"
      puts @error  # to log
      nil
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      puts @error  # to log
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

      case
      when !params["query"].to_s.empty?
        @query = params["query"]
        puts "Open form data: #{@query.inspect}"
        sparql_expr = SPARQL.parse(@query, sparql_opts)
      when !params["uri"].to_s.empty?
        puts "Open uri <#{params["uri"]}>"
        RDF::Util::File.open_file(params["uri"]) do |f|
          sparql_expr = SPARQL.parse(f, sparql_opts)
        end
      else
        # Otherwise, return service description
        puts "Service Description"
        return case format
        when :html
          ""  # Done in form
        else
          # Return service description graph
          service_description
        end
      end

      raise "No SPARQL query created" unless sparql_expr

      return ["application/sse+sparql-query", sparql_expr.to_sxp] if params["fmt"].to_s == "sse"

      puts "execute query"
      solutions = sparql_expr.execute(doap, sparql_opts)
      puts "solutions are #{solutions.inspect}"
      results = SPARQL.serialize_results(solutions, sparql_opts.merge(:standard_prefixes => true))
      puts "results are [#{results.content_type}, #{results.class}] with options #{sparql_opts.inspect}"
      [results.content_type, results]
    rescue SPARQL::Grammar::Parser::Error, SPARQL::MalformedQuery, TypeError
      @error = "#{$!.class}: #{$!.message}"
      puts @error  # to log
      nil
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      puts @error  # to log
      nil
    end

    ##
    # Return a service description graph
    #
    # @see http://www.w3.org/TR/sparql11-service-description
    def service_description
      @ssd ||= begin
        g = RDF::Graph.new
        sd = RDF::URI("http://www.w3.org/ns/sparql-service-description#")
        void = RDF::URI("http://rdfs.org/ns/void#")
      
        node = RDF::Node.new
        g << [node, RDF.type, sd.join("Service")]
        g << [node, sd.join("endpoint"), url("/sparql")]
        g << [node, sd.join("supportedLanguage"), sd.join("SPARQL10Query")]
      
        # Result formats, both RDF and SPARQL Results.
        # FIXME: We should get this from the avaliable serializers
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/RDF_XML")]
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/Turtle")]
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/RDFa")]
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/N-Triples")]
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_RESULTS_XML")]
        g << [node, sd.join("resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_RESULTS_JSON")]
      
        # Features
        g << [node, sd.join("feature"), sd.join("DereferencesURIs")]
      
        # Datasets
        ds = RDF::Node.new
        g << [node, sd.join("defaultDataset"), ds]
        g << [ds, RDF.type, sd.join("Dataset")]
      
        # Default graph
        dg = RDF::Node.new
        g << [ds, sd.join("defaultGraph"), dg]
        g << [dg, RDF.type, sd.join("Graph")]
        g << [dg, void.join("triples"), doap.count]
        g << [dg, void.join("dataDump"), url("/doap.nt")]
        g
      end
    end
  end
end