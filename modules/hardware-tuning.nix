{ config, pkgs, lib, ... }:

{
  # =====================================================================
  # HARDWARE TUNING — ПОДТВЕРЖДЁННОЕ железо
  # =====================================================================
  # Конфигурация для:
  #   - Материнка:  MSI MS-7A72 (чипсет Intel B250)
  #   - CPU:        Intel Core i7-7700K (Kaby Lake, Family 6 Model 158)
  #   - RAM:        32 GB DDR4
  #   - GPU:        NVIDIA GeForce GTX 1060 6GB (Pascal, GP106)
  #   - Storage:
  #       * Samsung 990 PRO 1TB NVMe Gen4 (основной, для NixOS)
  #       * Samsung 850 EVO 250GB M.2 SATA (вторичный SSD)
  #       * HGST 500GB 2.5" HDD SATA (для данных/бэкапов)
  #   - Network:
  #       * Intel I219-V Ethernet (драйвер e1000e)
  #       * Intel Wi-Fi 6 AX200 (iwlwifi)
  #   - Audio:      Realtek HDA (на материнке)
  #   - Monitor:    ASUS VX229 (1080p @ 60Hz IPS)
  #   - BIOS:       AMI v1.A0 (2018) — старый, см. примечания
  # =====================================================================

  # =====================================================================
  # CPU: Intel Kaby Lake
  # =====================================================================
  hardware.cpu.intel.updateMicrocode = true;

  # =====================================================================
  # Wi-Fi Intel AX200 + Ethernet I219-V
  # =====================================================================
  # AX200 firmware iwlwifi-cc-* содержится в linux-firmware (включено через
  # hardware.enableRedistributableFirmware = true в configuration.nix).
  # Дополнительно: AX200 может выдавать лучшую пропускную способность
  # с отключённым power_save (важно для гигабитного Wi-Fi 6).
  networking.networkmanager.wifi.powersave = false;

  # I219-V работает через драйвер e1000e — встроен в ядро, без настроек.

  # =====================================================================
  # ХРАНЕНИЕ: NVMe + SSD + HDD — разные планировщики I/O
  # =====================================================================
  # Для NVMe (Samsung 990 PRO) — `none` (NVMe сам управляет очередью,
  #   любой scheduler только замедляет).
  # Для SATA SSD (Samsung 850 EVO) — `mq-deadline` (минимальная задержка).
  # Для HDD (HGST) — `bfq` (умное планирование для вращающихся дисков).
  services.udev.extraRules = ''
    # NVMe — none
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]*", ATTR{queue/scheduler}="none"
    # SATA SSD — mq-deadline (rotational == 0 && не NVMe)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    # HDD — bfq (rotational == 1)
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  # TRIM для всех SSD (включая NVMe). Раз в неделю — оптимально.
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # =====================================================================
  # NVMe-специфичные настройки для Samsung 990 PRO
  # =====================================================================
  # 990 PRO — крайне быстрый Gen4 NVMe. Чтобы выжать максимум:
  boot.kernelParams = lib.mkAfter [
    # APST (Autonomous Power State Transitions) — иногда вызывает зависания
    # на Samsung NVMe. Отключаем для стабильности (теряем чуть-чуть энергии).
    "nvme_core.default_ps_max_latency_us=0"

    # =====================================================================
    # CUSTOM RESOLUTION 1920x1080@74Hz для ASUS VX229
    # =====================================================================
    # Чтобы NVIDIA-драйвер на Linux принял разогнанный режим 74 Hz,
    # нужно сообщить ему modeline через параметры ядра.
    # Modeline сгенерирован через `cvt 1920 1080 74`:
    #   Modeline "1920x1080_74.00" 220.50 1920 2056 2256 2592 1080 1083 1088 1147 -hsync +vsync
    # Pixel clock 220.50 MHz — в пределах HDMI 1.4 (340 MHz max),
    # значит ваш HDMI-кабель и порт должны справиться.
    #
    # ВКЛЮЧИТЬ позже, когда подтвердите что система загружается на 60 Hz.
    # Раскомментируйте параметр и раскомментируйте mode "1920x1080@74.000"
    # "video=HDMI-A-1:1920x1080@74"
  ];

  # =====================================================================
  # ZRAM (сжатая RAM-swap) — для 32 ГБ системы
  # =====================================================================
  # Используем zram вместо swap-на-диске. Преимущества:
  #   * Не изнашивает SSD
  #   * Сжатие даёт виртуально +8-12 ГБ "памяти"
  #   * zstd — лучший компромисс скорость/сжатие
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;  # до 8 ГБ сжатой памяти
    priority = 100;
  };

  # =====================================================================
  # CPU GOVERNOR — производительность для десктопа
  # =====================================================================
  # У вас десктоп (не лэптоп), и MS-7A72 на B250 — без разгона.
  # `performance` держит CPU на максимальной частоте — для игр и сборки Nix.
  # i7-7700K = 4 ядра / 8 потоков, base 4.2 GHz, boost 4.5 GHz.
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  # =====================================================================
  # ВИРТУАЛИЗАЦИЯ (опционально — раскомментируйте если нужна)
  # =====================================================================
  # i7-7700K поддерживает VT-x и VT-d.
  # virtualisation.libvirtd.enable = true;
  # programs.virt-manager.enable = true;

  # =====================================================================
  # ЗВУК: Realtek HDA на материнке
  # =====================================================================
  # MS-7A72 имеет Realtek ALC892 (или похожий). PipeWire в desktop.nix
  # справляется без специальных настроек. Опция power_save может вызывать
  # щелчки при включении звука после паузы — отключаем агрессивный режим.
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1 power_save_controller=N
  '';

  # =====================================================================
  # СЕНСОРЫ И МОНИТОРИНГ
  # =====================================================================
  # i7-7700K греется под нагрузкой (известная проблема Kaby Lake с TIM).
  # lm_sensors даёт `sensors` команду для мониторинга температуры.
  environment.systemPackages = with pkgs; [
    lm_sensors
    nvtopPackages.nvidia      # GPU мониторинг
    s-tui                     # CPU стресс/мониторинг
    smartmontools             # SMART для дисков (smartctl)
    nvme-cli                  # утилиты для NVMe
    pciutils
    usbutils
  ];

  # Регулярная проверка SMART (раз в неделю, отправка отчётов в журнал)
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.test = false;
  };

  # =====================================================================
  # BIOS 2018 (AMI v1.A0) — известные обходы
  # =====================================================================
  # 1. EFI variables overflow: systemd-boot может не успевать чистить
  #    boot-entries. configurationLimit = 20 в configuration.nix — защита.
  # 2. S3 sleep может работать криво. Не настраиваю автоматический suspend.
  # 3. Нет TPM 2.0 на этой плате — Secure Boot/lanzaboote не настраиваем.
  #
  # РЕКОМЕНДАЦИЯ: проверить наличие свежего BIOS на сайте MSI.
  # Поиск: "MSI MS-7A72 BIOS update". Если есть обновление до версии
  # выше 1.A0 — обновитесь до установки NixOS.

  # =====================================================================
  # СЕТЬ: производительность для Wi-Fi 6 и гигабитного Ethernet
  # =====================================================================
  boot.kernel.sysctl = {
    # TCP BBR — современный congestion control, лучше для гигабита
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Увеличиваем буферы для гигабитной сети
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
  };
}
