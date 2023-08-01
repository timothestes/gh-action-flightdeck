#!/bin/bash

# Usage: ./get-changed-files.sh <workdir> <filetype>

workdir=$1
filetype=$2

# Fetch the latest changes from the remote repository
git fetch origin dev

# Get the list of changed files, filter out deleted files and remove the workdir prefix
changed_files=$(git diff --name-only --diff-filter=ACMRT origin/dev..HEAD -- "*$filetype" | sed "s|^$workdir/||" | tr "\n" " ")

# Trim leading and trailing whitespace
changed_files=$(echo -e "${changed_files}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')


# Print the changed files
echo "${changed_files}"