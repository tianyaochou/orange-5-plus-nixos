{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.rk3588.url = "github:ryan4yin/nixos-rk3588";

  outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } ({ self, ... }: {
    flake = {
    };
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    perSystem = { self', pkgs, lib, config, ... }: {
      packages.ubootOrangePi5Plus = with pkgs; let rkbin = pkgs.fetchFromGitHub {
          owner = "rockchip-linux";
          repo = "rkbin";
          rev = "b4558da0860ca48bf1a571dd33ccba580b9abe23";
          sha256 = "sha256-KUZQaQ+IZ0OynawlYGW99QGAOmOrGt2CZidI3NTxFw8=";
        }; in
        stdenv.mkDerivation {
          name = "u-boot-orangepi-5-plus";
          version = "2024.1";
          src = fetchGit {
            url = "https://github.com/u-boot/u-boot";
            name = "v2024.0";
            rev = "866ca972d6c3cabeaf6dbac431e8e08bb30b3c8e";
          };
          nativeBuildInputs = [
            ncurses
            openssl
            bc
            bison
            flex
            (buildPackages.python3.withPackages (p: [
              p.setuptools # for pkg_resources
              p.pyelftools
            ]))
            swig
          ];
          postPatch = ''
            patchShebangs tools
            patchShebangs scripts
          '';
          configurePhase = ''
            make orangepi-5-plus-rk3588_defconfig
          '';
          buildPhase = ''
            make -j$NIX_BUILD_CORES
          '';
          ROCKCHIP_TPL="${rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.12.bin";
          BL31="${rkbin}/bin/rk35/rk3588_bl31_v1.40.elf";
          installPhase = ''
            mkdir $out
            cp u-boot-rockchip.bin $out
            mkdir $out/tools
            cp tools/mkimage $out/tools
          '';
        };
      packages.kernel-armbian = with pkgs; ((linuxManualConfig {
        version = "5.10.160-armbian";
        modDirVersion = "5.10.160";

        configfile = ./rk3588_linux; # rockchip_linux_defconfig + rk3588_linux.config with CONFIG_ANDROID=n CONFIG_AUTOFS_FS=y and CONFIG_ATA_PIIX=y
        allowImportFromDerivation = true; # Have to be true so linuxManualConfig will parse the configfile as a nix attrset, so assertions can be checked

        src = fetchgit {
          url = "https://github.com/armbian/linux-rockchip";
          hash = "sha256-zruENU8SFFZ5KJYa2iYBqmEJHwWsowGZ/GnlvN8xxwU=";
        };
      }).overrideAttrs (super: { nativeBuildInputs = super.nativeBuildInputs ++ [ ubootTools ncurses pkg-config ];}));

    };

    flake.nixosConfigurations.orangepi = let system = "aarch64-linux"; in
      inputs.nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs;
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          flakePackages = self.packages.${system};
        };
        modules = [
          ./orangepi.nix
        ];
      };
  });
}
