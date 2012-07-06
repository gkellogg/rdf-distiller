require 'rubygems'
require 'fileutils'
require 'yard'

task :yard => :clean_doc

YARD::Rake::YardocTask.new do |y|
  y.files = Dir.glob("lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/rdf*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/json-ld*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sparql*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/spira*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sxp*/lib/**/*.rb")
end

desc "Clean documentation"
task :clean_doc do
  FileUtils.rm_rf 'doc'
end

namespace :cache do
  desc 'Clear document cache'
  task :clear do
    FileUtils.rm_rf File.expand_path("../cache", __FILE__)
  end
end

desc "Create DOAP links"
task :doap do
  require 'linkeddata'
  require 'rdf/trig'
  require 'json/ld'
  require 'rdf/json'
  require 'rdf/microdata'
  require 'equivalent-xml'
  require 'yaml'

  g = RDF::Graph.new
  Dir.glob('vendor/bundler/**/etc/doap.*') do |path|
    begin
      next if path =~ %r(/rdf-\d.*\.(nq|nt)$)
      puts "load #{path}"
      g.load(path)
    rescue
      puts "#{$!}"
    end
  end
  RDF::NTriples::Writer.open("etc/doap.nt") {|w| w << g}
  puts "dumped ntriples"

  frame = File.open(File.expand_path("../etc/doap-frame.jsonld", __FILE__))
  JSON::LD::API.fromRDF(g.each_statement.to_a) do |expanded|
    puts "expanded"
    JSON::LD::API.frame(expanded, frame, nil) do |framed|
      puts "frame"
      File.open("etc/doap.jsonld", "w") do |f|
        f.write(framed.to_json(JSON::LD::JSON_STATE))
      end
    end
  end
end