$:.unshift ".."
require 'spec_helper'

describe ::RDF::Test::Core::Manifest do
  let(:logger) {
    l = Logger.new(StringIO.new)
    l.level = Logger::DEBUG
    l
  }

  let!(:graph) {RDF::Graph.load(File.expand_path("../data/manifest.ttl", __FILE__), base_uri: "http://example.com/manifest.ttl")}

  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe ".find" do
    context "default" do
      subject {described_class.find("default", logger: logger)}

      specify {is_expected.to be_a(described_class)}
      its(:label) {is_expected.to eql "Manifest List"}
      its(:entries) {is_expected.to be_a(Array)}
    end
    context "http://example.com/manifest.ttl" do

      before(:each) {
        allow(RDF::Graph).to receive(:load).with('http://example.com/manifest.ttl').
          and_return(graph)
      }

      subject {described_class.find("http://example.com/manifest.ttl", logger: logger)}

      specify {is_expected.to be_a(described_class)}
      its(:label) {is_expected.to eql "Test manifest"}
      its(:entries) {is_expected.to be_a(Array)}
    end
  end

  describe "#entry" do
    subject {described_class.find("file:" + File.expand_path("../data/manifest.ttl", __FILE__), logger: logger)}

    it "returns an entry" do
      expect(subject.entry("#syntax")).to be_a(::RDF::Test::Core::Entry)
    end
  end

  describe "#entries" do
    let!(:manifest) {described_class.find("file:" + File.expand_path("../data/manifest.ttl", __FILE__), logger: logger)}

    %w(
      #eval
      #eval-negative
      #syntax
      #syntax-negative
    ).each do |test|
      describe test do
        subject {manifest.entry(test)}
        specify {is_expected.to be_a(::RDF::Test::Core::Entry)}
        its(:id) {is_expected.to eql(test)}
        its(:action_body) {is_expected.to be_a(String)}
        if test.include?('syntax')
          its(:result_body) {is_expected.to be_nil}
          it {is_expected.to be_syntax}
          it {is_expected.not_to be_evaluate}
        else
          its(:result_body) {is_expected.to be_a(String)}
          it {is_expected.not_to be_syntax}
          it {is_expected.to be_evaluate}
        end
        if test.include?('negative')
          it {is_expected.to be_negative}
          it {is_expected.not_to be_positive}
        else
          it {is_expected.to be_positive}
          it {is_expected.not_to be_negative}
        end

        describe "#run" do
          specify {expect {|b| subject.run('http://example.org/reflector?url=', &b)}.to yield_control}

          it "returns extracted content" do
            subject.run('http://example.org/reflector?url=') do |extracted, status, error|
              expect(extracted).to eql (subject.result_body || subject.action_body)
            end
          end

          it "returns status='#{test.include?('negative') ? 'Fail' : 'Pass'}'" do
            subject.run('http://example.org/reflector?url=') do |extracted, status, error|
              expect(status).to eql(test.include?('negative') ? 'Fail' : 'Pass')
            end
          end
        end
      end
    end
  end
end
