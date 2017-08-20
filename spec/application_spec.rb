$:.unshift ".."
require 'spec_helper'

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

  describe "/" do
    it "gets HTML" do
      get '/'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Ruby Linked Data Service}
    end
  end
  
  describe "/about" do
    it "gets HTML" do
      get '/about'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Ruby Linked Data Service}
    end
  end
  
  describe "/distiller" do
    context "HTML" do
      subject {
        get "/distiller", {}, "HTTP_ACCEPT" => "text/html"
        last_response
      }
      it {should be_ok}
      its(:content_type) {should include("text/html")}

      context "body" do
        {
          "/html" => true,
          "/html/body/@class" => "distiller",
          "/html/head/title/text()" => "Ruby Distiller"
        }.each do |xpath, value|
          it "has xpath #{xpath}" do
            expect(subject.body).to have_xpath(xpath, value)
          end
        end
      end

      context "raw" do
        let(:opts) {{
          content: %(<http://example/a> <http://example/b> "c" .),
          in_fmt: "ntriples",
          raw: "true"
        }}
        subject {
          expect_any_instance_of(RDF::Distiller::Application).to receive(:distil).
            with(hash_including(opts)).
            and_return({format: "text/html", serialized: ""})
          get '/distiller', opts, "HTTP_ACCEPT" => "text/html"
          last_response
        }
        it {should be_ok}
        its(:content_type) {should include("text/html")}
      end
    end

    context "JSON XHR" do
      {
        "url" => {"url" => "http://example/"},
        "url and base_uri" => {"url" => "http://example/", "base_uri" => "http://foo/"},
        "validate" => {"validate" => "true"},
        "verify_none" => {"verify_none" => "true"},
        "content" => {"content" => "foo"},
      }.each do |param, opts|
        context "with #{param}" do
          context "GET" do
            subject {
              expect_any_instance_of(RDF::Distiller::Application).to receive(:distil).
                with(hash_including(opts)).
                and_return({})
              get "/distiller", opts,
                  "HTTP_ACCEPT" => "application/json",
                  "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"
              last_response
            }
            it {should be_ok}
            its(:content_type) {should include("application/json")}
          end

          context "POST" do
            subject {
              expect_any_instance_of(RDF::Distiller::Application).to receive(:distil).
                with(hash_including(opts)).
                and_return({})
              post "/distiller", opts.to_json,
                  "HTTP_ACCEPT" => "application/json",
                  "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"
              last_response
            }
            it {should be_ok}
            its(:content_type) {should include("application/json")}
          end
        end
      end
    end

    describe "/distiller/load" do
      it "loads remote resource"
      it "signals error if resource not found"
    end
  end
  
  describe "/doap" do
    it "gets HTML" do
      get '/doap'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Project Information on included Gems}
    end
  end
end
