#!/bin/bash 

set -e

function pypi-tokens {
    load-dotenv
    echo "TEST_PYPI_TOKEN=$TEST_PYPI_TOKEN"
    echo "PROD_PYPI_TOKEN=$PROD_PYPI_TOKEN"
}

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

function load-dotenv {
    echo "$THIS_DIR"
    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}

function install {
    python -m pip install --upgrade pip
    # assumes there is a virtual environment
    python -m pip install --editable "$THIS_DIR/[dev]"
}

function lint {
    pre-commit run --all-file
}

function build {
    python -m build --sdist --wheel "$THIS_DIR/"
}

function release:test {
    clean
    build
    publish:test
}

function release:prod {
    release:test
    publish:prod
}

function publish:test {
    load-dotenv
    twine upload dist/* \
        --repository testpypi \
        --username=__token__ \
        --password="$TEST_PYPI_TOKEN"
}

function publish:prod {
    load-dotenv
    twine upload dist/* \
        --repository pypi \
        --username=__token__ \
        --password="$PROD_PYPI_TOKEN"
        --verbose
}

function clean {
    rm -rf dist build
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
      \) \
      -not -path "./venv2/*" \
      -exec rm -r {} +
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
