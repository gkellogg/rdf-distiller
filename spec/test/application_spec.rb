$:.unshift ".."
require 'spec_helper'

describe RDF::Test::Application do
  def app
    described_class.new
  end

  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe "/tests" do
    it "GET HTML by default" do
      get '/tests'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to start_with mime_type(:html)
      expect(last_response.body).to match %r{The CSVW Test Harness}
      expect(last_response.headers).to include("Cache-Control"=>"public, must-revalidate, max-age=300")
    end

    it "GET HTML with text/html" do
      get '/tests', {}, "HTTP_ACCEPT" => 'text/html'
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:html)
      expect(last_response.body).to match %r{The CSVW Test Harness}
    end

    it "GET HTML with .html" do
      get '/tests.html'
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:html)
    end

    it "GET JSON-LD with application/ld+json" do
      get '/tests', {}, "HTTP_ACCEPT" => "application/ld+json"
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:jsonld)
      {
        "$['@context']" => true,
        "$id"      => [""],
        "$type"    => ["mf:Manifest"],
        "$entries"  => true
      }.each do |path, value|
        expect(last_response.body).to have_jsonpath(path, value)
      end
      expect(last_response.headers).to include("Cache-Control"=>"public, must-revalidate, max-age=300")
      expect(last_response.headers).to include("ETag")
    end

    it "GET JSON-LD with .jsonld" do
      get '/tests.jsonld', {}
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:jsonld)
    end

    it "GET Turtle with text/turtle" do
      get '/tests', {}, "HTTP_ACCEPT" => "text/turtle"
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:ttl)
      expect(last_response.body).to match(/@prefix/)
      expect(last_response.headers).to include("Cache-Control"=>"public, must-revalidate, max-age=300")
      expect(last_response.headers).to include("ETag")
    end

    it "GET Turtle with .ttl" do
      get '/tests.ttl', {}
      expect(last_response).to be_ok
      expect(last_response.content_type).to start_with mime_type(:ttl)
    end
  end

  describe "/tests/test001r" do
    context "GET application/ld+json" do
      before(:all) {get '/tests/test001r', {}, "HTTP_ACCEPT" => "application/ld+json"}
      it "gets JSON-LD" do
        expect(last_response).to be_ok
        expect(last_response.body).not_to be_empty
        expect(last_response.content_type).to start_with mime_type(:jsonld)
        expect(last_response.headers).to include("Cache-Control"=>"public, must-revalidate, max-age=300")
        expect(last_response.headers).to include("ETag")
      end
      {
        "$['@context']" => true,
        "$action"  => ["test001.csv"],
        "$action_body"  => true,
        "$action_loc"  => [TEST_URI.join("test001.csv").to_s],
        "$approval"  => true,
        "$comment"  => true,
        "$id"      => ["test001r"],
        "$name"  => true,
        "$result"  => ["test001.jsonld"],
        "$result_loc"  => [TEST_URI.join("test001.jsonld").to_s],
        "$result_body"  => true,
        "$type"    => ["csvt:TestRdfSimpleEval"],
      }.each do |path, value|
        it "has #{path}" do
          expect(last_response.body).to have_jsonpath(path, value)
        end
      end
    end

    context "GET text/html" do
      before(:all) {get '/tests/test001r', {}, "HTTP_ACCEPT" => "text/html"}
      it "gets HTML", pending: "entry-specific application" do
        get '/tests.html', {}
        expect(last_response).to be_ok
        expect(last_response.content_type).to start_with mime_type(:html)
        expect(last_response.body).to include("test001.csv")
      end
    end

    context "POST" do
      before(:all) {
        WebMock.stub_request(:get, "http://example.org/endpoint?url=#{TEST_URI.join("test001.csv")}").
          to_return(:body => RestClient.get(TEST_URI.join("test001.jsonld").to_s),
                    :status => 200,
                    :headers => { 'Content-Type' => 'application/ld+json'})
        post '/tests/test001r', {processorUrl: "http://example.org/endpoint?url="}, "HTTP_ACCEPT" => "application/ld+json"
      }

      it "returns JSON-LD" do
        expect(last_response).to be_ok
        expect(last_response.body).not_to be_empty
        expect(last_response.content_type).to start_with mime_type(:jsonld)
      end

      it "requests application/json", pending: true do
        # FIXME: Figure this out later
        expect(WebMock).to have_requested(:get, "http://example.org/endpoint?url=#{TEST_URI.join("test001.csv")}").
          with(headers:  {'Content-Type' => 'application/json'})
      end

      {
        "$action"         => ["test001.csv"],
        "$action_body"    => true,
        "$action_loc"     => [TEST_URI.join("test001.csv").to_s],
        "$approval"       => true,
        "$comment"        => true,
        "$error"          => [nil],
        "$extracted_body" => true,
        "$extracted_loc"  => true,
        "$id"             => ["test001r"],
        "$name"           => true,
        "$result"         => ["test001.jsonld"],
        "$result_body"    => true,
        "$result_loc"     => [TEST_URI.join("test001.jsonld").to_s],
        "$status"         => ["Pass"],
        "$type"           => ["csvt:TestRdfSimpleEval"],
        "$['@context']"   => true,
      }.each do |path, value|
        it "has #{path}" do
          expect(last_response.body).to have_jsonpath(path, value)
        end
      end
    end
  end

  describe "tests/no-such-entry" do
    it "GET returns 404" do
      get '/tests/no-such-entry'
      expect(last_response).to be_not_found
    end

    it "POST returns 404" do
      post '/tests/no-such-entry'
      expect(last_response).to be_not_found
    end
  end
end
