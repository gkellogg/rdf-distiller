require 'rdf/util/file'
require 'curb'

module RDF::Util
  module File
    ##
    # Override to use CURB for http and https, Kernel.open otherwise.
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
        remote_document = RemoteDocument.new("", base_uri: filename_or_url, charset: "utf-8")

        c = Curl::Easy.perform(filename_or_url) do |curl|
          curl.headers['Accept'] = 'text/turtle, application/rdf+xml;q=0.8, text/plain;q=0.4, */*;q=0.1'
          curl.headers['User-Agent'] = "Ruby-RDF-Distiller/#{RDF::Distiller::VERSION}"
          curl.on_body {|body| remote_document.write(body); body.length}
          curl.on_header do |header|
            remote_document.instance_variable_set(:@content_type, header["Content-Type"])
            remote_document.instance_variable_set(:@last_modified, header["Last-Modified"])
          end
          curl.on_success {|easy, code| remote_document.instance_variable_set(:@status, code || 200)}
          curl.on_failure {|easy, code| remote_document.instance_variable_set(:@status, code || 500)}
        end
        remote_document.rewind
        remote_document.instance_variable_set(:@content_type, @content_type)
        if block_given?
          begin
            block.call(remote_document)
          ensure
            remote_document.close
          end
        else
          remote_document
        end
      else
        Kernel.open(filename_or_url.to_s, &block)
      end
    end
  end
end
