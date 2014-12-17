$:.unshift "."
require 'spec_helper'

describe RDF::Distiller::Application do
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
  
  describe "about" do
    it "gets HTML" do
      get '/about'
      expect(last_response.body).to eq "" unless last_response.ok?
      expect(last_response.content_type).to match %r{#{mime_type(:html)}}
      expect(last_response.body).to match %r{Ruby Linked Data Service}
    end
  end
end
