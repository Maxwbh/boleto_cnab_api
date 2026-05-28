source 'https://rubygems.org'

# Gem principal de boletos/CNAB (fork @maxwbh com C6 Bank + PIX + Bancos API)
gem 'brcobranca', git: 'https://github.com/maxwbh/brcobranca.git'

# Framework API REST
gem 'grape'

# Servidor HTTP
gem 'puma'

# Geração de PDF (requerido pela brcobranca)
gem 'rghost', '~> 0.9.8'

# Parsing de extratos bancários OFX
gem 'ofx'

# Gems extraídas da stdlib do Ruby 3.4+
# (necessárias para compatibilidade futura)
gem 'base64'
gem 'mutex_m'
gem 'bigdecimal'

group :test do
  gem 'rspec'
  gem 'rack-test'
end
