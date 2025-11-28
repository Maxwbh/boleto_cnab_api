"""
Cliente principal para a API Boleto CNAB
"""
import json
import logging
from typing import Dict, Any, Optional, List
from urllib.parse import urljoin

import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

from .exceptions import (
    BoletoAPIError,
    BoletoValidationError,
    BoletoConnectionError,
    BoletoTimeoutError
)
from .models import BoletoData, BoletoResponse

logger = logging.getLogger(__name__)


class BoletoClient:
    """
    Cliente Python para a API Boleto CNAB.

    Args:
        base_url: URL base da API (ex: 'https://boleto-api.onrender.com')
        timeout: Timeout em segundos (padrão: 30)
        retries: Número de tentativas em caso de falha (padrão: 3)
        verify_ssl: Verificar certificado SSL (padrão: True)

    Example:
        >>> client = BoletoClient('https://api.exemplo.com')
        >>> boleto_data = {
        ...     'agencia': '3073',
        ...     'conta_corrente': '12345678',
        ...     'nosso_numero': '123',
        ...     'valor': 1500.00,
        ...     # ... outros campos
        ... }
        >>> response = client.generate_boleto('banco_brasil', boleto_data)
        >>> print(response.codigo_barras)
    """

    def __init__(
        self,
        base_url: str,
        timeout: int = 30,
        retries: int = 3,
        verify_ssl: bool = True
    ):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.verify_ssl = verify_ssl

        # Configurar sessão com retry automático
        self.session = requests.Session()
        retry_strategy = Retry(
            total=retries,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "POST", "OPTIONS"],
            backoff_factor=1
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)

        logger.info(f"BoletoClient initialized: {self.base_url}")

    def _make_request(
        self,
        method: str,
        endpoint: str,
        **kwargs
    ) -> requests.Response:
        """
        Faz requisição HTTP com tratamento de erros.

        Args:
            method: Método HTTP (GET, POST, etc)
            endpoint: Endpoint da API
            **kwargs: Argumentos para requests

        Returns:
            Response object

        Raises:
            BoletoConnectionError: Erro de conexão
            BoletoTimeoutError: Timeout
            BoletoAPIError: Erro da API
        """
        url = urljoin(self.base_url, endpoint)
        kwargs.setdefault('timeout', self.timeout)
        kwargs.setdefault('verify', self.verify_ssl)

        try:
            logger.debug(f"{method} {url}")
            response = self.session.request(method, url, **kwargs)

            if response.status_code >= 400:
                try:
                    error_data = response.json()
                    error_msg = error_data.get('error', response.text)
                except:
                    error_msg = response.text

                if response.status_code == 400:
                    raise BoletoValidationError(error_msg, response.status_code)
                else:
                    raise BoletoAPIError(error_msg, response.status_code)

            return response

        except requests.Timeout as e:
            raise BoletoTimeoutError(f"Timeout após {self.timeout}s") from e
        except requests.ConnectionError as e:
            raise BoletoConnectionError(f"Erro de conexão: {str(e)}") from e

    def health_check(self) -> Dict[str, str]:
        """
        Verifica se a API está funcionando.

        Returns:
            Dict com status da API

        Example:
            >>> client.health_check()
            {'status': 'OK'}
        """
        response = self._make_request('GET', '/api/health')
        return response.json()

    def validate(
        self,
        bank: str,
        data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Valida dados do boleto sem gerar PDF.

        Args:
            bank: Código do banco (banco_brasil, sicoob, etc)
            data: Dados do boleto

        Returns:
            Dict com resultado da validação

        Example:
            >>> result = client.validate('banco_brasil', boleto_data)
            >>> print(result['valid'])
            True
        """
        response = self._make_request(
            'GET',
            '/api/boleto/validate',
            params={'bank': bank, 'data': json.dumps(data)}
        )
        return response.json()

    def get_boleto_data(
        self,
        bank: str,
        data: Dict[str, Any]
    ) -> BoletoResponse:
        """
        Obtém dados completos do boleto sem gerar PDF.

        Args:
            bank: Código do banco
            data: Dados do boleto

        Returns:
            BoletoResponse com todos os dados

        Example:
            >>> response = client.get_boleto_data('banco_brasil', boleto_data)
            >>> print(response.codigo_barras)
            >>> print(response.linha_digitavel)
        """
        response = self._make_request(
            'GET',
            '/api/boleto/data',
            params={'bank': bank, 'data': json.dumps(data)}
        )
        return BoletoResponse(**response.json())

    def get_nosso_numero(
        self,
        bank: str,
        data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Gera apenas o nosso número do boleto.

        Args:
            bank: Código do banco
            data: Dados do boleto

        Returns:
            Dict com nosso_numero e campos relacionados
        """
        response = self._make_request(
            'GET',
            '/api/boleto/nosso_numero',
            params={'bank': bank, 'data': json.dumps(data)}
        )
        return response.json()

    def generate_boleto(
        self,
        bank: str,
        data: Dict[str, Any],
        file_type: str = 'pdf'
    ) -> bytes:
        """
        Gera boleto em PDF ou imagem.

        Args:
            bank: Código do banco
            data: Dados do boleto
            file_type: Tipo de arquivo (pdf, jpg, png, tif)

        Returns:
            Bytes do arquivo gerado

        Example:
            >>> pdf_bytes = client.generate_boleto('banco_brasil', boleto_data)
            >>> with open('boleto.pdf', 'wb') as f:
            ...     f.write(pdf_bytes)
        """
        response = self._make_request(
            'GET',
            '/api/boleto',
            params={
                'bank': bank,
                'type': file_type,
                'data': json.dumps(data)
            }
        )
        return response.content

    def generate_multiple_boletos(
        self,
        boletos: List[Dict[str, Any]],
        file_type: str = 'pdf'
    ) -> bytes:
        """
        Gera múltiplos boletos em um único arquivo.

        Args:
            boletos: Lista de dicts com dados dos boletos (incluindo 'bank')
            file_type: Tipo de arquivo (pdf, jpg, png, tif)

        Returns:
            Bytes do arquivo gerado

        Example:
            >>> boletos = [
            ...     {'bank': 'banco_brasil', 'agencia': '3073', ...},
            ...     {'bank': 'sicoob', 'agencia': '4327', ...}
            ... ]
            >>> pdf_bytes = client.generate_multiple_boletos(boletos)
        """
        import tempfile

        # Criar arquivo temporário com JSON
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(boletos, f)
            temp_path = f.name

        try:
            with open(temp_path, 'rb') as f:
                response = self._make_request(
                    'POST',
                    '/api/boleto/multi',
                    data={'type': file_type},
                    files={'data': f}
                )
            return response.content
        finally:
            import os
            os.unlink(temp_path)

    def __repr__(self) -> str:
        return f"<BoletoClient(base_url='{self.base_url}')>"
