# -*- encoding: utf-8 -*-
require 'sinatra/sparql'
require 'sinatra/asset_pipeline'
require 'rack/protection'
require 'sprockets-helpers'
require 'uglifier'
require 'sassc'
require 'logger'
require 'erubis'
require 'linkeddata'
require 'rdf/ordered_repo'
require 'rdf/cli'
require 'json/ld/preloaded' # Preload certain contexts
require 'uri'
require 'haml'

module RDF::Distiller
  class Application < Sinatra::Base
    DOAP_NT = File.join(APP_DIR, 'etc/doap.nt')
    DOAP_JSON = File.join(APP_DIR, 'etc/doap.jsonld')

    configure do
      register Sinatra::SPARQL
      unless test?
        enable :sessions
        set :session_secret, ENV.fetch('SESSION_SECRET', "rdf-distiller")
        use Rack::Protection
      end
      set :root, APP_DIR
      set :public_folder, PUB_DIR
      set :views, ::File.expand_path('../views',  __FILE__)
      set :app_name, "RDF Distiller"
      enable :logging
      disable :raise_errors, :show_exceptions if settings.production?

      # Cache client requests
      RestClient.enable Rack::Cache,
        verbose:     true,
        metastore:   "file:" + ::File.join(APP_DIR, "cache/meta"),
        entitystore: "file:" + ::File.join(APP_DIR, "cache/body")

      mime_type :jsonld, "application/ld+json"
      mime_type :normalize, "application/normalized+n-quads"
      mime_type :sparql, "application/sparql-query"
      mime_type :ttl, "text/turtle"
      mime_type :sse, "application/sse+sparql-query"

      # Asset pipeline
      set :digest_assets, false

      # Include these files when precompiling assets
      set :assets_precompile, %w(*.js *.css *.ttf *.gif)

      # The path to your assets
      set :assets_paths, %w(assets/js assets/css)

      # CSS minification
      set :assets_css_compressor, :sassc

      # JavaScript minification
      set :assets_js_compressor, :uglifier

      register Sinatra::AssetPipeline

      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
        config.prefix      = assets_prefix
        config.digest      = digest_assets
        config.public_path = public_folder

        # Force to debug mode in development mode
        # Debug mode automatically sets
        # expand = true, digest = false, manifest = false
        config.debug       = true if development?
      end
    end

    configure :development do
      set :logging, ::Logger.new($stdout)
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = APP_DIR
    end

    configure :test do
      set :logging, ::Logger.new(StringIO.new)
    end

    helpers do
      include Sprockets::Helpers

      # Set cache control
      def set_cache_header(options = {})
        options = {max_age: ENV.fetch('max_age', 60*5)}.merge(options)
        cache_control(:public, :must_revalidate, options)
      end

      def active_page?(path='')
        request.path_info.start_with?("/#{path}") ? 'active': nil
      end

      ##
      # Lookup extension class version
      #
      # @param [String] class_name
      # @return [String]
      def class_version(str)

        str = case str
        when "RDF.rb"       then "RDF"
        when "SXP for Ruby" then "SXP"
        when "ebnf"         then "EBNF"
        else str
        end

        "#{str.sub('.rb', '')}::VERSION".split('::').inject(Object) do |mod, class_name|
          mod.const_get(class_name)
        end.to_s
      rescue
        "???"
      end
    end

    before do
      request.logger.level = Logger::DEBUG unless settings.environment == :production
      request.logger.info "#{request.request_method} [#{request.path_info}], " +
        params.merge(Accept: request.accept.map(&:to_s)).map {|k,v| "#{k}=#{v}" unless k.to_s == "content"}.join(" ")
    end

    after do
      headers 'Access-Control-Allow-Origin' => '*'
      msg = "Status: #{response.status} (#{request.request_method} #{request.path_info}), Content-Type: #{response.content_type}"
      msg += ", Location: #{response.location}" if response.location
      request.logger.info msg
    end

    # Get "/" either returns the main linter page or linted markup
    #
    # @method get_root
    # @overload get "/", params
    # @see {#distil}
    get '/' do
      cache_control :public, :must_revalidate, max_age: 60
      result = erb :index, locals: {title: "Ruby Linked Data Service"}
      etag result.hash
      result
    end

    get '/about' do
      set_cache_header
      erb :about, locals: {title: "About the Ruby Linked Data Service"}
    end
    get '/about/' do
      redirect '/about'
    end

    get '/doap.?:format?' do
      set_cache_header
      case format
      when :nt, :ntriples
        f = File.read(DOAP_NT).force_encoding(Encoding::UTF_8)
        etag f
        headers "Content-Type" => "application/n-triples; charset=utf-8"
        body f
      when :jsonld
        f = File.read(DOAP_JSON).force_encoding(Encoding::UTF_8)
        etag Digest::SHA1.hexdigest f
        headers "Content-Type" => "application/ld+json; charset=utf-8"
        body f
      when :html, :xhtml
        f = File.read(DOAP_JSON).force_encoding(Encoding::UTF_8)
        etag Digest::SHA1.hexdigest f
        projects = ::JSON.parse(f)['@graph']
        
        # Fix dc:created and doap:helper entries to be normalized
        projects.each do |p|
          devs = p['doap:developer'].inject({}) {|memo, h| memo[h['@id']] = h if h.is_a?(Hash); memo}
          p['dc:creator'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
          p['doap:helper'].map! {|u| u.is_a?(String) && devs.has_key?(u) ? devs[u] : u}
        end
        erb :doap, locals: {
          title:    "Project Information on included Gems",
          projects: projects
        }
      else
        etag Digest::SHA1.hexdigest File.read(DOAP_NT)
        settings.sparql_options.merge!(format: format, content_type: content_type)
        doap
      end
    end

    # Get "/distiller" either returns the main distiller page or distilled markup.
    #
    # When JSON is requested, returns data intended for the single-page application.
    #
    # @method get_distil
    # @overload get "/distiller", params
    # @see {#distil}
    get '/distiller' do
      set_cache_header
      if request.accept?('text/html') && !params.has_key?('raw')
        raw_opt = {
          symbol: :raw,
          control: :checkbox,
          description: "Return raw results directly through the browser (use link at bottom of the page)."
        }
        # Return application
        erb :distiller, locals: {
          head: :distiller,
          root: url("/"),
          title: "Ruby Distiller",
          command_data: RDF::CLI.commands(format: :json).to_json,
          option_data:  RDF::CLI.options([], format: :json).unshift(raw_opt).to_json,
          input_format_option_data: RDF::Reader.each.inject({}) {|memo, r| memo.merge(r.to_sym => r.options.map(&:to_hash))}.to_json,
          output_format_option_data: RDF::Writer.each.inject({}) {|memo, w| memo.merge(w.to_sym => w.options.map(&:to_hash))}.to_json
        }
      elsif request.accept?('application/json') && request.xhr? && !params.has_key?('raw')
        # Return distilled input
        content_type :json
        distil(params).to_json
      else
        # Return raw content
        hash = distil(params)
        if hash[:format]
          format hash[:format]
          hash[:serialized]
        else
          content_type :txt
          hash[:messages][:error].join("\n")
        end
      end
    end

    # POST "/distiller" returns distilled markup as JSON
    #
    # @method post_distil
    # @overload post "/distiller", params
    # @see {#distil}
    post '/distiller' do
      payload = Sinatra::IndifferentHash.new.merge(::JSON.parse(request.body.read))
      content_type :json
      distil(payload).to_json
    end

    # GET "/distiller/load" retrieves and returns a remote document
    get '/distiller/load' do
      begin
        set_cache_header
        content_type :text
        remote_doc = RDF::Util::File.open_file(params[:url])
        remote_doc.read
      rescue
        "Failed to load file '#{params[:url]}': #{$!.message}"
      end
    end

    private

    # Handle GET/POST /distiller returning either a raw RDF format, or JSON
    # @param {Hash} params
    # @option params [String] :base_uri
    #   Base URI for decoding markup, defaluts to `:url` if present
    # @option params [String] :content
    #   Markup specified inline
    # @option params [String] :datafile
    #   Location of uploaded file containing markup
    # @option params [Boolean] :debug
    #   Return verbose debug output
    # @option params [String] :format
    #   Format to use when parsing file
    # @option params [String] :url
    #   Location of resource containing markup
    # @option params [Boolean] :validate
    #   Perform strict validation of markup
    def distil(params)
      messages, json_result, statistics = {}, {}, {}
      log_dev = StringIO.new
      logger = Logger.new(log_dev)
      logger.level = Logger::WARN
      logger.formatter = lambda {|severity, datetime, progname, msg| "#{severity}: #{msg}\n"}

      # Main argument is specified command
      args = [params.delete('command') || 'serialize']
      url = params.delete('url')
      params['base_uri'] ||= url

      unless params['base_uri'].nil? || RDF::URI(params['base_uri']).absolute?
        raise ArgumentError, "Base URI must be an absolute IRI"
      end

      params['evaluate'] ||= params.delete('input')

      # Prepend any options which are commands
      command_names = RDF::CLI.commands(format: :json).map {|c| c[:symbol].to_s}
      modifiers = params.keys.map(&:to_s) & command_names
      args = modifiers + args

      # Transform other properties ending with Input to the base version, wrapping in a StringIO.
      params.keys.select {|k| k.end_with?('Input')}.each do |input_key|
        key = input_key[0..-6]
        params[key] = StringIO.new(params.delete(input_key))
      end

      output = StringIO.new
      args << url if url && !params[:evaluate]
      cli_opts = params.
        inject({}) {|memo, (k,v)| memo.merge(k.to_sym => v)}.
        merge(logger: logger, output: output, statistics: statistics, messages: messages)
      RDF::CLI.exec(args, **cli_opts)
      output.rewind
      output.set_encoding(Encoding::UTF_8)
      result = output.read
      content_type :json
      json_result = {
        serialized: result,
        format: params.fetch(:output_format, :ntriples)
      }.merge(statistics: statistics, messages: messages)
    rescue RDF::ReaderError, ArgumentError => e
      request.logger.error "#{e.class}: #{e.message}"
      request.logger.debug e.backtrace.join("\n")
      content_type :json
      status 400
      messages[:error] = {"#{e.class}" => [e.message]}
      {format: :txt, messages: messages}
    rescue IOError => e
      request.logger.error "Failed to open #{params['base_uri']}: #{e.message}"
      request.logger.debug e.backtrace.join("\n")
      content_type :json
      status 502
      messages[:error] = {"IOError" => ["Failed to open #{params['base_uri']}: #{e.message}"]}
      {format: :txt, messages: messages}
    rescue
      request.logger.error "#{$!.class}: #{$!.message}"
      content_type :json
      status 400
      messages[:error] = {"#{$!.class}" => [$!.message]}
      {format: :txt, messages: messages}
    ensure
      # Extract messages from logger
      log_dev.rewind
      last_level = nil
      log_dev.each_line do |line|
        level, message = line.split(':', 2)
        unless %w(FATAL ERROR WARN INFO DEBUG).include?(level)
          message = [("  " + level), message].compact.join(":")
          level = last_level
        end
        last_level = level
        messages[level.to_sym] ||= {}
        (messages[level.to_sym][:reader] ||= []) << message
      end
    end

    # Format symbols for RDF formats
    # @param [Symbol] reader_or_writer
    # @return [Array<Symbol>] List of format symbols
    def formats(reader_or_writer = :reader)
      # Symbols for different input formats
      RDF::Format.each.to_a.map {|f| f.send(reader_or_writer)}.uniq.compact.map(&:to_sym)
    end

    # Negotiated format
    # @param [#to_sym] format (nil) allows a format to be specified
    # @return [Symbol]
    def format(format = nil)
      params[:format] = format.to_sym if format
      case
      when params[:format]
        content_type params[:format]
        params[:format].to_sym
      when %w(application/xhtml+xml text/html */*).include?(Array(env['ORDERED_CONTENT_TYPES']).first)
        content_type env['ORDERED_CONTENT_TYPES'].first
        :html
      when !Array(env['ORDERED_CONTENT_TYPES']).empty?
        content_type env['ORDERED_CONTENT_TYPES'].first
        case env['ORDERED_CONTENT_TYPES'].first
        when 'application/sparql-results+json' then :json
        when 'text/html'                       then :html
        when 'application/sparql-results+xml'  then :xml
        when 'text/csv'                        then :csv
        when 'text/tab-separated-values'       then :tsv
        when 'application/rdf+json'            then :json
        else
          RDF::Format.for(content_type: env['ORDERED_CONTENT_TYPES'].first).to_sym
        end
      else
        content_type :html
        :html
      end
    end

    ## Default graph, loaded from DOAP file
    def doap
      @doap ||= begin
        request.logger.debug "load #{DOAP_NT}"
        RDF::OrderedRepo.load(DOAP_NT)
      end
    end

    private
    def format_version(format)
      if %w(RDF::NTriples::Format RDF::NQuads::Format RDF::Vocabulary::Format).include?(format.to_s)
        return RDF::VERSION
      else
        format.to_s.split('::')[0..-2].inject(Kernel) {|mod, name| mod.const_get(name)}.const_get('VERSION')
      end
    end
  end
end