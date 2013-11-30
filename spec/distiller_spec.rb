$:.unshift "."
require 'spec_helper'
require 'linkeddata'
require 'webmock/rspec'

describe RDF::Distiller::Application do
  before(:each) do
    $debug_output = StringIO.new()
    $logger = Logger.new($debug_output)
    $logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
  end

  describe "/distiller" do
    context "HTML output" do
      context "URL" do
        before(:each) do
          WebMock.stub_request(:get, 'http://example.com/foo').
            to_return(:body =>  %(<http://example/a> <http://example/b> "c" .),
                      :status => 200,
                      :headers => { 'Content-Type' => 'text/ntriples'})
        end

        it "retrieves a graph" do
          get '/distiller', :url => 'http://example.com/foo', :fmt => "ntriples"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('text/html')
        end
      end

      context "form data" do
        it "retrieves a graph" do
          get '/distiller',
              :content => ::URI.escape(%(<http://example/a> <http://example/b> "c" .)),
              :in_fmt => "ntriples",
              :fmt => "ntriples"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('text/html')
        end

        context "content detection" do
          {
            jsonld: %q({"@id": "http://example/a", "http://example/b": "c"}),
            turtle: %q(@prefix ex: <http://example/> . ex:a ex:b "c" .),
          }.each do |format, input|
            context format do
              it "detects format" do
                get '/distiller',
                    :content => input,
                    :in_fmt => "content",
                    :fmt => "ntriples",
                    :raw => true
                expect(last_response.body).to eq "" unless last_response.ok?
                expect(last_response.content_type).to include('application/n-triples')
                in_g = RDF::Graph.new << RDF::Reader.for(format).new(input)
                expect(in_g.count).to eq 1
                expect(in_g.statements.first).to eq RDF::Statement(RDF::URI("http://example/a"), RDF::URI("http://example/b"), RDF::Literal("c"))
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
            :content => ::URI.escape(%(<http://example/a> <http://example/b> "c" .)),
            :in_fmt => "ntriples",
            :fmt => "ntriples",
            :raw => "true"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include('application/n-triples')
          expect(last_response.body).to eq %(<http://example/a> <http://example/b> "c" .\n)
        end
      end
    end

    context "RDF Formats" do
      RDF::Format.each do |format|
        next unless format.writer
        it "retrieves graph as #{format.to_sym}" do
          get '/distiller',
            :content => ::URI.escape(%(<http://example/a> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example/C> .)),
            :in_fmt => "ntriples",
            :fmt => format.to_sym,
            :raw => "true"
          expect(last_response.body).to eq "" unless last_response.ok?
          expect(last_response.content_type).to include(format.content_type.first)
        end
      end
    end
  end
end
