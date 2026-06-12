# syntax=docker/dockerfile:1

# ============================================================
# Build stage — compila gems nativas
# ============================================================
FROM ruby:3.3-alpine AS builder

WORKDIR /usr/src/app

# Dependências de build (compilação de gems nativas)
RUN apk add --no-cache \
    build-base \
    git

# Copiar apenas Gemfile para cache de layers de gems
COPY Gemfile Gemfile.lock ./

# Instalar gems de produção e remover artefatos de build
RUN bundle config set --local without 'development test' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle config set --local deployment 'true' && \
    bundle install --jobs 4 --retry 3 && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.o" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.so.gch" -delete 2>/dev/null || true

# ============================================================
# Runtime stage
# ============================================================
FROM ruby:3.3-alpine

# Labels (OCI)
LABEL org.opencontainers.image.title="Boleto CNAB API"
LABEL org.opencontainers.image.description="API REST para Boletos, CNAB e OFX"
LABEL org.opencontainers.image.version="1.3.0"
LABEL org.opencontainers.image.authors="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.source="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.vendor="M&S do Brasil LTDA"
LABEL org.opencontainers.image.licenses="MIT"

# Runtime:
#  - ghostscript      -> geração de PDF (brcobranca/RGhost)
#  - jemalloc         -> allocator com baixa fragmentação (musl/Alpine).
#                        Reduz drasticamente o uso de memória do Ruby no
#                        free tier de 512MB. (MALLOC_ARENA_MAX é glibc-only
#                        e NÃO tem efeito em Alpine/musl.)
#  - tini             -> init mínimo (PID 1) para reaping e sinais corretos
RUN apk add --no-cache \
    ghostscript \
    ghostscript-fonts \
    jemalloc \
    tini \
    && rm -rf /var/cache/apk/*

# Usuário não-root
RUN addgroup -S app && adduser -S -G app app

WORKDIR /usr/src/app

# Copiar gems já compiladas/limpas do builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copiar aplicação (respeitando .dockerignore)
COPY --chown=app:app . .

# Diretórios de runtime
RUN mkdir -p tmp log && chown -R app:app tmp log

# Ambiente otimizado para Render Free Tier (512MB RAM)
ENV RACK_ENV=production \
    PORT=9292 \
    LD_PRELOAD=/usr/lib/libjemalloc.so.2 \
    MALLOC_CONF="background_thread:true,narenas:2,dirty_decay_ms:1000,muzzy_decay_ms:0" \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    RUBY_GC_MALLOC_LIMIT=16777216 \
    RUBY_GC_OLDMALLOC_LIMIT=16777216 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=true \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH"

EXPOSE 9292

USER app

# Healthcheck (usado por docker/compose; o Render usa healthCheckPath)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider "http://localhost:${PORT}/api/health" || exit 1

# tini como PID 1 -> propaga SIGTERM ao Puma (shutdown gracioso no deploy)
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "config.ru"]
