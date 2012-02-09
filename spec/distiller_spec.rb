$:.unshift "."
require 'spec_helper'

describe RDF::Portal::Application do
  describe "/distiller" do
    context "HTML output" do
      context "URL" do
        before(:each) do
          nt = %(<a> <b> "c" .)
          io = StringIO.new(nt)
          io.stub!(:content_type).and_return("text/plain")
          Object.any_instance.stub(:open_file).with("http://example.com/foo").and_yield(io)
        end

        it "retrieves a graph" do
          get '/distiller', :url => 'http://example.com/foo', :fmt => "ntriples"
          last_response.status.should == 200
          last_response.content_type.should include('text/html')
        end
      end

      context "form data" do
        it "retrieves a graph" do
          get '/distiller', :content => ::URI.escape(%(<a> <b> "c" .)), :in_fmt => "ntriples", :fmt => "ntriples"
          last_response.status.should == 200
          last_response.content_type.should include('text/html')
        end
      end
    end
    
    context "RAW output" do
      context "form data" do
        it "retrieves a graph" do
          get '/distiller', :content => ::URI.escape(%(<a> <b> "c" .)), :in_fmt => "ntriples", :fmt => "ntriples", :raw => "true"
          last_response.status.should == 200
          last_response.content_type.should include('text/plain')
          last_response.body.should == %(<a> <b> "c" .\n)
        end
      end
    end
  end
end
