# allexem-tf-modules

This repository contains reusable Terraform modules for the **Allexem project** infrastructure, including DNS configuration, S3 setup, and more. Each module resides in its own subdirectory and is versioned via Git tags.

## How to Use the Module

Update the module's `source` directive:
```hcl
module "dns" {
  source = "git@github.com:Matt544/allexem-tf-modules.git//dns?ref=v0.0.1"

  <...>
}
```
Terraform will need to use the ssh key for this. ~/.ssh/config is set up to sse ~/.ssh/id_ed25519.

Before using the module, start the SSH agent manually:
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
The ssh passphrase is the usual default password for the Allexem project.

## Versioning
Modules are versioned using Git tags. To create a new version:
```
git tag -a v0.0.2 -m "Description of changes"
git push origin v0.0.2
```
Update your Terraform source reference to match: `source = "git@github.com:Matt544/allexem-tf-modules.git//dns?ref=v0.0.2"`.
