"""
Setup para o cliente Python da API Boleto CNAB
"""
import os
import re
from setuptools import setup, find_packages

# Ler versão do arquivo __init__.py
def get_version():
    init_py = os.path.join(
        os.path.dirname(__file__),
        'boleto_cnab_client',
        '__init__.py'
    )
    with open(init_py, 'r') as f:
        content = f.read()
        version_match = re.search(r"__version__ = ['\"]([^'\"]+)['\"]", content)
        if version_match:
            return version_match.group(1)
        raise RuntimeError("Unable to find version string.")

# Ler README
def get_long_description():
    readme_path = os.path.join(os.path.dirname(__file__), 'README.md')
    if os.path.exists(readme_path):
        with open(readme_path, 'r', encoding='utf-8') as f:
            return f.read()
    return ''

setup(
    name='boleto-cnab-client',
    version=get_version(),
    description='Cliente Python oficial para a API de geração de Boletos Bancários Brasileiros',
    long_description=get_long_description(),
    long_description_content_type='text/markdown',
    author='Maxwell da Silva Oliveira',
    author_email='maxwbh@gmail.com',
    url='https://github.com/Maxwbh/boleto_cnab_api',
    project_urls={
        'Documentation': 'https://github.com/Maxwbh/boleto_cnab_api/tree/main/docs',
        'Source': 'https://github.com/Maxwbh/boleto_cnab_api',
        'Tracker': 'https://github.com/Maxwbh/boleto_cnab_api/issues',
    },
    packages=find_packages(),
    python_requires='>=3.7',
    install_requires=[
        'requests>=2.25.0',
    ],
    extras_require={
        'dev': [
            'pytest>=6.0.0',
            'pytest-cov>=2.10.0',
            'black>=21.0',
            'flake8>=3.8.0',
            'mypy>=0.900',
        ],
    },
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Office/Business :: Financial',
    ],
    keywords='boleto cnab brazil banking api client',
    license='MIT',
    include_package_data=True,
    zip_safe=False,
)
