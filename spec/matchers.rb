require 'rspec/matchers'

RSpec::Matchers.define :have_xpath do |xpath, value, trace|
  match do |actual|
    @doc = Nokogiri::XML.parse(actual)
    @doc.should be_a(Nokogiri::XML::Document)
    @doc.root.should be_a(Nokogiri::XML::Element)
    @namespaces = @doc.namespaces.merge("xhtml" => "http://www.w3.org/1999/xhtml", "xml" => "http://www.w3.org/XML/1998/namespace")
    case value
    when false
      @doc.root.at_xpath(xpath, @namespaces).should be_nil
    when true
      @doc.root.at_xpath(xpath, @namespaces).should_not be_nil
    when Array
      @doc.root.at_xpath(xpath, @namespaces).to_s.split(" ").should include(*value)
    when Regexp
      @doc.root.at_xpath(xpath, @namespaces).to_s.should =~ value
    else
      @doc.root.at_xpath(xpath, @namespaces).to_s.should == value
    end
  end
  
  failure_message_for_should do |actual|
    msg = "expected that #{xpath.inspect} would be #{value.inspect} in:\n" + actual.to_s
    msg += "was: #{@doc.root.at_xpath(xpath, @namespaces)}"
    msg +=  "\nDebug:#{trace.join("\n")}" if trace
    msg
  end
  
  failure_message_for_should_not do |actual|
    msg = "expected that #{xpath.inspect} would not be #{value.inspect} in:\n" + actual.to_s
    msg +=  "\nDebug:#{trace.join("\n")}" if trace
    msg
  end
end

require 'linkeddata'

RSpec::Matchers.define :have_format do |format|
  match do |actual|
    RDF::Format.for(:sample => actual).should == RDF::Format.for(format)
  end

  failure_message_for_should do |actual|
    msg = "expected expected format #{format.inspect}, found #{RDF::Format.for(:sample => actual).to_sym.inspect}" +
    "\nResult: #{actual}"
  end
end

