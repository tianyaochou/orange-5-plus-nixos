{ config, lib, pkgs, inputs, flakePackages, ... }: {
  imports = [ "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix" ];

  boot = {
    kernelPackages = pkgs.linuxPackagesFor flakePackages.kernel-armbian;
    kernelParams = [
      "root=UUID=${"14e19a7b-0ae0-484d-9d54-43bd6fdc20c7"}"
      "rootwait"
      "rootfstype=ext4"

      "earlycon" # enable early console, so we can see the boot messages via serial port / HDMI
      "consoleblank=0" # disable console blanking(screen saver)
      "console=ttyS2,1500000" # serial port
      "console=tty1" # HDMI
    ];
    supportedFilesystems = lib.mkForce [
      "vfat"
      "fat32"
      "exfat"
      "ext4"
      "btrfs"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.includeDefaultModules = lib.mkForce false;
    initrd.availableKernelModules = lib.mkForce [ "ahci" "uas" "nvme" "dw-hdmi" "dw-mipi-dsi" "rockchipdrm" "rockchip-rga" "phy-rockchip-pcie" "panel-simple" "pwm-bl" "ext2" "ext4" ];
    #Removed ata_piix sata_inic162x sata_nv sata_promise sata_qstor sata_sil sata_sil24 sata_sis sata_svw sata_sx4 sata_uli sata_via sata_vsc pata_* 3w-9xxx arcmsr
  };

  hardware = {
    deviceTree = {
      name = "rockchip/rk3588-orangepi-5-plus.dtb";
      overlays = [];
    };

    firmware = [];
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
      dd if=${flakePackages.ubootOrangePi5Plus}/u-boot-rockchip.bin of=$img seek=64 conv=notrunc
    '';
    compressImage = false;
  };
}
