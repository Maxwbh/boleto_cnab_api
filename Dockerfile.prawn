# Build stage
FROM ruby:3.3-alpine AS builder

WORKDIR /usr/src/app

RUN apk add --no-cache build-base git

COPY Gemfile Gemfile.lock ./

RUN bundle config set --local without 'development test' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install --jobs 4 && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.o" -delete 2>/dev/null || true

# Runtime stage — SEM GhostScript (usa Prawn)
FROM ruby:3.3-alpine

LABEL org.opencontainers.image.title="Boleto CNAB API (Prawn)"
LABEL org.opencontainers.image.description="API REST para Boletos, CNAB e OFX — sem GhostScript"
LABEL org.opencontainers.image.version="1.3.0"
LABEL org.opencontainers.image.authors="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.source="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.vendor="M&S do Brasil LTDA"
LABEL org.opencontainers.image.licenses="MIT"

# Sem ghostscript — Prawn gera PDF nativamente em Ruby
RUN rm -rf /var/cache/apk/*

RUN addgroup -S app && adduser -S -G app app

WORKDIR /usr/src/app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=app:app . .

RUN mkdir -p tmp log && chown -R app:app tmp log

ENV RACK_ENV=production \
    PORT=9292 \
    MALLOC_ARENA_MAX=2 \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH" \
    BOLETO_TEMPLATE=prawn

EXPOSE 9292

USER app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:9292/api/health || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "config.ru"]
