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

variable vm_base_name {
  type = string
}

variable "vm_name" {
  type = string
}

source "tart-cli" "tart" {
  vm_base_name = "${var.vm_base_name}"
  vm_name = "${var.vm_name}"
  disk_size_gb = 40
  headless = false
  disable_vnc = true
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "ansible" {
    playbook_file = "./playbook-gpu.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }
}
