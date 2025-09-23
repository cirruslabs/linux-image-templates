packer {
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = ">= 1.7.0"
    }
  }
}

variable "vm_name" {
  type = string
}

source "tart-cli" "tart" {
  vm_name = "${var.vm_name}"
  disk_size_gb = 25
  run_extra_args = ["--disk", "cloud-init.iso"]
  headless = false
  disable_vnc = true
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "file" {
    source = "99_cirruslabs.cfg"
    destination = "/tmp/99_cirruslabs.cfg"
  }

  provisioner "shell" {
    inline = [
      "cat /tmp/99_cirruslabs.cfg | sudo tee /etc/cloud/cloud.cfg.d/99_cirruslabs.cfg"
    ]
  }

  provisioner "ansible" {
    playbook_file = "./playbook.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }
}
