require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'
require 'rdf/microdata'
require 'rdf/turtle'
require 'json/ld'

module RDF
  module Portal
    autoload :VERSION,        'rdf/portal/version'
    autoload :DISTILLER_HAML,  'rdf/portal/rdfa_template'

    class Application < Sinatra::Base
      #register Sinatra::LinkedData
      helpers Sinatra::Partials
      #use Rack::LinkedData::ContentNegotiation, :default => "text/html"
      set :views, ::File.expand_path('../portal/views',  __FILE__)

      before do
        puts "[#{request.path_info}], #{params.inspect}"
      end

      get '/' do
        cache_control :public, :must_revalidate, :max_age => 60
        erb :index, :locals => {:title => "Ruby Linked Data Service"}
      end

      get '/about' do
        cache_control :public, :must_revalidate, :max_age => 60
        erb :about, :locals => {:title => "About the Ruby Linked Data Service"}
      end

      get '/distiller' do
        distil
      end

      post '/distiller' do
        distil
      end
      
      private

      # Handle GET/POST /distiller
      def distil
        content_type, content = parse
        if !params["raw"].to_s.empty?
          puts "render distilled content as type #{content_type}"
          status 200
          headers "Allow" => "GET, POST", "Content-Type" => content_type
          body content
        else
          @output = content unless content == @error
          erb :distiller, :locals => {:title => "RDF Distiller", :head => :distiller}
        end
      end
      
      # Return ordered accept mime-types
      def accepts
        types = []
        request.env["HTTP_ACCEPT"].to_s.split(",").each do |type|
          t, q = type.split(';q=')
          q ||= t =~ /xml$/ ? "0.9" : "1"   # WebKit places application/xml at same priority as /html
          types << [t, q.to_i]
        end

        types.sort {|a, b| b[1] <=> a[1]}.map {|(t, q)| t}
      end

      # Parse HTTP Accept header and find an suitable RDF writer
      def writer(format = nil)
        if format && format.to_sym != :accept
          fmt = RDF::Format.for(format.to_sym)
          return [format.to_sym, fmt.content_type.first] if fmt
        end
        
        # Look for formats matching accept headers
        accepts.each do |t|
          writer = RDF::Writer.for(:content_type => t)
          return [writer.to_sym, t] if writer
        end

        return [:ntriples, "text/plain"]
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
        format = params["in_fmt"].to_sym if params["in_fmt"]

        case
        when !params["datafile"].to_s.empty?
          raise RDF::ReaderError, "Specify input format" if format.nil? || format == :content
          puts "Open datafile with format #{format}"
          tempfile = params["datafile"][:tempfile]
          reader = RDF::Reader.for(format).new(tempfile, reader_opts) {|r| graph << r}
        when !params["content"].to_s.empty?
          raise RDF::ReaderError, "Specify input format" if format.nil? || format == :content
          puts "Open form data with format #{format}"
          @content = params["content"]
          reader = RDF::Reader.for(format).new(@content, reader_opts) {|r| graph << r}
        when !params["uri"].to_s.empty?
          puts "Open uri <#{params["uri"]}> with format #{format}"
          reader = RDF::Reader.open(params["uri"], reader_opts) {|r| graph << r}
          params["in_fmt"] = reader.class.to_sym if format.nil? || format == :content
        else
          return ["text/html", ""]
        end

        params["fmt"], content_type = writer(params["fmt"])
        
        writer_opts = reader_opts.merge(:standard_prefixes => true)
        case params["fmt"]
        when :rdfa
          haml = DISTILLER_HAML.dup
          root = request.url[0,request.url.index(request.path)]
          haml[:doc] = haml[:doc].gsub(/--root--/, root)
          writer_opts[:haml] = haml
          writer_opts[:haml_options] = {:ugly => false}
        end
        puts "Writer options: #{writer_opts.inspect}"
        [content_type, graph.dump(params["fmt"].to_sym, writer_opts)]
      rescue RDF::ReaderError => e
        @error = "RDF::ReaderError: #{e.message}"
        puts @error  # to log
        content_type ||= accepts.first
        case content_type
        when /html/
          [content_type, @error] # XXX
        when /xml/
          [content_type, @error.to_xml]
        else
          [content_type, @error]
        end
      rescue
        raise unless settings.environment == :production
        @error = "#{$!.class}: #{$!.message}"
        puts @error  # to log
        content_type ||= "text/html" if accepts.include?("text/html")
        content_type ||= "application/xml" if accepts.include?("application/xml")
        content_type ||= "text/plain"
        case content_type
        when "application/xml"
          [content_type, @error.to_xml]
        when "text/html"
          [content_type, @error] # XXX
        else
          ["text/plain", @error]
        end
      end
    end
  end

  module Util::File
    ##
    # Override to use Net::HTTP, which means that it only opens URIs.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    #   any options to pass through to the underlying UUID library
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, options = {}, &block)
      STDERR.puts "open file #{filename_or_url.inspect}"
      filename_or_url = $1 if filename_or_url.to_s.match(/^file:(.*)$/)
      Kernel.open(filename_or_url.to_s, &block)
    end
  end
end
