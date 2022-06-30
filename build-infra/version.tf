terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.11.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# variable "boundary_version" {
#   type    = string
#   default = "0.9.0"
# }

