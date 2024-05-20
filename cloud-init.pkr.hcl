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
  disk_size_gb = 20
  run_extra_args = ["--disk", "cloud-init.iso"]
  headless = false
  disable_vnc = true
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      # We can't disable the Cloud Init because otherwise we loose the growpart functionality[1],
      # so disable all data sources instead.
      #
      # Also see [2] for more details.
      #
      # [1]: https://cloudinit.readthedocs.io/en/latest/reference/modules.html#growpart
      # [2]: https://github.com/cirruslabs/linux-image-templates/pull/8
      "echo 'datasource_list: [ None ]' >> /etc/cloud/cloud.cfg.d/99_cirruslabs.cfg",
      # Cloud Init creates a /etc/ssh/sshd_config.d/50-cloud-init.conf file on Fedora
      # with "PasswordAuthentication no" contents despite us setting the
      # "ssh_pwauth: true" in "user-data" file, so override this behavior.
      "echo 'ssh_pwauth: true' >> /etc/cloud/cloud.cfg.d/99_cirruslabs.cfg"
    ]
  }
}
