{
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # Match the cloud images: grow the root partition and filesystem on boot
  # after increasing the VM disk with `tart set --disk-size`.
  boot.growPartition = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  networking.hostName = "nixos";
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-ethernet" = {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  users.users.admin = {
    isNormalUser = true;
    initialPassword = "admin";
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    gzip
    python3
    gnutar
  ];

  systemd.services.tart-guest-agent = {
    description = "Guest agent for Tart VMs";
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/home/admin/.local/bin/tart-guest-agent";
    serviceConfig = {
      Type = "simple";
      User = "admin";
      ExecStart = "/home/admin/.local/bin/tart-guest-agent --run-rpc";
      Restart = "on-failure";
    };
  };

  system.stateVersion = "26.05";
}
