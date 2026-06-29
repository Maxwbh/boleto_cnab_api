source 'https://rubygems.org'

# Gem principal de boletos/CNAB (fork @maxwbh com C6 Bank + PIX + Bancos API)
gem 'brcobranca', git: 'https://github.com/maxwbh/brcobranca.git'

# Framework API REST
gem 'grape'

# Servidor HTTP
gem 'puma'

# Geração de PDF via RGhost (requerido pela brcobranca, usa GhostScript)
gem 'rghost', '~> 0.9.8'

# Geração de PDF via Prawn (alternativa sem GhostScript, Ruby puro)
gem 'prawn'
gem 'prawn-table'
gem 'barby'
gem 'rqrcode'
gem 'chunky_png'

# Parsing de extratos bancários OFX
gem 'ofx'

# Gems extraídas da stdlib do Ruby 3.1+/3.4+
gem 'base64'
gem 'mutex_m'
gem 'bigdecimal'
gem 'matrix'

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'simplecov', require: false
end
