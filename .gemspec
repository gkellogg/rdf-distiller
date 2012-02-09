#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.version            = File.read('VERSION').chomp
  s.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  s.name               = 'rdf-portal'
  s.homepage           = 'http://gkellogg/rdf-portal/'
  s.license            = 'Public Domain' if s.respond_to?(:license=)
  s.summary            = 'Web portal for RDF.rb.'
  s.description        = s.summary

  s.authors            = ['Gregg Kellogg']
  s.email              = 'public-rdf-ruby@w3.org'

  s.platform           = Gem::Platform::RUBY
  s.files              = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  s.bindir             = %q(bin)
  s.executables        = %w()
  s.default_executable = s.executables.first
  s.require_paths      = %w(lib)
  s.extensions         = %w()
  s.test_files         = %w()
  s.has_rdoc           = false

  s.required_ruby_version      = '>= 1.8.7'
  s.requirements               = []

  # RDF dependencies
  s.add_runtime_dependency      "linkeddata",         '>= 0.3.4'
  s.add_runtime_dependency      'equivalent-xml',     '>= 0.2.8'
  s.add_runtime_dependency      'sparql',             '>= 0.1.0'

  # Sinatra dependencies        
  s.add_runtime_dependency      'sinatra',            '>= 1.2.1'
  s.add_runtime_dependency      'erubis',             '>= 2.6.6'
  s.add_runtime_dependency      "rack",               '>= 1.3.1'
  s.add_runtime_dependency      'sinatra-respond_to', '>= 0.8.0'

  # development dependencies    
  s.add_development_dependency  'yard' ,              '>= 0.6.7'
  s.add_development_dependency  'rspec',              '>= 2.5.0'
  s.add_development_dependency  'rack-test',          '>= 0.5.6'
  s.add_development_dependency  'bundler'
  s.post_install_message        = nil
end
