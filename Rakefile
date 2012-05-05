require 'rubygems'
require 'fileutils'
require 'yard'

task :yard => [:clean_doc, :readme]

YARD::Rake::YardocTask.new do |y|
  y.files = Dir.glob("lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/rdf*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/json-ld/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sparql*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/spira*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sxp*/lib/**/*.rb") +
            ["-"] +
            Dir.glob("*-README")
end

desc "Clean documentation"
task :clean_doc do
  FileUtils.rm_rf 'doc'
end

desc "Create README links"
task :readme do
  Dir.glob("readmes/*").each {|d| FileUtils.rm d}
  Dir.glob('vendor/bundler/**/README').each do |path|
    d = path.split('/')[-2]
    next unless d
    d.sub!(/-([a-z0-9]{12})$/, '')
    d.sub!(/-\d+\.\d+(?:\.\d+)$/, '')
    puts "link #{path} to readmes/#{d}"
    FileUtils.ln_s "../#{path}", "readmes/#{d}" unless File.exist?("readmes/#{d}")
  end
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

  g = RDF::Repository.new
  Dir.glob('vendor/bundler/**/etc/doap.*') do |path|
    begin
      puts "load #{path}"
      g.load(path)
    rescue
      puts "#{$!}"
    end
  end
  RDF::NTriples::Writer.open("etc/doap.nt") {|w| w << g}
end