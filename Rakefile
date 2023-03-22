require 'rubygems'
require 'bundler/setup'
require 'restclient/components'
require 'rack/cache'
require 'rdf/distiller'
require 'fileutils'
require 'yard'

desc "Build DOAP files and documentation"
task default: [:doap, :yard]

desc "Build documentation"
task yard: [:clean_doc, :readme] do
  files = %w(lib/ readmes/ ) +
          Dir.glob("vendor/bundler/ruby/*/bundler/gems/*/lib/") +
          %w(- README.me) +
          Dir.glob("readmes/*-README")
  cmd = 'yardoc ' + files.join(' ')
  puts cmd
  %x(#{cmd})
end

desc "Clean documentation"
task :clean_doc do
  FileUtils.rm_rf 'doc'
end

desc "Create README links"
task :readme do
  dir = File.expand_path("../", __FILE__)
  FileUtils.mkdir_p("readmes")
  Dir.glob("readmes/*").each {|d| FileUtils.rm d}
  Dir.glob('vendor/bundler/**/README.md').each do |path|
    d = path.split('/')[-2]
    next unless d.match?(/(.*rdf.*|.*sparql.*|json-ld.*|sxp|ebnf)/)
    d.sub!(/-([a-z0-9]{12})$/, '')
    d.sub!(/-\d+\.\d+(?:\.\d+)$/, '')
    puts "link #{path} to readmes/#{d}-README"
    FileUtils.ln_s "#{dir}/#{path}", "#{dir}/readmes/#{d}-README" unless File.exist?("#{dir}/readmes/#{d}-README")
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
  require 'rdf/json'
  require 'equivalent-xml'
  require 'yaml'

  g = RDF::Graph.new
  Dir.glob('vendor/bundler/**/etc/doap.*') do |path|
    begin
      next if path =~ %r(/rdf-\d.*\.(nq|nt)$)
      next if path.end_with?('metadata.json')
      puts "load #{path}"
      g.load("file:/" + File.expand_path(path))
    rescue
      puts "#{$!}"
    end
  end
  l = Logger.new(STDERR)
  RDF::NTriples::Writer.open("etc/doap.nt", logger: l) {|w| w << g}
  puts "dumped ntriples"

  frame = File.open(File.expand_path("../etc/doap-frame.jsonld", __FILE__))
  JSON::LD::API.fromRDF(g.each_statement.to_a) do |expanded|
    puts "expanded"
    JSON::LD::API.frame(expanded, frame) do |framed|
      puts "frame"
      File.open("etc/doap.jsonld", "w") do |f|
        f.write(framed.to_json(JSON::LD::JSON_STATE))
      end
    end
  end
end
