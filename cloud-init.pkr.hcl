packer {
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = ">= 1.6.1"
    }
  }
}

variable "vm_name" {
  type = string
}

source "tart-cli" "tart" {
  vm_name = "${var.vm_name}"
  run_extra_args = ["--disk", "cloud-init.iso"]
  headless = false
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      # Disable Cloud Init[1] to avoid wasting time
      # trying to crawl non-existent metadata
      #
      # [1]: https://cloudinit.readthedocs.io/en/latest/howto/disable_cloud_init.html#method-1-text-file
      "sudo touch /etc/cloud/cloud-init.disabled"
    ]
  }
}
