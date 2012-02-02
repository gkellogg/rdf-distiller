$:.unshift "."
require 'spec_helper'

describe RDF::Portal::Application do
  describe "/doap" do
    it "gets RDFa by default" do
      get '/doap'
      last_response['Content-Type'].should =~ %r{#{mime_type(:html)}}
      last_response.should be_ok
      last_response.body.should match(/<html prefix/)
    end

    it "gets RDFa with .html extension" do
      get '/doap.html'
      last_response['Content-Type'].should =~ %r{#{mime_type(:html)}}
      last_response.should be_ok
      last_response.body.should match(/<html prefix/)
    end

    it "gets NTriples with .nt extension" do
      get '/doap.nt'
      last_response['Content-Type'].should =~ %r{#{mime_type(:text)}}
      last_response.should be_ok
      last_response.body.should have_format(:nquads)
    end

    it "gets NTriples with text/plain ACCEPT header" do
      get '/doap.nt', {}, {"HTTP_ACCEPT" => "text/plain"}
      last_response['Content-Type'].should =~ %r{#{mime_type(:text)}}
      last_response.should be_ok
      last_response.body.should have_format(:nquads)
    end
  end
end
