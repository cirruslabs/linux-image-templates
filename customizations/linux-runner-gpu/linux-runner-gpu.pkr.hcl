packer {
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = ">= 1.7.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.1"
    }
  }
}

variable "vm_name" {
  type = string
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/ubuntu-runner-amd64:latest"
  vm_name = "${var.vm_name}"
  disk_size_gb = 20
  headless = false
  disable_vnc = true
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      # Install NVIDIA GPU driver
      "sudo apt-get update",
      "sudo apt-get install -y linux-headers-$(uname -r)",
      "sudo apt-get install -y nvidia-dkms-550",
      "sudo apt-get install -y nvidia-driver-550-server",
    ]
  }
}
