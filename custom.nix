{ lib, config, pkgs, ... }:

with lib;

let
  self = config.custom;
in

{
  options.custom = {
    hostName = mkOption {
      description = "The name of the host whose config to build.";
      default = "HEPHAISTOS";
      example = "PLATON";
      type = types.str;
    };

    withPackages = mkOption {
      description = "Whether to include system packages.";
      default = true;
      example = false;
      type = types.bool;
      # FIXME implemented in packages.nix for now
    };

    emacs = mkOption {
      description = "Emacs package to use.";
      default = let
        emacs-overlay = import <emacs-overlay> pkgs pkgs;
        package = if (builtins.tryEval emacs-overlay).success
                  then emacs-overlay.emacsGcc
                  else warn "emacs-overlay not in NIX_PATH! Falling back to regular emacs..." pkgs.emacs;
      in package.override { withGTK3 = false; }; # gtk crashes daemon when X server is stopped
      example = pkgs.emacs-nox;
      type = types.package;
      # implemented in packages.nix and desktop.nix
    };
  };

  config = {
    networking.hostName = self.hostName;

    # The hostId is set to the first 8 chars of the sha256 of the hostName
    networking.hostId = substring 0 8 (builtins.hashString "sha256" self.hostName);
  };
}
