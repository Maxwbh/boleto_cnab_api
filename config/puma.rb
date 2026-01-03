# frozen_string_literal: true

# Configuração do Puma otimizada para Render.com Free Tier
# Limite de memória: 512MB

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

# Diretório de trabalho
directory '/usr/src/app'

# PID e state files
pidfile 'tmp/puma.pid'
state_path 'tmp/puma.state'

# Logs
stdout_redirect 'log/puma.stdout.log', 'log/puma.stderr.log', true if ENV['RACK_ENV'] == 'production'

# Graceful shutdown
on_worker_boot do
  # Reconectar a qualquer banco de dados se necessário
end

# Lifecycle hooks
before_fork do
  # Cleanup antes de fork
end

on_restart do
  # Cleanup durante restart
end

# Baixar prioridade do GC para melhor throughput
if ENV['RACK_ENV'] == 'production'
  lowlevel_error_handler do |e, env|
    [500, {}, ["Erro interno do servidor\n"]]
  end
end
