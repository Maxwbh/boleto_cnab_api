# Build stage
FROM alpine:3.19 AS builder

WORKDIR /usr/src/app

# Instalar dependências de build
RUN apk add --no-cache \
    build-base \
    ruby-dev \
    git

# Copiar apenas arquivos necessários para bundle
COPY Gemfile Gemfile.lock* ./

# Instalar gems no path padrão do sistema
RUN gem install bundler:2.5.11 --no-document && \
    bundle config set --local without 'development test' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs 4 && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.o" -delete 2>/dev/null || true

# Runtime stage
FROM alpine:3.19

# Labels do mantenedor
LABEL org.opencontainers.image.title="Boleto CNAB API"
LABEL org.opencontainers.image.description="API REST para geração de Boletos, Remessas e Retornos Bancários"
LABEL org.opencontainers.image.version="1.1.0"
LABEL org.opencontainers.image.authors="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.source="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.vendor="M&S do Brasil LTDA"
LABEL org.opencontainers.image.licenses="MIT"

# Instalar runtime dependencies apenas
RUN apk add --no-cache \
    ruby \
    ghostscript \
    ghostscript-fonts \
    && gem install bundler:2.5.11 --no-document \
    && rm -rf /var/cache/apk/*

# Criar usuário não-root
RUN addgroup -S app && adduser -S -G app app

WORKDIR /usr/src/app

# Copiar gems do builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copiar aplicação
COPY --chown=app:app . .

# Criar diretórios necessários
RUN mkdir -p tmp log && chown -R app:app tmp log

# Configurar ambiente
ENV RACK_ENV=production \
    PORT=9292 \
    MALLOC_ARENA_MAX=2 \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    BUNDLE_PATH=/usr/local/bundle \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH"

# Expor porta
EXPOSE 9292

# Usar usuário não-root
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:9292/api/health || exit 1

# Comando de inicialização
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "config.ru"]
