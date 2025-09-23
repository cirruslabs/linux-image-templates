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
  vm_name = "${var.vm_name}"
  disk_size_gb = 25
  headless = false
  disable_vnc = true
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "ansible" {
    playbook_file = "./playbook-runner.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }

  provisioner "ansible" {
    playbook_file = "./playbook-extras.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }

  provisioner "shell" {
    script = "test.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} bash -l {{ .Path }}"
  }

  provisioner "shell" {
    inline = [
      # Add "admin" user to the "docker" group
      "sudo gpasswd -a admin docker",
      "newgrp",
      # Add "admin" user to the "kvm" group
      "sudo gpasswd -a admin kvm",
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

  provisioner "ansible" {
    playbook_file = "./playbook-setup-info-generator.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }
}
