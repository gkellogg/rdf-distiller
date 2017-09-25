$:.unshift ".."
require 'spec_helper'
require 'linkeddata'
require 'webmock/rspec'

describe RDF::Distiller::Application do
  def app
   RDF::Distiller::Application
  end

  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe "/distiller" do
    context "HTML output" do
      context "URL" do
        before(:each) do
          WebMock.stub_request(:get, 'http://example.com/foo').
            to_return(body:  %(<http://example/a> <http://example/b> "c" .),
                      status: 200,
                      headers: { 'Content-Type' => 'text/ntriples' })
        end

        it "retrieves a graph" do
          get '/distiller', url: 'http://example.com/foo', fmt: "ntriples"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('text/html')
        end
      end

      context "form data" do
        it "retrieves a graph" do
          get '/distiller',
              content: %(<http://example/a> <http://example/b> "c" .),
              in_fmt: "ntriples",
              fmt: "ntriples"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('text/html')
        end

        context "content detection" do
          {
            jsonld: %q({"@id": "http://example/a", "http://example/b": "c"}),
            turtle: %q(@prefix ex: <http://example/> . ex:a ex:b "c" .),
          }.each do |format, input|
            context format do
              it "detects #{format}" do
                get '/distiller',
                    input: input,
                    output_format: "ntriples",
                    raw: true
                expect(last_response.body).to_not be_empty
                expect(last_response).to be_ok
              end
            end
          end
        end
      end
    end
    
    context "RAW output" do
      context "form data" do
        it "retrieves a graph" do
          get '/distiller',
            input: %(<http://example/a> <http://example/b> "c" .),
            format: "ntriples",
            output_format: "ntriples",
            raw: "true"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('application/n-triples')
          expect(last_response.body).to eq %(<http://example/a> <http://example/b> "c" .\n)
        end
      end

      it "requires url to be absolute" do
        get '/distiller', url: 'relative-foo', fmt: "ntriples", raw: "true"
        expect(last_response).not_to be_ok
      end

      it "requires base_uri to be absolute" do
        get '/distiller',
          input: %(<http://example/a> <http://example/b> "c" .),
          format: "ntriples",
          base_uri: "relative-foo",
          output_format: "ntriples",
          raw: "true"
        expect(last_response).not_to be_ok
      end
    end

    context "RDF Formats" do
      RDF::Format.each do |format|
        next if format.writer.nil? || format == RDF::Vocabulary::Format
        it "retrieves graph as #{format.to_sym}" do
          get '/distiller',
            input: %(<http://example/a> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example/C> .),
            format: "ntriples",
            output_format: format.to_sym,
            raw: "true"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include(format.content_type.first)
        end
      end
    end
  end
end
