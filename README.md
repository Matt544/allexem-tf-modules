# allexem-tf-modules

This repository contains reusable Terraform modules for the **Allexem project** infrastructure, including DNS configuration, S3 setup, and more. Each module resides in its own subdirectory and is versioned via Git tags.

## How to Use the Module

Update the module's `source` directive:
```
module "dns" {
  source = "git@github.com:Matt544/allexem-tf-modules.git//dns?ref=v0.0.1"
  <...>
}
```
Terraform will need to use the ssh key for this. ~/.ssh/config is set up to sse ~/.ssh/id_ed25519.

Before using the module, start the SSH agent manually:
```shell
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
The ssh passphrase is the usual default password for the Allexem project.

## Versioning
Modules are versioned using Git tags. 

### To Commit and tag a new version
```shell
git add -A
git commit -m "Update module to support XYZ"
git describe --tags --abbrev=0  # confirm current version so you can increment. E.g. v0.0.1
git tag -a v0.0.2 -m "Description of tag"
git push origin main --follow-tags
```

### To create a new version tag
```shell
git tag -a v0.0.2 -m "Description of changes"
git push origin v0.0.2
```
Note: Update your Terraform source reference to match: `source = "git@github.com:Matt544/allexem-tf-modules.git//dns?ref=v0.0.2"`.

Note: For this to work, make sure your commit is already pushed to `main` or another branch, or push it first with git push origin main.

### Change the reference of an existing tag
To force an old tag (e.g., v0.0.1) to point to a new commit:
```shell
git add -A
git commit -m "the message"
git push origin main

# Move the tag locally to the latest commit (force update with -f)
git tag -fa v0.0.2 -m "Retagging to latest commit"
# Delete the remote tag
git push origin :refs/tags/v0.0.2
# Push the updated tag to GitHub
git push origin v0.0.2
```

After doing those things, re-running `terraform apply` on the modules won't pick up the changes because the modules will use the existing "cached" code. Do this:
```shell
rm -rf .terraform/modules
terraform init -upgrade
```
This will clear the cached module and re-download it from Git, using the latest commit referenced by the tag.
