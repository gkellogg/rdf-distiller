#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.version            = File.read('VERSION').chomp
  s.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  s.name               = 'rdf-distiller'
  s.homepage           = 'http://gkellogg/rdf-distiller/'
  s.license            = 'Public Domain' if s.respond_to?(:license=)
  s.summary            = 'Translate any RDF format to any other using Ruby RDF gems'
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

  s.required_ruby_version      = '>= 2.3.1'
  s.requirements               = []

  # RDF dependencies
  s.add_runtime_dependency      "linkeddata",         '~> 3.0'
  s.add_runtime_dependency      'equivalent-xml',     '~> 0.6'

  # Sinatra dependencies
  s.add_runtime_dependency      'sinatra',            '~> 2.0'
  s.add_runtime_dependency      'sinatra-asset-pipeline', '~> 2.0'
  s.add_runtime_dependency      'sass',               '~> 3.5'
  s.add_runtime_dependency      'sprockets-helpers',  '~> 1.2'
  s.add_runtime_dependency      'uglifier',           '~> 3.2'

  s.add_runtime_dependency      'erubis',             '~> 2.7'
  s.add_runtime_dependency      'haml',               '~> 5.0'
  s.add_runtime_dependency      'maruku',             '~> 0.7'
  s.add_runtime_dependency      'json-compare',       '~> 0.1'
  s.add_runtime_dependency      'json-ld-preloaded',  '~> 2.2'
  s.add_runtime_dependency      "rack",               '~> 2.0'
  s.add_runtime_dependency      'rest-client',        '~> 2.0'
  s.add_runtime_dependency      'rest-client-components', '~> 1.4'
  s.add_runtime_dependency      'rack-cache',         '~> 1.7'
  s.add_runtime_dependency      'redcarpet',          '~> 3.4'
  s.add_runtime_dependency      'puma',               '~> 3.11'
  s.add_runtime_dependency      'nokogiri',           '~> 1.8'
  s.add_runtime_dependency      'nokogumbo',          '~> 1.5'
  s.add_runtime_dependency      'yard' ,              '~> 0.9.12'

  # development dependencies
  s.add_development_dependency  'foreman'
  s.add_development_dependency  'rspec',              '~> 3.7'
  s.add_development_dependency  'rspec-its',          '~> 1.2'
  s.add_development_dependency  'rack-test',          '~> 0.8'
  s.add_development_dependency  'jsonpath',           '~> 0.8'
  s.add_development_dependency  'webmock',            '~> 3.1'

  s.post_install_message        = nil
end
