# Jenkins Infra on Oracle

> **Warning**
> This project is archived as per <https://github.com/jenkins-infra/helpdesk/issues/3761>, hence this repository archival

This repository hosts the infrastructure-as-code definition for all the [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) resources for the [Jenkins Infrastructure Project](https://www.jenkins.io/projects/infrastructure/).

## Requirements

* An Oracle Cloud account with the administration permissions on the tenant jenkins infra.
* The requirements (of the shared tools) listed at [shared-tools/terraform#requirements](https://github.com/jenkins-infra/shared-tools/tree/main/terraform#requirements).
* The [Terraform Azure Bucket](https://www.terraform.io/docs/language/settings/backends/azurerm.html) on a local file named `backend-config`:
  * The content can be retrieved from the outputs of the [(private) repository terraform-states](https://github.com/jenkins-infra/terraform-states)
  * This file (`backend-config`) is git-ignored

* The git command line to allow cloning the repository and its submodule [shared-tools](https://github.com/jenkins-infra/shared-tools)
  * This repository has submodules. Once you cloned the repository, execute the following command to obtain the shared tools:

```bash
git submodule update --init --recursive
```

## HowTo

IMPORTANT: Don't blindly execute the terraform code located in this repository on your own account as it may lead your account bill to significantly increase.

Once you've fulfilled the [#requirements](./#requirements), you may execute any command from <https://github.com/jenkins-infra/shared-tools/blob/main/terraform/README.adoc#available-commands> by adding the correct flag `--directory` pointing to `.shared-tools/terraform/`:

```bash
make --directory=.shared-tools/terraform help
make --directory=.shared-tools/terraform lint
# ...
```

A usual change to this repository looks like the following:

* Fork the repository and clone it locally
* Follow the [#requirements](./#requirements) steps to obtain the shared tools
* Start by running a full `make --directory=.shared-tools/terraform validate` command to ensure that you work on a sane base (should generate a report TXT file with no changes to be applied)
* Edit the Terraform project files
* Run the command `make --directory=.shared-tools/terraform validate` again to ensure that your changes are OK
* Commit, push and open a pull request to let the Jenkins pipeline run the test + plan (as per <https://github.com/jenkins-infra/shared-tools/blob/main/terraform/README.adoc#jenkins-pipeline>)
