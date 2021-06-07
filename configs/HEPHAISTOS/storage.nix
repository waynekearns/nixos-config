# This file contains the configuration of disks and storage
{ config, ... }:

let
  rootPool = mkUuid "1700c195-e991-4c08-9055-5d0403fb1cc6"; # Device to mount the main btrfs pool from

  # TODO put in custom lib
  mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";
  mkMount = subvol: {
    device = rootPool;
    fsType = "btrfs";
    options = [ "compress-force=zstd:1" "subvol=${subvol}" ];
  };
in

{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  # TODO refactor into custom.luksPools
  boot.initrd.luks.devices = {
    TR200_18PB71KWK3QS-crypt = {
      device = mkUuid "642a307a-9b37-414b-b53b-045eeb277d72";
      allowDiscards = true;
    };
  };

  fileSystems = {
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
    };
    "/boot" = {
      device = mkUuid "B422-5366";
      fsType = "vfat";
      options = [ "umask=077" ];
    };

    "/" = mkMount "root";
    "/nix" = mkMount "nix";
    "/home" = mkMount "home";
    "/var/opt/games" = mkMount "games";
  };

  # TODO factor out into custom.zram
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
    numDevices = 1; # default
    priority = 5; # default
    swapDevices = 1; # why do I need this?
  };
}
