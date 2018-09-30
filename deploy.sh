#!/bin/bash

echo -e "Deploying updates to GitHub..."

# delete public folder
rm -rf public

# Build the project.
hugo # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd ../crazyzlj.github.io

# clean working dir
rm -f .git/index
git clean -df

# copy public folder
cp -av ../website_ljzhu/public/* .

# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ../website_ljzhu
