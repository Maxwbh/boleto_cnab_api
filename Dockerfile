# Build stage
FROM ruby:3.3-alpine AS builder

WORKDIR /usr/src/app

# Dependências de build (compilação de gems nativas)
RUN apk add --no-cache \
    build-base \
    git

# Copiar apenas Gemfile para cache de gems
COPY Gemfile Gemfile.lock ./

# Instalar gems de produção
RUN bundle config set --local without 'development test' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs 4 && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.o" -delete 2>/dev/null || true

# Runtime stage
FROM ruby:3.3-alpine

# Labels
LABEL org.opencontainers.image.title="Boleto CNAB API"
LABEL org.opencontainers.image.description="API REST para Boletos, CNAB e OFX"
LABEL org.opencontainers.image.version="1.3.0"
LABEL org.opencontainers.image.authors="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.source="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.vendor="M&S do Brasil LTDA"
LABEL org.opencontainers.image.licenses="MIT"

# Runtime: apenas ghostscript para geração de PDF
RUN apk add --no-cache \
    ghostscript \
    ghostscript-fonts \
    && rm -rf /var/cache/apk/*

# Usuário não-root
RUN addgroup -S app && adduser -S -G app app

WORKDIR /usr/src/app

# Copiar gems do builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copiar aplicação
COPY --chown=app:app . .

# Diretórios necessários
RUN mkdir -p tmp log && chown -R app:app tmp log

# Ambiente
ENV RACK_ENV=production \
    PORT=9292 \
    MALLOC_ARENA_MAX=2 \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH"

EXPOSE 9292

USER app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:9292/api/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "config.ru"]
