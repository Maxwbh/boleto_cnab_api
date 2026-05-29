# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

# Cobertura de testes (SimpleCov) — deve ser o PRIMEIRO require
if ENV.fetch('COVERAGE', 'false').downcase == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_group 'Services', 'lib/boleto_api/services'
    add_group 'Endpoints', 'lib/boleto_api/endpoints'
    add_group 'Middleware', 'lib/boleto_api/middleware'
    add_group 'Config', 'lib/boleto_api/config'
    minimum_coverage 70
  end
end

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'rack/test'
require 'rspec'
require 'json'
require_relative '../lib/boleto_api'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/.rspec_status'
  config.disable_monkey_patching!
  config.warnings = false

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end

def app
  BoletoApi::Server
end
