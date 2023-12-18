output "virtual_machines_public_ips" {
  value = [
    for instance in azurerm_linux_virtual_machine.tf_vm_linux : {
      name      = instance.computer_name
      public_ip = "http://${instance.public_ip_address}"
    }
  ]
}
