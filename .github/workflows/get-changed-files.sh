#!/bin/bash

# Usage: ./get-changed-files.sh <workdir> <filetype> <main_branch> <repository>

workdir=$1
filetype=$2
main_branch=$3
repository=$4

# Fetch the latest changes from the remote repository
# figure out main branch
git fetch https://$GITHUB_TOKEN@github.com/$repository.git $main_branch

# Get the list of changed files, filter out deleted files and remove the workdir prefix
changed_files=$(git diff --name-only --diff-filter=ACMRT FETCH_HEAD -- "*$filetype" | sed "s|^$workdir/||" | tr "\n" " ")

# Trim leading and trailing whitespace
changed_files=$(echo -e "${changed_files}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Print the changed files
echo "${changed_files}"
