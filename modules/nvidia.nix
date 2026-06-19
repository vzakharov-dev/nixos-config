{ config, pkgs, ... }:

{
  # =====================================================================
  # NVIDIA для GTX 1060 (Pascal) + Wayland (Niri)
  # =====================================================================
  # Зачем: без правильной NVIDIA-настройки на Wayland будет чёрный экран,
  # курсор-лаги и невозможность использовать аппаратное ускорение.
  # GTX 1060 — это карта поколения Pascal (2016), и она требует:
  #   - проприетарный драйвер (open-source kernel module не поддерживает Pascal!)
  #   - explicit sync (драйвер 555+)
  #   - GBM, а не EGLStreams
  # =====================================================================

  # OpenGL / Vulkan / VAAPI — обязательно для любого GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # для Steam, Wine, 32-bit игр
  };

  # Регистрируем NVIDIA как video driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # КРИТИЧНО для Wayland: kernel mode setting + DRM
    modesetting.enable = true;

    # GTX 1060 = Pascal. Open-source модуль работает ТОЛЬКО на Turing+ (2018+).
    # Для Pascal обязательно проприетарный — иначе чёрный экран.
    open = false;

    # GUI-утилита nvidia-settings (можно отключить, если не нужна)
    nvidiaSettings = true;

    # Power management — для десктопа НЕ нужен (нужен только на лэптопах)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Pascal-карты используют production-ветку драйверов.
    # НЕ используйте `latest` или `beta` — на Pascal они часто ломаются.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # =====================================================================
  # Environment variables для Wayland + NVIDIA
  # =====================================================================
  environment.sessionVariables = {
    # Electron/Chrome/VSCode — нативный Wayland
    NIXOS_OZONE_WL = "1";

    # Qt-приложения предпочитают Wayland, fallback на X11
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # GBM backend — обязательно для NVIDIA + Wayland
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # На некоторых NVIDIA-картах аппаратные курсоры лагают —
    # принудительно используем софтовые (стабильнее)
    WLR_NO_HARDWARE_CURSORS = "1";

    # Mozilla apps (Firefox) — нативный Wayland
    MOZ_ENABLE_WAYLAND = "1";

    # SDL/Java/etc — Wayland первичен
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # =====================================================================
  # Параметры ядра
  # =====================================================================
  boot.kernelParams = [
    # Включить modesetting на уровне ядра (для Wayland критично)
    "nvidia_drm.modeset=1"
    # Framebuffer console через NVIDIA — boot-экран на правильном разрешении
    "nvidia_drm.fbdev=1"
  ];

  # Гарантируем, что NVIDIA-модули загружаются рано
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
}
