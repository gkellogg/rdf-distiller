#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.version            = File.read('VERSION').chomp
  s.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  s.name               = 'rdf-distiller'
  s.homepage           = 'https://github.com/gkellogg/rdf-distiller/'
  s.license            = 'Public Domain' if s.respond_to?(:license=)
  s.summary            = 'Translate any RDF format to any other using Ruby RDF gems'
  s.description        = s.summary

  s.authors            = ['Gregg Kellogg']
  s.email              = 'public-rdf-ruby@w3.org'

  s.platform           = Gem::Platform::RUBY
  s.files              = %w(AUTHORS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  s.require_paths      = %w(lib)

  s.required_ruby_version      = '>= 2.6'
  s.requirements               = []

  # RDF dependencies
  s.add_runtime_dependency      "sinatra-linkeddata", '~> 3.2'
  s.add_runtime_dependency      'equivalent-xml',     '~> 0.6'

  # Sinatra dependencies
  s.add_runtime_dependency      'sinatra',            '~> 2.2'
  s.add_runtime_dependency      'sass',               '~> 3.7'
  s.add_runtime_dependency      'sprockets',          '~> 4.0'
  s.add_runtime_dependency      'sprockets-helpers',  '~> 1.4'
  s.add_runtime_dependency      'uglifier',           '~> 4.2'

  s.add_runtime_dependency      'erubis',             '~> 2.7'
  s.add_runtime_dependency      'haml',               '~> 5.2'
  s.add_runtime_dependency      'maruku',             '~> 0.7'
  s.add_runtime_dependency      'json-compare',       '~> 0.1'
  s.add_runtime_dependency      'json-ld-preloaded',  '~> 3.2'
  s.add_runtime_dependency      "rack",               '~> 2.2'
  s.add_runtime_dependency      'rest-client',        '~> 2.1'
  s.add_runtime_dependency      'rest-client-components', '~> 1.5'
  s.add_runtime_dependency      'rack-cache',         '~> 1.13'
  s.add_runtime_dependency      'redcarpet',          '~> 3.5'
  s.add_runtime_dependency      'puma',               '~> 5.5'
  s.add_runtime_dependency      'nokogiri',           '~> 1.13', '>= 1.13.6'
  s.add_runtime_dependency      'yard' ,              '~> 0.9', ">= 0.9.27"

  # development dependencies
  s.add_development_dependency  'foreman'
  s.add_development_dependency  'rspec',              '~> 3.10'
  s.add_development_dependency  'rspec-its',          '~> 1.3'
  s.add_development_dependency  'rack-test',          '~> 1.1'
  s.add_development_dependency  'jsonpath',           '~> 1.1'
  s.add_development_dependency  'webmock',            '~> 3.14'

  s.post_install_message        = nil
end
