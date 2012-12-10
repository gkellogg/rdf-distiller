$:.unshift "."
require 'spec_helper'

describe RDF::Distiller::Application do
  before(:each) do
    $debug_output = StringIO.new()
    $logger = Logger.new($debug_output)
    $logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
  end

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
