{ config, pkgs, inputs, ... }:

{
  # =====================================================================
  # NIRI: scrollable-tiling Wayland compositor
  # =====================================================================
  # Включаем системный модуль niri из nixpkgs.
  # Альтернатива — sodiboo/niri-flake для самой свежей версии и
  # декларативной настройки через wayland.windowManager.niri.settings
  # в Home Manager. Пока используем простой путь.
  programs.niri.enable = true;

  # =====================================================================
  # DISPLAY MANAGER: greetd + tuigreet
  # =====================================================================
  # Почему greetd, а НЕ GDM/SDDM:
  # - На NVIDIA + Niri в gdm/sddm часто чёрный экран после логина.
  # - tuigreet работает на TTY-уровне до запуска композитора — стабильно.
  # - Минимум памяти, нет лишних зависимостей.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # NixOS внедряет урезанный PATH в niri.service — переопределяем,
  # чтобы пользовательский PATH (из ~/.profile, и т.п.) был доступен
  systemd.user.services.niri.enableDefaultPath = false;

  # =====================================================================
  # XWAYLAND: для X11-приложений
  # =====================================================================
  # Niri (в отличие от Sway/Hyprland) НЕ имеет встроенного XWayland.
  # Нужно запускать xwayland-satellite как user-service отдельно.
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  # xwayland-satellite запускается автоматически при старте Niri-сессии
  systemd.user.services.xwayland-satellite = {
    description = "Xwayland outside your Wayland (for Niri)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # DISPLAY=:0 — чтобы X11-приложения знали, к какому satellite подключаться
  environment.sessionVariables.DISPLAY = ":0";

  # =====================================================================
  # XDG PORTALS: file picker, screencast, скриншоты
  # =====================================================================
  # Без порталов:
  # - Не работает Open File... в Firefox/Chrome/etc.
  # - Не работает Screen Share в Zoom/Discord/Meet.
  # - Не работают системные скриншоты.
  xdg.portal = {
    enable = true;

    # xdg-desktop-portal-gtk — file picker (легковесный, для всех приложений)
    # xdg-desktop-portal-gnome — screencast (для screen share)
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    config = {
      niri = {
        default = [ "gnome" "gtk" ];
        # File chooser через GTK — стабильнее, чем GNOME (нужен Nautilus)
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      common.default = [ "gtk" ];
    };
  };

  # =====================================================================
  # АУДИО: PipeWire (современный стандарт)
  # =====================================================================
  services.pulseaudio.enable = false;  # ОТКЛЮЧАЕМ legacy pulseaudio

  security.rtkit.enable = true;  # rtkit нужен PipeWire для realtime приоритета

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;      # совместимость с PulseAudio-приложениями
    jack.enable = true;       # совместимость с JACK (аудио-софт)
    wireplumber.enable = true;
  };

  # =====================================================================
  # POLKIT + KEYRING (без них не работают системные диалоги)
  # =====================================================================
  security.polkit.enable = true;

  # gnome-keyring — хранилище паролей, нужен Firefox/Chrome/git
  services.gnome.gnome-keyring.enable = true;

  # PAM-интеграция: keyring разблокируется автоматически при логине
  security.pam.services.greetd.enableGnomeKeyring = true;

  # PAM-сессия для Noctalia lock screen (документация Noctalia требует)
  security.pam.services.noctalia-lock = {};

  # =====================================================================
  # GTK / DCONF
  # =====================================================================
  # dconf — backend настроек для GTK-приложений (без него теряются темы)
  programs.dconf.enable = true;

  # =====================================================================
  # BLUETOOTH (опционально — закомментируйте, если не нужен)
  # =====================================================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # =====================================================================
  # ПЕЧАТЬ (опционально)
  # =====================================================================
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
