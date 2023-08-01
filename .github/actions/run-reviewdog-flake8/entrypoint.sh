#!/bin/bash

# a modified version of this file: https://github.com/reviewdog/action-flake8/blob/master/entrypoint.sh
set -eu # Increase bash strictness

# Check if GITHUB_WORKSPACE environment variable is set and change directory
if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

# Set REVIEWDOG_GITHUB_API_TOKEN environment variable for reviewdog
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

export REVIEWDOG_VERSION=v0.14.1

echo "[action-flake8] Installing reviewdog..."
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /tmp "${REVIEWDOG_VERSION}"

# Check if flake8 is installed and install it if necessary
if [[ "$(which flake8)" == "" ]]; then
  echo "[action-flake8] Installing flake8 package..."
  python -m pip install --upgrade flake8
fi
echo "[action-flake8] Flake8 version:"
flake8 --version

echo "[action-flake8] Checking python code with the flake8 linter and reviewdog..."
exit_val="0"
poetry run flake8 ${CHANGED_FILES} --config=.flake8 ${INPUT_FLAKE8_ARGS} 2>&1 |
  /tmp/reviewdog -f=flake8 \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS} || exit_val="$?"

echo "[action-flake8] Clean up reviewdog..."
rm /tmp/reviewdog

# Exit with error code if there were any issues found by flake8 and reviewdog
if [[ "${exit_val}" -ne '0' ]]; then
  exit 1
fi