#!/bin/bash

set -e

# Get the last version tag (assumes tags are in the format v0.0.X)
last_tag=$(git tag --list 'v0.0.*' | sort -V | tail -n 1)

if [ -z "$last_tag" ]; then
  echo "No previous tag found. Starting at v0.0.1"
  last_patch=0
else
  echo "The last version was $last_tag"
  last_patch=$(echo "$last_tag" | cut -d. -f3)
fi

# Increment patch version
new_patch=$((last_patch + 1))
new_version="v0.0.$new_patch"
commit_message="Automated message for $new_version"
tag_message="Automated message for $new_version"

git add -A
git commit -m "$commit_message"
git tag -a "$new_version" -m "$tag_message"
echo "The new version is $new_version"
git push origin main --follow-tags
echo "Changes added, commited, tagged and pushed."
