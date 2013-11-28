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
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Ruby Linked Data Service}
    end
  end
  
  describe "about" do
    it "gets HTML" do
      get '/about'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Ruby Linked Data Service}
    end
  end
end
