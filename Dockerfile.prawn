# syntax=docker/dockerfile:1

# ============================================================
# Build stage — compila gems nativas
# ============================================================
FROM ruby:3.3-alpine AS builder

WORKDIR /usr/src/app

RUN apk add --no-cache build-base git

COPY Gemfile Gemfile.lock ./

RUN bundle config set --local without 'development test' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle config set --local deployment 'true' && \
    bundle install --jobs 4 --retry 3 && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete 2>/dev/null || true && \
    find /usr/local/bundle/gems/ -name "*.o" -delete 2>/dev/null || true

# ============================================================
# Runtime stage — SEM GhostScript (PDF via Prawn, Ruby puro)
# ============================================================
FROM ruby:3.3-alpine

LABEL org.opencontainers.image.title="Boleto CNAB API (Prawn)"
LABEL org.opencontainers.image.description="API REST para Boletos, CNAB e OFX — sem GhostScript"
LABEL org.opencontainers.image.version="1.4.0"
LABEL org.opencontainers.image.authors="Maxwell Oliveira <maxwbh@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.source="https://github.com/Maxwbh/boleto_cnab_api"
LABEL org.opencontainers.image.vendor="M&S do Brasil LTDA"
LABEL org.opencontainers.image.licenses="MIT"

# jemalloc + tini (sem ghostscript). jemalloc reduz o uso de memória do
# Ruby em Alpine/musl — essencial no free tier de 512MB.
RUN apk add --no-cache \
    jemalloc \
    tini \
    && rm -rf /var/cache/apk/*

RUN addgroup -S app && adduser -S -G app app

WORKDIR /usr/src/app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --chown=app:app . .

RUN mkdir -p tmp log && chown -R app:app tmp log

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
    PATH="/usr/local/bundle/bin:$PATH" \
    BOLETO_TEMPLATE=prawn

EXPOSE 9292

USER app

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider "http://localhost:${PORT}/api/health" || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "config.ru"]
