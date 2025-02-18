{ pkgs, config, lib, ... }:

with pkgs;

let
  # Packages to always install.
  common = [
    acpi
    aespipe
    bash-completion
    bc
    bind
    borgbackup
    brightnessctl
    btop
    btrfs-progs
    cifs-utils
    compsize
    cryptsetup
    curl
    ddrescue
    diceware
    dos2unix
    f2fs-tools
    fd
    file
    git
    gnupg
    hdparm
    iftop
    iotop
    iperf
    iw
    jq
    killall
    libarchive
    lm_sensors
    lsof
    lsscsi
    lz4
    man-pages
    mediainfo
    modemmanager
    mosh
    ncdu
    neofetch
    netcat-gnu
    nix-bash-completions
    nix-index
    nix-top
    nixpkgs-fmt
    nixpkgs-review
    nmap
    ntfs3g
    p7zip
    pciutils
    protonvpn-cli
    pstree
    pv
    ranger
    ripgrep
    rsync
    screen
    smartmontools
    sshfs
    stress
    sysstat
    tigervnc
    traceroute
    tree
    unzip
    usbutils
    vim
    wget
    which
    whois
    wol
    youtube-dl
    zip
    zstd
  ]
  ++ (with config.boot.kernelPackages; [
    cpupower
    perf
  ])
  ++ lib.optionals (stdenv.targetPlatform.isx86) [
    ffmpeg-full
    haskellPackages.git-annex
    shellcheck
  ]
  ++ lib.optionals (stdenv.targetPlatform.isAarch32) [
    ffmpeg
  ];

  # Packages to install if X is not enabled.
  noX = [
    emacs-nox # FIXME this needs to be handled in custom.emacs
    rxvt_unicode.terminfo
  ];

  # Packages to install if X is enabled.
  x = [
    android-studio
    anki-bin
    chromium
    config.custom.emacs
    direnv
    discord
    element-desktop
    firefox-bin
    gimp
    gnome3.adwaita-icon-theme # fix lutris' missing icons
    goverlay
    jetbrains.clion
    jetbrains.idea-community
    libreoffice
    lutris
    lxrandr
    mangohud
    mlterm
    mozlz4a
    mpv
    pavucontrol
    piper
    pulseaudio # For pactl when pipewire is enabled
    python3
    rxvt_unicode
    signal-desktop
    spotify
    steam
    steam-run
    teamspeak_client
    torbrowser
    virt-manager
    vlc
    wineWowPackages.staging
    xclip
    xorg.xev
  ];
in
{
  nixpkgs.config.allowUnfree = true; # :(

  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      config = config.nixpkgs.config; # propagate `allowUnfree`
    };
    stable = import <nixos-stable> {
      config = config.nixpkgs.config; # propagate `allowUnfree`
    };
  };

  # List of packages installed in system profile.
  environment.systemPackages = lib.mkIf config.custom.withPackages (
    # If the host config enables X, X packages are also imported
    common ++ (if config.custom.desktop.enable then x else noX)
  );
}
