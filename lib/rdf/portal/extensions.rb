require 'rdf/util/file'
require 'patron'

module RDF::Util
  module File
    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, options = {}, &block)
      case filename_or_url.to_s
      when /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, &block)
      when /^http/
        headers = {
          "Accept" => 'text/turtle, application/rdf+xml;q=0.8, text/plain;q=0.4, */*;q=0.1',
          #"User-Agent" => "Ruby-RDF-Distiller/#{RDF::Portal::VERSION}"
        }.merge(options[:headers] || {})
        sess = Patron::Session.new
        sess.timeout = 30
        sess.headers['User-Agent'] = 
        sess.headers['Accept'] = [options[:accept] || 'application/rdf+xml, */*;q=0.1'].flatten.join(', ')
        resp = sess.get(filename_or_url)
        io_obj = StringIO.new(resp.body)
        io_obj.instance_variable_set(:@resp, resp)
        def io_obj.content_type
          [@resp.headers["Content-Type"]].flatten.first.split(/[;,]/).first
        end
        def io_obj.status
          @resp.status
        end
        def io_obj.charset
          @resp.charset
        end
        if block_given?
          begin
            block.call(io_obj)
          ensure
            io_obj.close
          end
        else
          io_obj
        end
      else
        Kernel.open(filename_or_url.to_s, &block)
      end
    end
  end
end
