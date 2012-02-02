$:.unshift "."
require 'spec_helper'

describe RDF::Portal::Application do
  describe "/" do
    it "gets HTML" do
      get '/'
      last_response['Content-Type'].should =~ %r{#{mime_type(:html)}}
      last_response.should be_ok
      last_response.body.should match %r{Ruby Linked Data Service}
    end
  end
  
  describe "about" do
    it "gets HTML" do
      get '/about'
      last_response['Content-Type'].should =~ %r{#{mime_type(:html)}}
      last_response.should be_ok
      last_response.body.should match %r{Ruby Linked Data Service}
    end
  end
end
