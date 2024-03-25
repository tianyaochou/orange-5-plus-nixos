{ config, lib, pkgs, inputs, packages, ... }: {
  imports = [ "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];

  boot = {
    kernelPackages = pkgs.linuxPackagesFor pkgs.linuxKernel.kernels.linux_6_8;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    supportedFilesystems = lib.mkForce [
      "vfat"
      "fat32"
      "exfat"
      "ext2"
      "ext4"
      "btrfs"
    ];
  };

  hardware = {
    deviceTree = {
      name = "rockchip/rk3588-orangepi-5-plus.dtb";
      overlays = [];
    };
  };

  networking.networkmanager.enable = true;

  programs.fish.enable = true;

  users.users.tianyaochou = {
    name = "tianyaochou";
    isNormalUser = true;
    shell = pkgs.fish;
    initialPassword = "orangepi";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keyFiles = [
      (pkgs.fetchurl {
        url = "https://github.com/tianyaochou.keys";
        sha256 = "df4fe57000c2229c4231e96962d5da532ed7de80d84a4cc94a187386d7d668c3";
      })
    ];
  };

  services.openssh.enable = true;

  sdImage = {
    imageBaseName = "orangepi-5-plus";
    firmwarePartitionOffset = 32;
    firmwarePartitionName = "BOOT";
    firmwareSize = 200; # MiB
    populateFirmwareCommands = lib.mkForce ''
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
    '';
    postBuildCommands = ''
      dd if=${packages.ubootOrangePi5Plus}/u-boot-rockchip.bin of=$img seek=64 conv=notrunc
    '';
    compressImage = false;
  };
}
