#!/bin/bash

# Usage:
# chmod +x commit-patch.sh
# ./commit-patch.sh

set -e

# Ensure we're on the 'main' branch before proceeding
current_branch=$(git symbolic-ref --short HEAD)
if [[ "$current_branch" != "main" ]]; then
  echo "Error: You are on branch '$current_branch'. Please switch to 'main' before "\
    "running this script."
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
  echo "No remote release tag found. Starting at v0.0.1"
elif [ -z "$local_last_tag" ]; then
  echo "Remote latest tag is $remote_last_tag, but no local tag found."
  echo "Aborting. You may need to fetch or create the local tag."
  exit 1
else
  echo "Remote last release version:  $remote_last_tag"
  echo "Local last release version:   $local_last_tag"
  echo
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
if [ -n "$version_numbers" ]; then
  read major minor patch <<< "$version_numbers"
fi

echo "Choose a new tag type:"
echo "1. dev-tag (git-<short_hash>)"
echo "2. + patch"
echo "3. + minor"
echo "4. + major"
read -p "☛ " tag_type
# use dict for major/minor/patch to prevent errors

placeholder_dev_version="git-<short_hash>-TBD"

if [[ "$tag_type" == "1" ]]; then
  # short_hash=$(git rev-parse --short main)
  # new_version="git-$short_hash"
  new_version=$placeholder_dev_version  # TBD, after the new commit hash is available.
  echo "You chose a dev-tag (git-<short_hash>)."
  # echo "New version tag: $new_version."
elif [[ "$tag_type" == "2" ]]; then
  # Increment patch version
  new_patch=$((patch + 1))
  new_version="v$major.$minor.$new_patch"
  echo "You chose a PATCH increment."
  echo
  echo "New version tag: $new_version."
elif [[ "$tag_type" == "3" ]]; then
  # Increment minor version
  new_patch=0
  new_minor=$((minor + 1))
  new_version="v$major.$new_minor.$new_patch"
  echo "You chose a MINOR increment."
  echo
  echo "New version tag: $new_version."
elif [[ "$tag_type" == "4" ]]; then
  # Increment major version
  new_patch=0
  new_minor=0
  new_major=$((major + 1))
  new_version="v$new_major.$new_minor.$new_patch"
  echo "You chose a MAJOR increment."
  echo
  echo "New version tag: $new_version."
else
  echo "Invalid tag type choice."
  exit 1
fi
echo

read -p "☛ Commit/tag message (press enter only for the automated default): " commit_message
if [[ "$commit_message" == "" ]]; then
  commit_message="Automated commit message"
fi
tag_message="$commit_message"
echo

# Show current git status and confirm
echo "Running 'git status'..."
echo
git status
echo
echo "Confirm to commit changes with:" 
echo "- tag:      $new_version"
echo "- message:  $commit_message"
read -p "☛ [yes/no]: " confirm
echo
if [[ "$confirm" != "yes" ]]; then
  echo "Aborting on user request."
  exit 1
fi

git add -A
git commit -m "$commit_message"
git rev-parse --short main

if [[ "$new_version" == $placeholder_dev_version ]]; then
  short_hash=$(git rev-parse --short main)
  new_version="git-$short_hash"
fi

git tag -a "$new_version" -m "$tag_message"
echo "The new version is $new_version"
git push origin main --follow-tags
echo "Changes added, committed, tagged and pushed."
echo

# Cull old git-* tags, keeping only the most recent 3
GIT_TAGS=$(git tag --sort=-creatordate | grep '^git-' || true)
TAGS_TO_DELETE=$(echo "$GIT_TAGS" | tail -n +4)

echo "Delete all but the last three dev tags? Namely:" 
for tag in $(echo "$TAGS_TO_DELETE" | xargs); do
  echo "- $tag"
done
read -p "☛ [yes/N]: " confirm_delete
echo

if [[ "$confirm_delete" != "yes" ]]; then
  echo "Skipping deletions."
  exit 1
else
  if [[ -n "$GIT_TAGS" ]]; then
    if [[ -n "$TAGS_TO_DELETE" ]]; then
      echo "Deleting old git-* tags..."
      # Delete local tags
      echo "$TAGS_TO_DELETE" | xargs -r git tag -d
      # Delete remote tags
      echo "$TAGS_TO_DELETE" | xargs -r -I {} git push origin --delete {}
    else
      echo "No old git-* tags to delete."
    fi
  else
    echo "No git-* tags found."
  fi
fi
