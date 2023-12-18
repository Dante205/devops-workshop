
# Network Interface
resource "azurerm_network_interface" "tf_nic" {
  for_each            = var.services
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.tf_rg_cicd.location
  resource_group_name = azurerm_resource_group.tf_rg_cicd.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tf_subnets[each.key].id
    private_ip_address_allocation = "Dynamic"
    # Associate Public IP if the each.key has the propertie "public_ip" == yes
    public_ip_address_id = each.value.public_ip == "yes" ? azurerm_public_ip.tf_public_ip[each.key].id : null
  }
}

# Creates a PEM (and OpenSSH) formatted private key.
# Generates a secure private key and encodes it in PEM (RFC 1421) and OpenSSH PEM (RFC 4716) formats. 
resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generates a local file with the given content.
resource "local_file" "linuxpemkey" {
  content  = tls_private_key.linuxkey.private_key_pem
  filename = "${path.module}/linuxkey.pem"
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "tf_vm_linux" {
  for_each            = var.services
  name                = "server-${each.value.name}"
  resource_group_name = azurerm_resource_group.tf_rg_cicd.name
  location            = azurerm_resource_group.tf_rg_cicd.location
  size                = "Standard_B2s"
  admin_username      = "ubuntu"
  # custom_data = filebase64("./install_ansible.sh")
  # Install Ansible only in Ansible Server
  custom_data = each.value.name == "Ansible" ? filebase64("./install_ansible.sh") : null

  network_interface_ids = [
    azurerm_network_interface.tf_nic[each.key].id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = tls_private_key.linuxkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Copy Private SSH Key to Ansible Server
resource "null_resource" "copy_ssh_key" {
  # ...
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ${var.remote_path}/ansible",
      "mkdir -p /home/ubuntu/.ssh", # Crea el directorio .ssh si no existe
      "echo '${file(var.local_private_key_path)}' > ${var.remote_path}/.ssh/id_rsa",
      "chmod 600 ${var.remote_path}/.ssh/id_rsa",
      "echo 'StrictHostKeyChecking no' > ${var.remote_path}/.ssh/config", # Opcional: deshabilita la verificación de clave de host para evitar solicitudes interactivas
    ]
    connection {
      type        = "ssh"
      user        = var.remote_user
      private_key = file("${var.local_private_key_path}") # Ruta de tu clave privada local
      host        = azurerm_linux_virtual_machine.tf_vm_linux["ansible"].public_ip_address
    }
  }
  depends_on = [azurerm_linux_virtual_machine.tf_vm_linux]
}

# Reade Ansible Hosts file with respective Private IPs Jenkins Master and Slave
data "template_file" "ansible_hosts" {
  template = file("${path.module}/Ansible/hosts")

  vars = {
    JENKINS_MASTER_PRIVATE_IP = azurerm_linux_virtual_machine.tf_vm_linux["jenkins_master"].private_ip_address
    JENKINS_SLAVE_PRIVATE_IP  = azurerm_linux_virtual_machine.tf_vm_linux["jenkins_slave"].private_ip_address
  }
  depends_on = [azurerm_linux_virtual_machine.tf_vm_linux]
}
# Generate Ansible Hosts rendered with according values
resource "local_file" "ansible_hosts_output" {
  content    = data.template_file.ansible_hosts.rendered
  filename   = "${path.module}/Ansible/remote/ansible_hosts"
  depends_on = [data.template_file.ansible_hosts]
}

# Run Ansible Playbook
resource "null_resource" "copy_files" {
  provisioner "local-exec" {
    command = <<-EOF
      chmod 400 ${var.local_private_key_path}
      scp -i ${var.local_private_key_path} -o StrictHostKeyChecking=no ${path.module}/Ansible/remote/* ubuntu@${azurerm_linux_virtual_machine.tf_vm_linux["ansible"].public_ip_address}:${var.remote_path}/ansible
    EOF
  }
  depends_on = [azurerm_linux_virtual_machine.tf_vm_linux, null_resource.copy_ssh_key]
}

# Run Ansible Playbook to configure setup Jenkins Master and Slave
resource "null_resource" "run_ansible" {
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "ansible-playbook -i ${var.remote_path}/ansible/ansible_hosts ${var.remote_path}/ansible/jenkins-master-setup.yaml",
      "ansible-playbook -i ${var.remote_path}/ansible/ansible_hosts ${var.remote_path}/ansible/jenkins-slave-setup.yaml"
    ]
    connection {
      type        = "ssh"
      user        = var.remote_user
      private_key = file("${var.local_private_key_path}")
      host        = azurerm_linux_virtual_machine.tf_vm_linux["ansible"].public_ip_address
    }
  }
  depends_on = [
    null_resource.copy_files,
    data.template_file.ansible_hosts,
    azurerm_linux_virtual_machine.tf_vm_linux
  ]

}

