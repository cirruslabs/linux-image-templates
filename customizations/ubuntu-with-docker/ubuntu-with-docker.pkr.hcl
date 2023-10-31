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
      # Add "admin" user to the "docker group
      "sudo gpasswd -a admin docker",
    ]
  }

  provisioner "shell" {
    inline = [
      # Install basic necessity utilities
      "sudo apt-get install -y vim zip git build-essential",
      # Install packages needed for Python development
      "sudo apt-get install -y python3-dev python3-pip python3-venv",
      # Install packages needed for Ruby development
      "sudo apt-get install -y ruby-dev",
      "sudo gem install bundler",
      # Install packages needed for Java development
      "sudo apt-get install -y openjdk-17-jdk",
      # Disable unattended upgrades
      "sudo cp /usr/share/unattended-upgrades/20auto-upgrades-disabled /etc/apt/apt.conf.d/",
      # Install Packer
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg",
      "sudo chmod a+r /etc/apt/keyrings/hashicorp.gpg",
      "echo \"deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null",
      "sudo apt-get update && sudo apt-get install -y packer",
      # Install AWS Command Line Interface
      "wget -O /tmp/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip",
      "unzip /tmp/awscli.zip",
      "rm /tmp/awscli.zip",
      "sudo ./aws/install",
      "rm -r aws",
      # Install QEMU
      "sudo apt-get install -y qemu-kvm",
      # Install emulators for non-host architectures, so that we can
      # run e.g. "docker run --rm ppc64le/alpine uname -a" on arm64
      "sudo docker run --privileged --rm tonistiigi/binfmt --install all",
    ]
  }
}
