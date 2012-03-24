$:.unshift "."
require 'spec_helper'
require 'linkeddata'

describe RDF::Distiller::Application do
  describe "/sparql" do
    before(:all) {@doap = RDF::Repository.new << [RDF::URI("doap"), RDF.type, RDF::DOAP.to_uri]}
    before(:each) {RDF::Repository.stub!(:load).and_return(@doap)}

    describe "service_description" do
      it "returns a serialized graph" do
        get '/sparql', {}, {'HTTP_ACCEPT' => 'text/turtle'}
        last_response.status.should == 200
        last_response.body.should match(/^@prefix ssd: <.*> \.$/)
        last_response.body.should match(/\[ a ssd:Service;/)
      end
    end

    context "serializes graphs" do
      context "with format" do
        {
          :ntriples => "<doap> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://usefulinc.com/ns/doap#> .",
          :ttl => /<doap> a doap: ./
        }.each do |fmt, expected|
          context fmt do
            it "returns serialization" do
              get '/sparql', :query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o}), :fmt => fmt, :raw => true
              last_response.status.should == 200
              last_response.body.should match(expected)
              last_response.content_type.should == RDF::Format.for(fmt).content_type.first
              last_response.content_length.should_not == 0
            end
          end
        end
      end

      context "with Accept" do
        {
          "text/plain" => "<doap> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://usefulinc.com/ns/doap#> .",
          "text/turtle" => /<doap> a doap: ./
        }.each do |content_types, expected|
          context content_types do
            it "returns serialization" do
              get '/sparql', {:query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o})}, {"HTTP_ACCEPT" => content_types}
              puts last_response.inspect
              last_response.status.should == 200
              last_response.body.should match(expected)
              last_response.content_type.should == content_types
            end
          end
        end
      end
    end

    context "serializes solutions" do
      context "with format" do
        {
          :json => /{\s*"head"/,
          :html => /<table class="sparql"/,
          :xml => /<\?xml version/,
        }.each do |fmt, expected|
          context fmt do
            it "returns serialization" do
              get '/sparql', :query => %(SELECT ?s ?p ?o WHERE {?s ?p ?o}), :fmt => fmt, :raw => true
              last_response.status.should == 200
              last_response.body.should match(expected)
              last_response.content_type.should include(SPARQL::Results::MIME_TYPES[fmt])
              last_response.content_length.should_not == 0
            end
          end
        end
      end

      context "with Accept" do
        {
          ::SPARQL::Results::MIME_TYPES[:json] => /{\s*"head"/,
          ::SPARQL::Results::MIME_TYPES[:html] => /<!DOCTYPE html/,
          ::SPARQL::Results::MIME_TYPES[:xml] => /<\?xml version/,
        }.each do |content_types, expected|
          context content_types do
            it "returns serialization" do
              get '/sparql', {:query => %(SELECT ?s ?p ?o WHERE {?s ?p ?o}), :raw => true}, {"HTTP_ACCEPT" => content_types}
              last_response.body.should match(expected)
              last_response.content_type.should include(content_types)
              last_response.content_length.should_not == 0
            end
          end
        end
      end
    end

    it "returns sse" do
      get '/sparql', :query => %(CONSTRUCT {?s ?p ?o} WHERE {?s ?p ?o}), :fmt => "sse", :raw => true
      last_response.status.should == 200
      last_response.body.should == %((construct ((triple ?s ?p ?o)) (bgp (triple ?s ?p ?o))))
      last_response.content_type.should include("application/sse+sparql-query")
    end
  end
end
