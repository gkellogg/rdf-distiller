$:.unshift ".."
require 'spec_helper'
require 'linkeddata'

describe RDF::Distiller::Application do
  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe "/doap" do
    let(:doap) {@doap ||= RDF::Repository.new << [RDF::URI("http://example/#this"), RDF.type, RDF::DOAP.to_uri]}
    before(:each) {allow(RDF::Repository).to receive(:load).and_return(doap)}

    context "Format symbols" do
      RDF::Writer.each do |writer|
        format = writer.format
        sym = format.to_sym
        ext = format.file_extension.first
        context "#{sym}" do
          it "gets  with #{sym} format" do
            get "/doap", :format => sym
            expect(last_response.body).to eq "" unless last_response.ok?
            expect(last_response.content_type).to include(mime_type(sym))
          end
        end
      end
    end
    
    context "File extensions" do
      RDF::Format.file_extensions.keys.each do |extension|
        next unless RDF::Format.for(file_extension: extension).writer
        context "#{extension}" do
          it "gets with .#{extension} extension" do
            get "/doap.#{extension}"
            expect(last_response.body).to eq "" unless last_response.ok?
            expect(last_response.content_type).to include(mime_type(extension))
          end
        end
      end
    end

    context "Content Type" do
      RDF::Format.content_types.keys.each do |content_type|
        next unless RDF::Format.for(content_type: content_type).writer
        next if %w(text/plain application/x-ld+json).include?(content_type)
        context "#{content_type}" do
          it "gets  with #{content_type}" do
            get "/doap", {}, {"HTTP_ACCEPT" => content_type}
            expect(last_response.body).to eq "" unless last_response.ok?
            expect(last_response.content_type).to include(content_type)
          end
        end
      end
    end
  end
end
