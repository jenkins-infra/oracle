provider "azurerm" {
  features {}
}

provider "tls" {
}

provider "oci" {
  region = var.region
}
