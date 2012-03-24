$:.unshift "."
require 'spec_helper'
require 'linkeddata'

describe RDF::Distiller::Application do
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
          get '/distiller',
            :content => ::URI.escape(%(<a> <b> "c" .)),
            :in_fmt => "ntriples",
            :fmt => "ntriples",
            :raw => "true"
          last_response.status.should == 200
          last_response.content_type.should include('text/plain')
          last_response.body.should == %(<a> <b> "c" .\n)
        end
      end
    end

    context "RDF Formats" do
      RDF::Format.each do |format|
        next unless format.writer
        it "retrieves graph as #{format.to_sym}" do
          get '/distiller',
            :content => ::URI.escape(%(<a> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <C> .)),
            :in_fmt => "ntriples",
            :fmt => format.to_sym,
            :raw => "true"
          last_response.status.should == 200
          last_response.content_type.should include(format.content_type.first)
        end
      end
    end
  end
end
