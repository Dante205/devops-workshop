vnet_address = ["10.0.0.0/16"]
services = {
  ansible = {
    name        = "Ansible"
    cidr_subnet = "10.0.10.0/24"
    public_ip   = "yes"
    nsg_rules = [
      {
        name                       = "Allow_SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "22"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow_HTTP"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "80"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  jenkins_master = {
    name        = "Jenkins-Master"
    cidr_subnet = "10.0.11.0/24"
    public_ip   = "yes"
    nsg_rules = [
      {
        name                       = "Allow_SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "22"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "Allow_HTTP"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "80"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]

  },
  jenkins_slave = {
    name        = "Jenkins-Slave"
    cidr_subnet = "10.0.20.0/24"
    public_ip   = "no"
    nsg_rules   = []
  }
}

local_private_key_path = "./linuxkey.pem"
remote_path            = "/home/ubuntu"
remote_user            = "ubuntu"
