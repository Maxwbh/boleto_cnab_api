#!/bin/bash
# Script para iniciar a API localmente

set -e

echo "🚀 Iniciando Boleto CNAB API..."
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando!"
    echo "Por favor, inicie o Docker Desktop e tente novamente."
    exit 1
fi

# Escolher método de execução
echo "Escolha o método de execução:"
echo "1) Docker Compose (recomendado)"
echo "2) Docker direto"
echo "3) Local (sem Docker)"
echo ""
read -p "Opção [1-3]: " choice

case $choice in
    1)
        echo "📦 Usando Docker Compose..."
        docker-compose up --build
        ;;
    2)
        echo "🐳 Usando Docker direto..."
        docker build -t boleto_cnab_api .
        echo ""
        echo "✅ Build concluído!"
        echo "🌐 Iniciando servidor na porta 9292..."
        docker run -p 9292:9292 boleto_cnab_api
        ;;
    3)
        echo "💻 Executando localmente..."

        # Verificar se bundle está instalado
        if ! command -v bundle &> /dev/null; then
            echo "❌ Bundler não encontrado!"
            echo "Instale com: gem install bundler"
            exit 1
        fi

        # Instalar dependências
        echo "📦 Instalando dependências..."
        bundle install

        echo ""
        echo "✅ Dependências instaladas!"
        echo "🌐 Iniciando servidor na porta 9292..."
        bundle exec rackup -p 9292
        ;;
    *)
        echo "❌ Opção inválida!"
        exit 1
        ;;
esac
