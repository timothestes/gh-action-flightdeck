#!/bin/bash

# A modified version of this file: https://github.com/tsuyoshicho/action-mypy/blob/master/script.sh

# Change directory to the specified working directory
cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit

echo '::group:: Setting up environment'

# activate python env
poetry env use ${INPUT_PYTHON_VERSION}
python --version

echo '::endgroup::'

# Create a temporary directory and add it to the PATH
TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# Check the setup method
SETUP="false"
case "${INPUT_SETUP_METHOD}" in
  "nothing")
    SETUP="false"
    ;;
  "install")
    SETUP="true"
    ;;
  *)
    # adaptive and other invalid value
    # Check if the execute_command is valid.
    echo '::group:: Check command is executable'
    echo "Execute command with version option: ${INPUT_EXECUTE_COMMAND} --version"
    if ${INPUT_EXECUTE_COMMAND} --version > /dev/null 2>&1 ; then
      echo 'Success command execution, skip installation.'
      SETUP="false"
    else
      echo 'Failure command execution, execute installation.'
      SETUP="true"
    fi
    echo '::endgroup::'
    ;;
esac

# Install mypy if needed.
if [[ "${SETUP}" == "true" ]] ; then
  echo '::group:: Running setup command'
  echo "Execute setup: ${INPUT_SETUP_COMMAND}"
  ${INPUT_SETUP_COMMAND}
  echo '::endgroup::'
fi

echo '::group:: Running mypy with reviewdog 🐶 ...'
mypy_exit_val="0"
reviewdog_exit_val="0"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# get the output of the mypy command
mypy_check_output="$(${INPUT_EXECUTE_COMMAND} \
  --show-column-numbers \
  --show-absolute-path \
  ${INPUT_MYPY_FLAGS} \
  "${INPUT_TARGET:-.}" 2>&1 \
  )" || mypy_exit_val="$?"

IGNORE_NOTE_EFM_OPTION=()
if [[ "${INPUT_IGNORE_NOTE}" == "true" ]] ; then
  # note ignore
  IGNORE_NOTE_EFM_OPTION=("-efm=%-G%f:%l:%c: note: %m")
fi

# Pass the mypy output to reviewdog for reporting
# The -efm option specifies the error format, which allows reviewdog to consume the mypy errors
echo -e "${mypy_check_output}" | reviewdog \
  "${IGNORE_NOTE_EFM_OPTION[@]}" \
  -efm="%f:%l:%c: %t%*[^:]: %m" \
  -efm="%f:%l: %t%*[^:]: %m" \
  -efm="%f: %t%*[^:]: %m" \
  -name="${INPUT_TOOL_NAME:-mypy}" \
  -reporter="${INPUT_REPORTER:-github-pr-check}" \
  -filter-mode="${INPUT_FILTER_MODE}" \
  -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
  -level="${INPUT_LEVEL}" \
  ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"
echo '::endgroup::'

echo '::group:: Mypy output:'
echo "${mypy_check_output}"
if [[ "$mypy_exit_val" != 0 && \
      ( $mypy_check_output == *"Command not found"* \
        || $mypy_check_output == *"Please change python executable"* \
      )\
    ]]; then
    echo "Error occurred while executing the mypy command: $mypy_check_output"
    exit $mypy_exit_val
fi
echo '::endgroup::'

# Throw error if an error occurred and fail_on_error is true
if [[ "${INPUT_FAIL_ON_ERROR}" == "true"  \
    && ( "${mypy_exit_val}" != "0"        \
        || "${reviewdog_exit_val}" != "0" \
    ) \
]]; then
  exit 1
fi
