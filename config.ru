# frozen_string_literal: true

$stdout.sync = true
$stderr.sync = true

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '/lib')
require 'boleto_api'

# Compressão gzip automática para responses JSON (~70% menor)
use Rack::Deflater

run BoletoApi::Server
