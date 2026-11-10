packer {
  required_plugins {
    tart = {
      source  = "github.com/cirruslabs/tart"
      version = "= 1.21.0"
    }
  }
}

variable "vm_name" {
  type = string
}

source "tart-cli" "omarchy" {
  vm_name            = var.vm_name
  cpu_count          = 4
  memory_gb          = 8
  display            = "1440x900px"
  communicator       = "none"
  recovery_partition = "keep"
}

build {
  sources = ["source.tart-cli.omarchy"]
}
