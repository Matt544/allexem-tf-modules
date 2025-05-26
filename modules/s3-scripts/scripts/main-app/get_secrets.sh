# #!/bin/bash
# echo ">>>>>> entered get_secrets.sh"
# set -euo pipefail
# mkdir -p secrets

# keys=(
#   "${staging_or_prod}/django_superuser_password.txt"
#   "${staging_or_prod}/secret_key.txt"
#   "${staging_or_prod}/s3_storage_bucket_name.txt"
#   "${staging_or_prod}/s3_access_key_id.txt"
#   "${staging_or_prod}/s3_secret_access_key.txt"
#   "${staging_or_prod}/sql_user.txt"
#   "${staging_or_prod}/sql_password.txt"
#   "${staging_or_prod}/sql_host.txt"
#   "${staging_or_prod}/stripe_publishable_key.txt"
#   "${staging_or_prod}/stripe_secret_key.txt"
#   "${staging_or_prod}/stripe_endpoint_secret.txt"
#   "${staging_or_prod}/stripe_price_id.txt"
#   "${staging_or_prod}/email_password.txt"
#   "${staging_or_prod}/recaptcha_public_key.txt"
#   "${staging_or_prod}/recaptcha_private_key.txt"
# )

# # Dear chatGPT:
# # This gets all secrets by their expected names. If I change the name of a secret file
# # that exists in s3 and change the name that the compose file expects, I also have to 
# # rememver to change the file name in this script. It would be easier to get all 
# # secrets without knowing their names and to save them using the existing names.

# # Please change this script so it does the following:
# # Instead of getting files by a key in the keys list, get all files in the s3 bucket 
# # with "${staging_or_prod}" in the key name (note: in the s3 secrets bucket, files are
# # uploaded to keys like "staging/secret1.txt" or "prod/secret1.txt", where staging and
# # prod use totally different buckets under different aws accounts). And it can save the 
# # file using the name under which it is found in s3, minus the "staging" or "prod" 
# # prefix. So if it is in s3 under "staging/secret1.txt" it will be saved to my system
# # under "./secrets/secret1.txt", which would be the same end result as the current 
# # script.


# for key in "${keys[@]}"; do
#   aws s3api get-object \
#     --bucket "allexem-${staging_or_prod}-secrets" \
#     --key "$key" \
#     "./secrets/$(basename "$key")"
# done

# # NOTE: I commented this out in connection with troubleshooting the nginx password thing
# # but watch in here for bugs, in case this turned out to be needed. I don't know why it
# # was there. Note: quick manual tests indicate that switching the order of these two 
# # `chown` blocks does not work for my site. I don't know why.
# # chown -R ubuntu:ubuntu ./secrets
# # chmod 600 ./secrets/*

# echo "<<<<<< exiting get_secrets.sh"

#!/bin/bash
echo ">>>>>> entered get_secrets.sh"
set -euo pipefail
mkdir -p secrets

bucket="allexem-${staging_or_prod}-secrets"

# List all secrets under the appropriate prefix and download them
aws s3api list-objects-v2 \
  --bucket "$bucket" \
  --prefix "${staging_or_prod}/" \
  --query 'Contents[].Key' \
  --output text |
while read -r key; do
  filename="${key#${staging_or_prod}/}"  # Strip the prefix from the key
  if [[ -n "$filename" ]]; then
    echo "Downloading $key to ./secrets/$filename"
    aws s3api get-object \
      --bucket "$bucket" \
      --key "$key" \
      "./secrets/$filename"
  fi
done

# (Optional) Reset ownership and permissions if needed
# chown -R ubuntu:ubuntu ./secrets
# chmod 600 ./secrets/*

echo "<<<<<< exiting get_secrets.sh"