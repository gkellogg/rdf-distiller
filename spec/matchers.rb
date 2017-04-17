require 'rspec/matchers'
require 'json'
require 'jsonpath'
require 'nokogiri'

RSpec::Matchers.define :have_jsonpath do |path, value, trace|
  p = JsonPath.new(path)
  match do |actual|
    case value
    when FalseClass
      p.on(actual).empty?
    when TrueClass
      !p.on(actual).empty?
    when Regexp
      p.on(actual).to_s =~ value
    else
      p.on(actual) == Array(value)
    end
  end
  
  failure_message do |actual|
    msg = "expected that #{path.inspect}\nwould be: #{value.inspect}"
    msg += "\n     was: #{JsonPath.new(path).on(actual)}"
    msg += "\nsource:" + actual
    msg
  end
  
  failure_message_when_negated do |actual|
    msg = "expected that #{path.inspect}\nwould not be #{value.inspect}"
    msg += "\nsource:" + actual
    msg
  end
end

RSpec::Matchers.define :have_xpath do |path, value, trace|
  match do |actual|
    @doc = Nokogiri::HTML.parse(actual)
    return false unless @doc.is_a?(Nokogiri::XML::Document)
    return false unless @doc.root.is_a?(Nokogiri::XML::Element)
    case value
    when FalseClass
      @doc.root.xpath(path).empty?
    when TrueClass
      !@doc.root.xpath(path).empty?
    when Array
      @doc.root.xpath(path).map {|f| f.to_s.strip}.sort <=> value.sort
    when Regexp
      @doc.root.xpath(path).to_s =~ value
    else
      @doc.root.xpath(path).to_s.strip == value
    end
  end
  
  failure_message do |actual|
    msg = "expected that #{path.inspect} would be #{value.inspect} in:\n" + actual.to_s
    msg += "was: #{@doc.root.at_xpath(path)}"
    msg +=  "\nDebug:#{Array(trace).join("\n")}" if trace
    msg
  end
  
  failure_message_when_negated do |actual|
    msg = "expected that #{path.inspect} would not be #{value.inspect} in:\n" + actual.to_s
    msg +=  "\nDebug:#{Array(trace).join("\n")}" if trace
    msg
  end
end

require 'linkeddata'

RSpec::Matchers.define :have_format do |format|
  match do |actual|
    RDF::Format.for(sample: actual).should == RDF::Format.for(format)
  end

  failure_message_for_should do |actual|
    msg = "expected expected format #{format.inspect}, found #{RDF::Format.for(sample: actual).to_sym.inspect}" +
    "\nResult: #{actual}"
  end
end

