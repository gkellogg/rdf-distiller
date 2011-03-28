require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'

module RDF
  module Portal
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
        erubis :index, :locals => {:title => "Ruby Linked Data Service"}
      end

      get '/about' do
        cache_control :public, :must_revalidate, :max_age => 60
        erubis :about, :locals => {:title => "About the Ruby Linked Data Service"}
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
        puts "content_type: #{content_type}"
        if !params["raw"].to_s.empty? || content_type !~ /html/
          status 200
          headers "Allow" => "GET, POST", "Content-Type" => content_type
          body content
        else
          @output = content
          erubis :distiller, :locals => {:title => "RDF Distiller", :head => :distiller}
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
        return format.to_sym if format && format.to_sym != :accept
        
        # Look for formats matching accept headers
        accepts.each do |t|
          writer = RDF::Writer.for(:content_type => t)
          return writer.to_sym if writer
        end

        return :ntriples
      end
      
      # Format symbol for RDF formats
      # @param [Symbol] reader_or_writer
      # @return [Array<Symbol>] List of format symbols
      def formats(reader_or_writer = nil)
        # Symbols for different input formats
        RDF::Format.select do |f|
          reader_or_writer != :reader || f.reader
          reader_or_writer != :writer || f.writer
        end.map(&:to_sym).sort
      end

      # Parse the an input file and re-serialize based on params and/or content-type/accept headers
      def parse
        reader_opts = {
          :prefixes => {},
          :base_uri => params["uri"],
          :validate => params["validate"]
        }
        reader_opts[:format] = params["in_fmt"].to_sym unless params["in_fmt"].nil? || params["in_fmt"] == 'content'
        reader_opts[:debug] = @debug = [] if params["debug"]
        case
        when !params["datafile"].to_s.empty?
          raise "Specify input format" if params["in_fmt"].nil? || params["in_fmt"] == 'content'
          reader = RDF::Reader.for(params["in_fmt"]).new(content, reader_opts)
        when !params["content"].to_s.empty?
          raise "Specify input format" if params["in_fmt"].nil? || params["in_fmt"] == 'content'
          reader = RDF::Reader.for(params["in_fmt"]).new(content, reader_opts)
        when !params["uri"].empty?
          reader = RDF::Reader.open(params["uri"], reader_opts)
          params["in_fmt"] = reader.class.to_sym if params["in_fmt"].nil? || params["in_fmt"] == 'content'
        else
          return ["text/html", ""]
        end
        content_type = reader.class.format.content_type.first

        graph = RDF::Graph.new << reader
        
        params["fmt"] = writer(params["fmt"])
        [content_type, graph.dump(params["fmt"].to_sym, reader_opts)]
      rescue Exception => e
        @error = "#{e.class}: #{e.message}"
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
        raise
      end

    end
  end
end

module RDF
  class Format
    def self.to_sym
      elements = self.to_s.split("::")
      sym = elements.pop
      sym = elements.pop if sym == 'Format'
      sym.downcase.to_s
    end
  end

  class Reader
    def self.to_sym
      elements = self.to_s.split("::")
      sym = elements.pop
      sym = elements.pop if sym == 'Reader'
      sym.downcase.to_s
    end
  end

  class Writer
    def self.to_sym
      elements = self.to_s.split("::")
      sym = elements.pop
      sym = elements.pop if sym == 'Writer'
      sym.downcase.to_s
    end
  end
end
