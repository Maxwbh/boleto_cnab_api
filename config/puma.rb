# frozen_string_literal: true

# Configuração do Puma otimizada para Render.com Free Tier
# Limite de memória: 512MB

# CRÍTICO: força flush imediato de stdout/stderr
# Sem isso, Render/Docker bufferizam logs e eles não aparecem em tempo real
$stdout.sync = true
$stderr.sync = true

# Porta — no Render, a porta é injetada via ENV['PORT']
port ENV.fetch('PORT', 9292)

# Ambiente
environment ENV.fetch('RACK_ENV', 'production')

# Workers (processos)
# Free tier: 1 worker para economizar memória
worker_count = ENV.fetch('PUMA_WORKERS', 1).to_i
workers worker_count

# Threads por worker
# min_threads em 1 evita latência de criação na primeira requisição
min_threads = ENV.fetch('PUMA_MIN_THREADS', 1).to_i
max_threads = ENV.fetch('PUMA_MAX_THREADS', 5).to_i
threads min_threads, max_threads

# Timeout do worker — evita que o master mate o worker durante o cold start
# (free tier pode demorar a "acordar" do sleep)
worker_timeout ENV.fetch('PUMA_WORKER_TIMEOUT', 60).to_i

# Modo cluster (workers >= 1): preload compartilha memória entre workers via
# copy-on-write e permite recarregar gems sem reiniciar o master.
# Em single mode (workers = 0) o preload é desnecessário e desperdiça memória.
preload_app! if worker_count.positive?

# PID e state files
pidfile ENV.fetch('PUMA_PIDFILE', 'tmp/puma.pid')
state_path ENV.fetch('PUMA_STATE', 'tmp/puma.state')

# Logs de request do Puma (method, path, status, duration)
log_requests true

# Hook após boot do worker: garante stdout/stderr em sync
on_worker_boot do
  $stdout.sync = true
  $stderr.sync = true
end

# Error handler de baixo nível (não vaza stacktrace em produção)
if ENV.fetch('RACK_ENV', 'production') == 'production'
  lowlevel_error_handler do |_e, _env|
    [500, { 'Content-Type' => 'text/plain' }, ["Erro interno do servidor\n"]]
  end
end
