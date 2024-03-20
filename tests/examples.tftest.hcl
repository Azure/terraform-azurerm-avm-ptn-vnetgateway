provider "azurerm" {
  features {}
}

run "examples_default" {
  command = plan

  module {
    source = "./examples/default"
  }
}

run "examples_vnet_with_subnet" {
  command = plan

  module {
    source = "./examples/vnet-with-subnet"
  }
}

