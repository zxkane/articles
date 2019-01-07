#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

git submodule update --init --recursive
# Build the project.
hugo # if using a theme, replace with `hugo -t <YOURTHEME>`

# Go To Public folder
cd public
# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git fetch && git rebase origin/master
git push origin HEAD:master

# Come Back up to the Project Root
cd ..
