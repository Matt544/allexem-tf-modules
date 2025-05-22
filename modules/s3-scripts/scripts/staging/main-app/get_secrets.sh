#!/bin/bash
echo ">>>>>> entered get_secrets.sh"
set -euo pipefail
mkdir -p secrets

keys=(
  "${staging_or_prod}/django_superuser_password.txt"
  "${staging_or_prod}/secret_key.txt"
  "${staging_or_prod}/s3_storage_bucket_name.txt"
  "${staging_or_prod}/s3_access_key_id.txt"
  "${staging_or_prod}/s3_secret_access_key.txt"
  "${staging_or_prod}/sql_user.txt"
  "${staging_or_prod}/sql_password.txt"
  "${staging_or_prod}/sql_host.txt"
  "${staging_or_prod}/stripe_publishable_key.txt"
  "${staging_or_prod}/stripe_secret_key.txt"
  "${staging_or_prod}/stripe_endpoint_secret.txt"
  "${staging_or_prod}/stripe_price_id.txt"
  "${staging_or_prod}/email_password.txt"
  "${staging_or_prod}/recaptcha_public_key.txt"
  "${staging_or_prod}/recaptcha_private_key.txt"
)

for key in "${keys[@]}"; do
  aws s3api get-object \
    --bucket allexem-secrets \
    --key "$key" \
    "./secrets/$(basename "$key")"
done

# NOTE: I commented this out in connection with troubleshooting the nginx password thing
# but watch in here for bugs, in case this turned out to be needed. I don't know why it
# was there. Note: quick manual tests indicate that switching the order of these two 
# `chown` blocks does not work for my site. I don't know why.
# chown -R ubuntu:ubuntu ./secrets
# chmod 600 ./secrets/*

echo "<<<<<< exiting get_secrets.sh"
