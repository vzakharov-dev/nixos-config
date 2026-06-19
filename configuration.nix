{ config, pkgs, inputs, ... }:

{
  # =====================================================================
  # ИМПОРТЫ
  # =====================================================================
  imports = [
  # mutableUsers = true (КРИТИЧНО): passwd работает, пароль не сбрасывается
  # при каждом nixos-rebuild.
    # hardware-configuration.nix НЕ в репозитории.
    # Этот файл уникален для вашего железа, сгенерирован nixos-generate-config.
    ./hardware-configuration.nix
  ];

  # =====================================================================
  # Разрешить insecure пакеты
  # ===================================================================== 
  nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];
    
  # =====================================================================
  # NIX: включаем flakes и оптимизации
  #  =====================================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "vzakharov-dev" ];

    substituters = [
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  nix.gc = {
     automatic = true;
     dates = "weekly";
     options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # =====================================================================
  # ЗАГРУЗЧИК
  # =====================================================================
  boot.loader.systemd-boot = {
    enable = true;

    configurationLimit = 20;
    # ⚠️ ВРЕМЕННО: разрешаем редактирование boot params для аварийного входа
    # (нужно для init=/bin/sh при сбросе пароля).
    # После того как всё работает — поставьте editor = false для безопасности.
    editor = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.consoleLogLevel = 4;  #видимые логи на этапе отладки

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  #  ALLIASSEEESS
  programs.bash.shellAliases = {
    run = "appimage-run ~/Applications/";
  };

  # =====================================================================
  # ЛОКАЛИЗАЦИЯ
  # =====================================================================
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
  };

  # ⚠️ КРИТИЧНО ДЛЯ ВХОДА: всегда US-раскладка на TTY и экране логина.
  console.keyMap = "ru";
  
  # СЕТЬ
  # =====================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  services.resolved.enable = false;
  networking.firewall.enable = true;

  # =====================================================================
  # ПОЛЬЗОВАТЕЛЬ
  # =====================================================================
  users.mutableUsers = true;

  users.users.vzakharov-dev = {
    isNormalUser = true;
    description = "vzakharov-dev";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    shell = pkgs.bash;

    initialPassword = "nixos";
  };

  users.users.root.initialPassword = "rootnixos";

  # =====================================================================
  # SUDO
  # =====================================================================
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    execWheelOnly = true;
    extraConfig = ''
      Defaults timestamp_timeout=15
      Defaults lecture=once
    '';
  };

  # =====================================================================
  # АВАРИЙНЫЙ ВХОД через TTY3 — автологин под vzakharov-dev без пароля
  # =====================================================================
  systemd.services."getty@tty3" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = [
      ""
      "@${pkgs.util-linux}/sbin/agetty agetty --autologin vzakharov-dev --noclear %I $TERM"
    ];
  };

  # =====================================================================
  # НАСТРОЙКИ ДЛЯ ЗАПУСКА БИНАРНИКОВ И APPIMAGE
  # =====================================================================
  programs.nix-ld = {
    enable = true;

  libraries = with pkgs; [
      # Базовые библиотеки
      stdenv.cc.cc
      zlib
      # GUI
      xorg.libX11      # AppImage / FUSE
      fuse
      fuse3
    ];
 };

  programs.appimage = {
      enable = true;
      binfmt = true; # Это заставит ядро Linux автоматически открывать AppImage
};

  # =====================================================================
  # СИСТЕМНЫЕ ПАКЕТЫ
  # =====================================================================
   environment.systemPackages = with pkgs; [
      vim micro curl wget
      pciutils usbutils
      util-linux file tree
      inetutils mkpasswd
      appimage-run
      git
    ];
  
   services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };

  # ШРИФТЫ
  # =====================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
   
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code 
      nerd-fonts.symbols-only
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  # =====================================================================
  # SSH
  # =====================================================================
  services.openssh = {
    enable = true;
    
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    
    openFirewall = true;
  };

  # Настройка раскрадки	
  services.xserver = {
    enable = true;

    xkb.layout = "us,ua,ru";
    xkb.variant = ",,";
    xkb.options = "grp:alt_shift_toggle,terminate:ctrl_alt_bksp";
  };


  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-uuid/2AAC4ED5EDCCB9DD";
    fsType = "ntfs3";
    options = [ "defaults" "nofail" "uid=1000" "gid=100"];
  };
    
  # =====================================================================
    system.stateVersion = "25.11";
}
