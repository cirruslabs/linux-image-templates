packer {
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = ">= 1.6.1"
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
  vm_name = "${var.vm_name}"
  disk_size_gb = 20
  headless = false
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "ansible" {
    playbook_file = "./playbook.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }

  provisioner "shell" {
    inline = [
      # Add "admin" user to the "docker" group
      "sudo gpasswd -a admin docker",
      "newgrp",
      # Disable unattended upgrades
      "sudo cp /usr/share/unattended-upgrades/20auto-upgrades-disabled /etc/apt/apt.conf.d/",
      # Install QEMU and emulators for non-host architectures, so that we can
      # run e.g. "docker run --rm ppc64le/alpine uname -a" on arm64
      "sudo apt-get install -y qemu-kvm",
      "sudo docker run --privileged --rm tonistiigi/binfmt --install all",
    ]
  }

  provisioner "shell" {
    script = "install-actions-runner.sh"
  }
}
