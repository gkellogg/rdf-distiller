require 'rack/linkeddata'
class Rack::LinkedData::ContentNegotiation
  # Pass more options to the writer
  # Also, be compatible with Sinatra::RespondTo and look at
  # returned Content-Type to find the writer
  def serialize(env, status, headers, body)
    begin
      puts "content type: #{headers['Content-Type'].inspect}"
      content_type = headers['Content-Type'].split(';').first
      writer = RDF::Writer.for(:content_type => content_type)
      if writer
        puts "Use writer #{writer} for #{content_type}"
        headers = VARY.merge(headers)
        [status, headers, [writer.dump(body, nil, :standard_prefixes => true)]]
      else
        not_acceptable
      end
    rescue RDF::WriterError => e
      not_acceptable
    end
  end
end

require 'rdf/util/file'
module RDF::Util::File
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
