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
  vm_base_name = "ghcr.io/cirruslabs/ubuntu:latest"
  vm_name = "${var.vm_name}"
  headless = false
  ssh_username = "admin"
  ssh_password = "admin"
}

build {
  sources = ["source.tart-cli.tart"]

  # Install Docker in accordance with the Docker's official instructions for Ubuntu[1]
  #
  # [1]: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
  provisioner "shell" {
    inline = [
      # Set up Docker's apt repository
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo chmod a+r /etc/apt/keyrings/docker.gpg",
      "echo \"deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      # Install the Docker packages
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
    ]
  }
}
