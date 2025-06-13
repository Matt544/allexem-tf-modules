#!/bin/bash

# Usage:
# chmod +x commit_patch.sh
# ./commit_patch.sh

# If you don't want to commit a patch (e.g. you want no new version number or you need
# to change the major or minor numbers), then do so manually.

set -e

# Ensure we're on the 'main' branch before proceeding
current_branch=$(git symbolic-ref --short HEAD)
if [[ "$current_branch" != "main" ]]; then
  echo "Error: You are on branch '$current_branch'. Please switch to 'main' before running this script."
  exit 1
fi

# Fetch the latest remote tags
git fetch --tags

# Get the most recent local and remote tags matching v*.*.*
local_last_tag=$(git tag --list 'v*.*.*' | sort -V | tail -n 1)
remote_last_tag=$(git ls-remote --tags origin 'v*.*.*' \
  | awk '{print $2}' \
  | grep -v '\^{}' \
  | sed 's|refs/tags/||' \
  | sort -V \
  | tail -n 1)

# Initialize version components
major=0
minor=0
patch=0

if [ -z "$remote_last_tag" ]; then
  echo "No remote tag found. Starting at v0.0.1"
elif [ -z "$local_last_tag" ]; then
  echo "Remote latest tag is $remote_last_tag, but no local tag found."
  echo "Aborting. You may need to fetch or create the local tag."
  exit 1
else
  echo "Remote last version is $remote_last_tag"
  echo "Local last version is $local_last_tag"
  if [ "$remote_last_tag" != "$local_last_tag" ]; then
    echo "WARNING: Local and remote tags differ."
    echo "Remote: $remote_last_tag"
    echo "Local : $local_last_tag"
    echo "You can delete tags with [Note: not tested]:"
    echo "  git tag -d $local_last_tag     # local"
    echo "  git push origin :refs/tags/$remote_last_tag  # remote"
    read -p "Proceed anyway with local version ($local_last_tag)? [yes/no] " answer
    if [[ "$answer" != "yes" ]]; then
      echo "Aborting due to tag mismatch."
      exit 1
    fi
  fi
fi

# Parse version numbers from local_last_tag (e.g., v2.5.12)
version_numbers=$(echo "$local_last_tag" | sed -E 's/^v([0-9]+)\.([0-9]+)\.([0-9]+)$/\1 \2 \3/')
read major minor patch <<< "$version_numbers"

# Increment patch version
new_patch=$((patch + 1))
new_version="v$major.$minor.$new_patch"

read -p "Commit message (press enter only for the automated default): " commit_message
if [[ "$commit_message" == "" ]]; then
  commit_message="Automated message for $new_version"
fi
# commit_message="Automated message for $new_version"
tag_message="Automated message for $new_version"

# Show current git status and confirm
git status
read -p "Continue with these changes and tag with '$new_version'? [yes/no]: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborting on user request."
  exit 1
fi

git add -A
git commit -m "$commit_message"
git tag -a "$new_version" -m "$tag_message"
echo "The new version is $new_version"
git push origin main --follow-tags
echo "Changes added, committed, tagged and pushed."
