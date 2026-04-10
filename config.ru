# frozen_string_literal: true

# Força flush imediato de stdout/stderr (crítico para containers)
$stdout.sync = true
$stderr.sync = true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '/lib')
require 'boleto_api'

run BoletoApi::Server
