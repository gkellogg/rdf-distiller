$:.unshift "."
require 'spec_helper'
require 'json/ld'

describe RDF::Portal::Application do
  describe "/doap" do
    before(:all) {@doap = RDF::Repository.new << [RDF::URI("doap"), RDF.type, RDF::DOAP.to_uri]}
    before(:each) {RDF::Repository.stub!(:load).and_return(@doap)}

    context "Format symbols" do
      RDF::Format.each do |format|
        sym = format.to_sym
        context "#{sym}" do
          it "gets  with .#{sym} extension" do
            get "/doap.#{sym}"
            last_response['Content-Type'].should include(mime_type(sym))
            last_response.should be_ok
          end

          it "gets  with #{sym} format" do
            get "/doap", :format => sym
            last_response['Content-Type'].should include(mime_type(sym))
            last_response.should be_ok
          end
        end
      end
    end
    
    context "File extensions" do
      RDF::Format.file_extensions.keys.each do |extension|
        next if extension == :xml
        context "#{extension}" do
          it "gets  with .#{extension} extension" do
            get "/doap.#{extension}"
            last_response['Content-Type'].should include(mime_type(extension))
            last_response.should be_ok
          end

          it "gets  with #{extension} format" do
            get "/doap", :format => extension
            last_response['Content-Type'].should include(mime_type(extension))
            last_response.should be_ok
          end
        end
      end
    end

    context "Content Type" do
      RDF::Format.content_types.keys.each do |content_type|
        context "#{content_type}" do
          it "gets  with #{content_type}" do
            get "/doap", {}, {"HTTP_ACCEPT" => content_type}
            last_response['Content-Type'].should include(content_type)
            last_response.should be_ok
          end
        end
      end
    end
  end
end
