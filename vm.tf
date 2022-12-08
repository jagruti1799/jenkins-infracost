resource "tls_private_key" "webkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "webkey" {
  filename= "webkey.pem"  
  content= tls_private_key.webkey.private_key_pem 
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "nginx-vm"
  location              = var.location
  resource_group_name   = "EIC-DevOps-RG"
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B1s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "Linux"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
     path     = "/home/adminuser/.ssh/authorized_keys"
     key_data = tls_private_key.webkey.public_key_openssh
    }
}
      # connection {
      # type = "ssh"
      # user = "adminuser"
      # host = azurerm_public_ip.publicip.ip_address
      # private_key = tls_private_key.webkey.private_key_pem
      #  } 

    connection {
    type     = "ssh"
    user     = "root"
    password = "Password1234!"
    host = azurerm_public_ip.publicip.ip_address
  }

   provisioner "local-exec" {
    command = "chmod 600 webkey.pem"
  }
}

resource "azurerm_lb" "nginx_lb" {
  name                = "ngnixlb"
  location            = var.location
  resource_group_name = "EIC-DevOps-RG"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.publicip.id
    }
}
