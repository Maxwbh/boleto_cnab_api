# frozen_string_literal: true

# Configuração do Puma otimizada para Render.com Free Tier
# Limite de memória: 512MB

# CRÍTICO: força flush imediato de stdout/stderr
# Sem isso, Render/Docker bufferizam logs e eles não aparecem em tempo real
$stdout.sync = true
$stderr.sync = true

# Porta
port ENV.fetch('PORT', 9292)

# Ambiente
environment ENV.fetch('RACK_ENV', 'production')

# Workers (processos)
# Free tier: 1 worker para economizar memória
workers ENV.fetch('PUMA_WORKERS', 1).to_i

# Threads por worker
# Range de threads para melhor performance com baixa memória
min_threads = ENV.fetch('PUMA_MIN_THREADS', 0).to_i
max_threads = ENV.fetch('PUMA_MAX_THREADS', 5).to_i
threads min_threads, max_threads

# Preload app para compartilhar memória entre workers
preload_app!

# PID e state files
pidfile 'tmp/puma.pid'
state_path 'tmp/puma.state'

# Logs de request do Puma (method, path, status, duration)
# Complementar ao RequestLogger da API
log_requests true

# Hook após boot: garante que stdout/stderr estão em sync no worker
on_worker_boot do
  $stdout.sync = true
  $stderr.sync = true
end

# Graceful shutdown
before_worker_boot do
  # Reconectar a qualquer banco de dados se necessário
end

# Lifecycle hooks
before_fork do
  # Cleanup antes de fork
end

# Error handler de baixo nível
if ENV['RACK_ENV'] == 'production'
  lowlevel_error_handler do |e, _env|
    [500, {}, ["Erro interno do servidor\n"]]
  end
end
