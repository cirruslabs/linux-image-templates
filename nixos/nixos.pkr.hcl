packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.1"
    }
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = "= 1.21.0"
    }
  }
}

variable "iso_path" {
  type = string
}

variable "vm_name" {
  type = string
}

source "tart-cli" "nixos" {
  vm_name      = var.vm_name
  from_iso     = [var.iso_path]
  cpu_count    = 4
  memory_gb    = 4
  disk_size_gb = 20
  display      = "1024x768"
  headless     = false
  boot_wait    = "10s"
  boot_command = [
    "<wait 'nixos@nixos'>",
    "curl -fsSL http://{{ .HTTPIP }}:{{ .HTTPPort }}/install.sh | sudo bash -s -- http://{{ .HTTPIP }}:{{ .HTTPPort }}<enter>",
  ]
  http_directory = "${path.root}/http"

  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "60m"
}

build {
  sources = ["source.tart-cli.nixos"]

  provisioner "ansible" {
    playbook_file = "${path.root}/../playbook.yml"
    use_sftp      = true
    # ISO builds need Packer's temporary localhost SSH proxy because the guest
    # has no stable IP before installation. The proxy generates an ECDSA host
    # key and uses a temporary RSA key whose signature some OpenSSH policies
    # exclude. Allow both only for this proxy; the guest's policy is unchanged.
    ansible_ssh_extra_args = [
      "-o",
      "IdentitiesOnly=yes",
      "-o",
      "HostKeyAlgorithms=+ecdsa-sha2-nistp384",
      "-o",
      "PubkeyAcceptedAlgorithms=+ssh-rsa",
    ]
    extra_arguments = [
      "--extra-vars",
      "ansible_python_interpreter=/run/current-system/sw/bin/python3",
    ]
  }

  # Remove build-time SSH identity before capture. NixOS's sshd-keygen service
  # generates fresh host keys on each clone's first boot.
  provisioner "shell" {
    inline = [
      "sudo rm -f /etc/ssh/ssh_host_*",
      "test -z \"$(find /etc/ssh -maxdepth 1 -name 'ssh_host_*' -print -quit)\"",
      "sync",
    ]
  }
}
