#!/bin/bash
set -euo pipefail

echo ">>>>>> entered get_secrets.sh"

mkdir -p secrets

bucket="allexem-${staging_or_prod}-secrets"
prefix="${staging_or_prod}/"

# Step 1: Get the list of keys from the bucket and prefix, store in an array
echo "Listing objects in bucket: $bucket with prefix: $prefix"
keys_json=$(aws s3api list-objects-v2 --bucket "$bucket" --prefix "$prefix" --query 'Contents[].Key' --output json)

# Parse JSON array to bash array of keys (requires jq)
mapfile -t keys < <(echo "$keys_json" | jq -r '.[]')

echo "Found ${#keys[@]} keys."

# Step 2: Download each object and save under ./secrets/
for key in "${keys[@]}"; do
  filename="${key#${prefix}}"  # Remove the prefix from the key to get filename

  if [[ -z "$filename" ]]; then
    echo "Skipping empty filename for key: $key"
    continue
  fi

  echo "Downloading $key to ./secrets/$filename"
  aws s3api get-object --bucket "$bucket" --key "$key" "./secrets/$filename"
done

echo "<<<<<< exiting get_secrets.sh"
