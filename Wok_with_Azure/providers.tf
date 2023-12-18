terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.83.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  # subscription_id = "YOUR_SUBSCRIPTION_ID"
  # tenant_id       = "YOUR_TENANT_ID"
  # client_id       = "YOUR_APPLICATIONCLIENT_ID_FROM_APPLICATION_OBJECT"
  # client_secret   = "YOUR_SECRET_YOU_CREATED"
  features {

  }
}