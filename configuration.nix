# This file implements things I want to have on all my NixOS machines and
# automatically includes host- and hardware-specific configuration based on
# the imperatively generated meta.nix. See README.md for more information.

{ config, lib, pkgs, ... }:

let
  # meta.nix provides hostName and productName
  meta = import ./meta.nix;
in

{
  imports = [
    # TODO: Find cleaner way to specify these
    # Include host-specific configuration
    (
      let
        hostConfigNix = (./. + "/${meta.hostName}-config.nix");
      in
      if (builtins.pathExists hostConfigNix) then
        hostConfigNix
      else
        ./genericHost.nix
    )

    # Include hardware-specific configuration
    (
      let
        productNix = (./. + "/${meta.productName}.nix");
      in
      if (builtins.pathExists productNix) then
        productNix
      else
        /etc/nixos/hardware-configuration.nix
    )
  ] ++ (
    # Include host-specific storage configuration
    let
      hostStorageNix = (./. + "/${meta.hostName}-storage.nix");
    in
    lib.optional (builtins.pathExists hostStorageNix) hostStorageNix
  );

  networking.hostName = meta.hostName;
  # The hostId is set to the crc32 of the hostName in hex
  # TODO clean up this beauty
  networking.hostId =
    builtins.readFile (
      pkgs.runCommand "mkHostId" {} ''
      printf '%X' $(printf "${meta.hostName}" | cksum | cut -d \  -f1) > $out
      ''
    );

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.consoleKeyMap = "us";

  time.timeZone = "Europe/Berlin";

  # Looks very similar the default console font and uni-vga though not 100%
  # TODO: Find out what the actual console font is and use that instead
  i18n.consoleFont = "cp1250";

  # Unstable channel pkgs override; e.g. pkgs.unstable.firefox
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      # pass the nixpkgs config to the unstable alias
      # to ensure `allowUnfree` is propagated:
      config = config.nixpkgs.config;
    };
  };
  nixpkgs.config.allowUnfree = true; # required for Steam

  # The Steam client needs 32bit libraries
  # TODO only enable these if Steam is enabled
  hardware.pulseaudio.support32Bit = true;
  hardware.opengl.driSupport32Bit = true;

  # List of packages installed in system profile.
  # If the host config enables X, X packages are also imported
  environment.systemPackages = with import ./systemPackages.nix pkgs;
                               common ++ (if config.services.xserver.enable then x else noX);

  programs.screen.screenrc = "startup_message off";

  services.xserver.libinput.accelProfile = "flat";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" ];
    shell = pkgs.bash;
  };
}
