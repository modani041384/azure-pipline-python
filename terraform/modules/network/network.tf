resource "azurerm_virtual_network" "test" {
  name                 = "${var.application_type}-${var.resource_type}"
  address_space        = "${var.address_space}"
  location             = "${var.location}"
  resource_group_name  = "resources-tf-2022"
}
resource "azurerm_subnet" "test" {
  name                 = "${var.application_type}-${var.resource_type}-sub"
  resource_group_name  = "resources-tf-2022"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefixes     = ["10.0.2.0/24"]
}
