#!/bin/bash

set -e

function pypi-tokens {
    load-dotenv
    echo "TEST_PYPI_TOKEN=$TEST_PYPI_TOKEN"
    echo "PROD_PYPI_TOKEN=$PROD_PYPI_TOKEN"
}

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "no .env file found"
        return 1
    fi

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

function lint:ci {
    SKIP=no-commit-to-branch pre-commit run --all-files
}

function test:quick {
    PYTEST_EXIT_STATUS=0
    python -m pytest -m 'not slow' "$THIS_DIR/tests/" \
        --cov "$THIS_DIR/packaging2" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junit-xml "$THIS_DIR/test-reports/report.xml" \
        --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS
}

function test {
    # run only specified tests, if non specified, run all
    PYTEST_EXIT_STATUS=0
    python -m pytest "${@:-$THIS_DIR/tests/}" \
        --cov "$THIS_DIR/packaging2" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junit-xml "$THIS_DIR/test-reports/report.xml" \
        --cov-fail-under 60 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS

}

function test:wheel-locally {
    deactivate || true
    rm -rf test-env || true
    python -m venv test-env
    source test-env/bin/activate
    clean
    pip install build
    build

    PYTEST_EXIT_STATUS=0
    pip install ./dist/*.whl pytest pytest-cov
    INSTALLED_PKG_DIR="$(python -c 'import packaging2; print(packaging2.__path__[0])')"
    python -m pytest "${@:-$THIS_DIR/tests/}" \
        --cov "$INSTALLED_PKG_DIR" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junit-xml "$THIS_DIR/test-reports/report.xml" \
        --cov-fail-under 60 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"

    deactivate
    return $PYTEST_EXIT_STATUS

}

function test:ci {

    PYTEST_EXIT_STATUS=0
    pip install ./dist/*.whl pytest pytest-cov
    INSTALLED_PKG_DIR="$(python -c 'import packaging2; print(packaging2.__path__[0])')"
    python -m pytest "${@:-$THIS_DIR/tests/}" \
        --cov "$INSTALLED_PKG_DIR" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junit-xml "$THIS_DIR/test-reports/report.xml" \
        --cov-fail-under 60 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"

    deactivate
    return $PYTEST_EXIT_STATUS

}

function serve-coverage-report {
    python -m http.server --directory "$THIS_DIR/htmlcov/"
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
    try-load-dotenv || true
    twine upload dist/* \
        --repository testpypi \
        --username=__token__ \
        --password="$TEST_PYPI_TOKEN"
}

function publish:prod {
    try-load-dotenv || true
    twine upload dist/* \
        --repository pypi \
        --username=__token__ \
        --password="$PROD_PYPI_TOKEN"
        --verbose
}

function clean {
    rm -rf dist build coverage.xml test-reports
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env*/*" \
      -exec rm -r {} +
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
