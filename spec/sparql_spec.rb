$:.unshift "."
require 'spec_helper'
require 'linkeddata'

describe RDF::Distiller::Application do
  before(:each) do
    $debug_output = StringIO.new()
    $logger = Logger.new($debug_output)
    $logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
  end

  describe "/sparql" do
    before(:all) {@doap = RDF::Repository.new << [RDF::URI("http://example/doap"), RDF.type, RDF::DOAP.to_uri]}
    before(:each) {allow(RDF::Repository).to receive(:load).and_return(@doap)}

    describe "service_description" do
      it "returns a serialized graph" do
        get '/sparql', {}, {'HTTP_ACCEPT' => 'application/turtle'}
        expect(last_response.body).to eq "" unless last_response.ok?
        expect(last_response.body).to match(/^@prefix ssd: <.*> \.$/)
        expect(last_response.body).to match(/\[ a ssd:Service;/)
      end
    end

    context "serializes graphs" do
      context "with format" do
        {
          :ntriples => "<http://example/doap> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://usefulinc.com/ns/doap#> .",
          :ttl => %r(<http://example/doap> a doap: .)
        }.each do |fmt, expected|
          context fmt do
            it "returns serialization" do
              get '/sparql', :query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o}), :fmt => fmt, :raw => true
              expect(last_response.body).to eq "" unless last_response.ok?
              expect(last_response.body).to match(expected)
              expect(last_response.content_type).to eq RDF::Format.for(fmt).content_type.first
              expect(last_response.content_length).not_to eq 0
            end
          end
        end
      end

      context "with Accept" do
        {
          "text/plain" => "<http://example/doap> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://usefulinc.com/ns/doap#> .",
          "application/turtle" => %r(<http://example/doap> a doap: .)
        }.each do |content_types, expected|
          context content_types do
            it "returns serialization" do
              get '/sparql', {:query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o})}, {"HTTP_ACCEPT" => content_types}
              $logger.debug last_response.inspect
              expect(last_response.body).to eq "" unless last_response.ok?
              expect(last_response.body).to match(expected)
              expect(last_response.content_type).to eq content_types
            end
          end
        end
      end
    end

    context "serializes solutions" do
      context "with format" do
        {
          :json => /\s*"head"/,
          :html => /<table class="sparql"/,
          :xml => /<\?xml version/,
        }.each do |fmt, expected|
          context fmt do
            it "returns serialization" do
              get '/sparql', :query => %(SELECT ?s ?p ?o WHERE {?s ?p ?o}), :fmt => fmt, :raw => true
              expect(last_response.body).to eq "" unless last_response.ok?
              expect(last_response.body).to match(expected)
              expect(last_response.content_type).to include(SPARQL::Results::MIME_TYPES[fmt])
              expect(last_response.content_length).not_to eq 0
            end
          end
        end
      end

      context "with Accept" do
        {
          ::SPARQL::Results::MIME_TYPES[:json] => /\s*"head"/,
          ::SPARQL::Results::MIME_TYPES[:html] => /<!DOCTYPE html/,
          ::SPARQL::Results::MIME_TYPES[:xml] => /<\?xml version/,
        }.each do |content_types, expected|
          context content_types do
            it "returns serialization" do
              get '/sparql', {:query => %(SELECT ?s ?p ?o WHERE {?s ?p ?o}), :raw => true}, {"HTTP_ACCEPT" => content_types}
              expect(last_response.body).to match(expected)
              expect(last_response.content_type).to include(content_types)
              expect(last_response.content_length).not_to eq 0
            end
          end
        end
      end
    end

    it "returns sse" do
      get '/sparql', :query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o}), :fmt => "sse", :raw => true
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.body).to eq %((construct ((triple ?s ?p ?o)) (bgp (triple ?s ?p ?o)))\n)
      expect(last_response.content_type).to include("application/sse+sparql-query")
    end
  end
end
