$:.unshift ".."
require 'spec_helper'

describe RDF::Test::Application do
  def app
   RDF::Test::Application
  end

  subject {last_response}

  let!(:graph) {RDF::Graph.load(File.expand_path("../data/manifest.ttl", __FILE__), base_uri: "http://example.com/manifest.ttl")}

  before(:each) {
    allow(RDF::Graph).to receive(:load).with('http://example.com/manifest.ttl').
      and_return(graph)
    %w(
      eval.ttl eval.nt
      eval-negative.ttl eval-negative.nt
      syntax.ttl syntax-negative.ttl
    ).each do |f|
      ct = f.end_with?('.ttl') ? 'text/turtle' : 'application/n-triples'
      WebMock.stub_request(:get, "http://example.com/#{f}").
      to_return(body: File.read(File.expand_path("../data/#{f}", __FILE__)),
                status: 200,
                headers: {
                  'Content-Type' => ct
                })
    end
  }

  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe "application" do
    %w(/tests /about /developers).each do |location|
      describe location do
        before(:all) {get location}
        it "loads testApp" do
          expect(subject).to be_ok
          expect(subject.body).to eq "" unless last_response.ok?
          expect(subject.content_type).to match %r{#{mime_type(:html)}}
          expect(subject.body).to match %r{RDF Test Runner}
        end

      end
    end
  end

  describe '/tests' do
    context "as HTML" do
      before(:all) {get '/tests'}

      it "has application JSON" do
        expect(subject.body).to have_xpath("/html/head/script[contains(@src, 'application')]", true)
      end

      context "processors" do
        subject {
          html = Nokogiri::HTML.parse(last_response.body)
          procs = html.at_xpath("/html/head/script[@id='processors']").content
        }
        specify {is_expected.not_to be_empty}

        context "paths" do
          {
            "$[0]['id']" => "reflector",
           }.each do |path, value|
            it "#{path} matches #{value.inspect}" do
              expect(subject).to have_jsonpath(path, [value])
            end
          end
        end
      end
    end

    context "as JSON-LD" do
      before(:all) {get '/tests', {}, 'HTTP_ACCEPT' => 'application/ld+json'}
      its(:content_type) {is_expected.to include 'application/ld+json'}

      context "paths" do
        {
          "$['id']" => /manifest.ttl/,
          "$['@context']" => true,
          "$['type']" => "mf:Manifest",
          "$['label']" => "Manifest List",
          "$['mf:entries']" => [nil],
          "$['manifests']" => true,
          "$['manifests'][0]['id']" => /N-TriplesTests/,
         }.each do |path, value|
          it "#{path} matches #{value.inspect}" do
            expect(subject.body).to have_jsonpath(path, value)
          end
        end
      end

      context "with manifestUrl" do
        before(:each) {
          get '/tests', {manifestUrl: 'http://example.com/manifest.ttl'}, 'HTTP_ACCEPT' => 'application/ld+json'
        }

        context "paths" do
          {
            "$id" => /manifest.ttl/,
            "$['@context']" => true,
            "$type" => "mf:Manifest",
            "$label" => "Test manifest",
            "$entries" => true,
            "$manifests" => false,
            "$entries[0].id" => /#syntax/,
            "$entries[0].type" => "rdft:TestSyntax",
            "$entries[0].name" => "Syntax Test",
            "$entries[0].action" => /syntax.ttl/,
           }.each do |path, value|
            it "#{path} matches #{value.inspect}" do
              expect(subject.body).to have_jsonpath(path, value)
            end
          end
        end
      end
    end
    context ".jsonld" do
      before(:all) {get '/tests.jsonld'}
      its(:content_type) {is_expected.to eql 'application/ld+json'}
    end

    context "as Turtle" do
      before(:all) {get '/tests', {}, 'HTTP_ACCEPT' => 'text/turtle'}
      its(:content_type) {is_expected.to include 'text/turtle'}
    end
    context ".ttl" do
      before(:all) {get '/tests.ttl'}
      its(:content_type) {is_expected.to include 'text/turtle'}
    end
  end

  describe '/tests/%23syntax' do
    before(:each) do
      allow_any_instance_of(::RDF::Test::Core::Entry).to receive(:action_body).and_return("action")
      allow_any_instance_of(::RDF::Test::Core::Entry).to receive(:result_body).and_return("result")
    end
    describe "GET" do
      context "as HTML" do
        before(:each) {get '/tests/%23syntax', {manifestUrl: 'http://example.com/manifest.ttl'}}
        its(:status) {is_expected.to eql 500}
        its(:body) {is_expected.to match /Only JSON-LD request type supported for Test detail/}
      end

      context "as JSON-LD" do
        before(:each) {get '/tests/%23syntax', {manifestUrl: 'http://example.com/manifest.ttl'}, "HTTP_ACCEPT" => 'application/ld+json'}
        its(:content_type) {is_expected.to include 'application/ld+json'}

        context "paths" do
          {
            "$id"           => "#syntax",
            "$['@context']" => true,
            "$type"         => "rdft:TestSyntax",
            "$comment"      => "Basic Syntax test",
            "$action"       => "syntax.ttl",
            "$result"       => false
           }.each do |path, value|
            it "#{path} matches #{value.inspect}" do
              expect(subject.body).to have_jsonpath(path, value)
            end
          end
        end
      end
    end

    describe "POST" do
      context "as JSON-LD" do
        before(:each) {post '/tests/%23syntax', {manifestUrl: 'http://example.com/manifest.ttl', processorUrl: 'http://example.org/processorUrl'}, "HTTP_ACCEPT" => 'application/ld+json'}
        its(:content_type) {is_expected.to include 'application/ld+json'}

        context "paths" do
          {
            "$id"           => "#syntax",
            "$['@context']" => true,
            "$type"         => "rdft:TestSyntax",
            "$comment"      => "Basic Syntax test",
            "$action"       => "syntax.ttl",
            "$result"       => false,
            "$status"        => true,
            "$extracted_body" => true,
            "$extracted_loc" => /processorUrl/
           }.each do |path, value|
            it "#{path} matches #{value.inspect}" do
              expect(subject.body).to have_jsonpath(path, value)
            end
          end
        end
      end
    end
  end

  describe "redirects" do
    {
      '/'            => '/tests',
      '/tests/'      => '/tests',
      '/about/'      => '/about',
      '/developers/' => '/developers'
    }.each do |from, location|
      it "#{from} redirects to #{location}" do
        get from
        expect(last_response).to be_redirect
        expect(last_response.location).to include(location)
      end
    end
  end
end
