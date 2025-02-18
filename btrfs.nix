{ config, lib, ... }:

with lib;

let
  cfg = config.custom.btrfs;
in

{
  options.custom.btrfs = {
    # TODO Make this a submodule like all the others that serves as the default for them
    default = {
      device = mkOption {
        description = ''
          The default device to use if none is declared.
        '';
        default = lib.warn "No `custom.btrfs.default.device` declared, proceed with caution!" null;
        defaultText = ''
          The device specified in `custom.custom.fs.btrfs.device`

          This allows for easily extending the defaults without having to re-specify the main device every time
        '';
      };

      options = mkOption {
        description = ''
          The mount options to use if none are declared.
        '';
        default = [ ];
      };
    };

    fileSystems = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          device = mkOption {
            description = ''
              The device to mount
            '';
            default = cfg.defaults.device;
            defaultText = ''
              The device declared in `custom.btrfs.default.device`

              This allows for easily extending custom generic defaults without having to declare the same main device every time
            '';
          };

          compress = {
            # TODO Make this on by default
            enable = mkOption {
              description = ''
                Whether to enabe btrfs filesystem compression
              '';
              default = true;
            };

            algorithm = mkOption {
              description = ''
                The compression algorith to use
              '';
              default = "zstd";
            };

            level = mkOption {
              description = ''
                The compression level to use
              '';
              default = 1;
            };

            force = mkOption {
              description = ''
                Whether to force compression or leave btrfs to decide what's compressible and what isn't
              '';
              default = true;
            };
          };

          subvol = mkOption {
            description = ''
              Subvolume to mount. Null means default subvol
            '';
            default = null;
          };
          options = mkOption {
            description = ''
              Mount options too add on
            '';
            default = cfg.default.options;
          };
        };
      });
      default = { };
      example = literalExample ''
        {
          "/data" = {
            device = "/dev/disk/by-id/ata-foo";
            subvolume = "data";
            compress.level = 10;
            extraOptions = [ "autodefrag" ];
          };
          "/home" = {
            device = "/dev/disk/by-id/ata-foo";
            subvolume = "home";
            compress = {
              force = false;
              level = 2;
            };
          };
        };
      '';
      description = ''
        Btrfs fileSystems, declared similar to NixOS' `fileSystems`.
      '';
    };
  };

  config.fileSystems = mapAttrs (_: fileSystem: {
    fsType = "btrfs";

    inherit (fileSystem) device;

    options = with fileSystem; let
      compressArg = with compress;
        optional enable "compress${optionalString force "-force"}=${algorithm + optionalString (level != null) ":${toString level}"}";
      subvolArg = optional (subvol != null) "subvol=${subvol}";
    in compressArg ++ subvolArg ++ fileSystem.options;
  }) cfg.fileSystems;
}
