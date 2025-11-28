"""
Boleto CNAB API Client
~~~~~~~~~~~~~~~~~~~~~~~

Cliente Python oficial para a API de geração de Boletos Bancários Brasileiros.

Uso básico:

   >>> from boleto_cnab_client import BoletoClient
   >>> client = BoletoClient('https://api.exemplo.com')
   >>> boleto = client.generate_boleto('banco_brasil', {...})

:copyright: (c) 2025 Maxwell da Silva Oliveira - M&S do Brasil Ltda
:license: MIT, see LICENSE for more details.
"""

__title__ = 'boleto-cnab-client'
__version__ = '1.0.0'
__author__ = 'Maxwell da Silva Oliveira'
__author_email__ = 'maxwbh@gmail.com'
__license__ = 'MIT'
__copyright__ = 'Copyright 2025 Maxwell da Silva Oliveira'

from .client import BoletoClient
from .exceptions import (
    BoletoAPIError,
    BoletoValidationError,
    BoletoConnectionError,
    BoletoTimeoutError
)
from .models import BoletoData, BoletoResponse

__all__ = [
    'BoletoClient',
    'BoletoAPIError',
    'BoletoValidationError',
    'BoletoConnectionError',
    'BoletoTimeoutError',
    'BoletoData',
    'BoletoResponse'
]
