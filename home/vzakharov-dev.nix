{ config, pkgs, inputs, ... }:

{
  # =====================================================================
  # ИМПОРТЫ HOME-MANAGER МОДУЛЕЙ
  # =====================================================================
  imports = [
    # programs.noctalia-shell живёт ТОЛЬКО в этом модуле, не в nixpkgs
    inputs.noctalia.homeModules.default
    ./modules/cli-tools.nix
    ./modules/de-stack.nix
    ./modules/apps.nix
    ./modules/wayland.nix    
  ];

  # =====================================================================
  # ИДЕНТИФИКАЦИЯ
  # =====================================================================
  home.username = "vzakharov-dev";
  home.homeDirectory = "/home/vzakharov-dev";

  # Home Manager state version — ТОЛЬКО для home-manager, отдельно от system
  home.stateVersion = "25.11";

  # =====================================================================
  # ПОЛЬЗОВАТЕЛЬСКИЕ ПАКЕТЫ
  # =====================================================================
  
  # =====================================================================
  # GHOSTTY: быстрый GPU-accelerated терминал
  # =====================================================================
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;
      theme = "Gruvbox Dark Hard";
      background-opacity = 0.95;
      background-blur-radius = 20;
      window-decoration = false;
      cursor-style = "block"; 
      cursor-style-blink = false;
      shell-integration = "bash";
      copy-on-select = true;
      mouse-hide-while-typing = true;
      window-padding-x = 8;
      window-padding-y = 8;
      confirm-close-surface = false;
    };
  };

  # =====================================================================
  # NEOVIM
  # =====================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;       # $EDITOR=nvim глобально
    viAlias = true;             # `vi` → nvim
    vimAlias = true;            # `vim` → nvim
    withNodeJs = true;          # для LSP-серверов
    withPython3 = true;

    extraConfig = ''
      " ===== Базовые настройки =====
      set number relativenumber
      set tabstop=2 shiftwidth=2 expandtab smartindent
      set termguicolors
      set clipboard+=unnamedplus
      set ignorecase smartcase
      set scrolloff=8
      set signcolumn=yes
      set updatetime=50
      set undofile
      set noswapfile nobackup
      set mouse=a

      syntax on
      filetype plugin indent on

      " ===== Тема =====
      colorscheme gruvbox

      " ===== Маппинги =====
      let mapleader = " "
      nnoremap <leader>e :Ex<CR>
      nnoremap <leader>w :w<CR>
      nnoremap <leader>q :q<CR>
    '';

    plugins = with pkgs.vimPlugins; [
      # Подсветка синтаксиса для всех языков
      nvim-treesitter.withAllGrammars

      # Fuzzy finder
      telescope-nvim
      plenary-nvim

      # Тема
      gruvbox-nvim

      # LSP
      nvim-lspconfig

      # Автодополнение
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path

      # Git
      vim-fugitive
      gitsigns-nvim

      # Утилиты
      vim-commentary
      vim-surround
    ];
  };

  # =====================================================================
  # NOCTALIA SHELL — конфиг через Home Manager
  # =====================================================================
  programs.noctalia-shell = {
    enable = true;

    # Полная схема настроек: https://docs.noctalia.dev
    # Здесь — базовый рабочий минимум, расширяйте под себя
    settings = {
      bar = {
        position = "top";
        backgroundOpacity = 0.9;
      };
    };
  };

  # =====================================================================
  # NIRI: конфигурация компостера
  # =====================================================================
  # Niri читает $XDG_CONFIG_HOME/niri/config.kdl
  # Создаём файл через xdg.configFile — Home Manager сделает symlink
  xdg.configFile."niri/config.kdl".text = ''
    // ============================================================
    // NIRI CONFIG — для i7-7700K + GTX 1060 + Asus VG229 (1920x1080)
    // Документация: https://github.com/YaLTeR/niri/wiki
    // ============================================================

    input {
        keyboard {
            xkb {
                layout "us,ru,ua"
                options "grp:alt_shift_toggle,caps:escape"
            }
            repeat-delay 300
            repeat-rate 30
        }

        mouse {
            accel-profile "flat"
        }
        // Отключаем фокус по наведению мыши
    }
}

    // ============================================================
    // ВЫХОДЫ (мониторы) — ASUS VX229 через HDMI
    //
    // Подтверждено: монитор подключён по HDMI к GTX 1060.
    // На Linux это будет HDMI-A-1 (или HDMI-A-2 если второй порт).
    // Узнать точное имя после первого запуска: niri msg outputs
    //
    // VX229 официально 60 Hz, но успешно гонится до 74 Hz через
    // Custom Resolution в NVIDIA Control Panel на Windows.
    // На Linux Niri умеет принимать кастомные modeline-строки.
    //
    // СТРАТЕГИЯ:
    // 1. По умолчанию используем стабильные 60 Hz (точно работает).
    // 2. После того как система загрузится, попробуем 74 Hz.
    // 3. Если 74 Hz даст чёрный экран — Niri автоматически
    //    откатится на 60 Hz из EDID монитора.
    // ============================================================

    output "HDMI-A-1" {
        // Безопасный режим — раскомментирован по умолчанию
        mode "1920x1080@60.000"

        // ⚡ Разгон до 74 Hz (как в Windows).
        // Чтобы включить: закомментируйте 60 Hz выше и раскомментируйте строку ниже.
        // ВАЖНО: сначала проверьте, что modeline валиден (см. инструкции под конфигом).
        // mode "1920x1080@74.000"

        position x=0 y=0
        scale 1.0

        // VX229 — IPS-матрица без FreeSync/G-Sync,
        // VRR отключён (не поддерживается монитором).
    }

    // Дублирующие выходы на случай если HDMI определится как HDMI-A-2
    output "HDMI-A-2" {
        mode "1920x1080@60.000"
        position x=0 y=0
        scale 1.0
    }

    // Если когда-нибудь подключите по DisplayPort:
    output "DP-1" {
        mode "1920x1080@60.000"
        position x=0 y=0
        scale 1.0
    }

    // ============================================================
    // LAYOUT
    // ============================================================
    layout {
        gaps 8
        center-focused-column "never"
        background-color "transparent"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
            proportion 1.0
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#7fc8ff"
            inactive-color "#505050"
        }

        border {
            off
        }
    }

    // ============================================================
    // АВТОСТАРТ
    // ============================================================
    spawn-at-startup "noctalia-shell"
    spawn-at-startup "xwayland-satellite"
    spawn-at-startup "nm-applet" "--indicator"

    // Скриншоты
    screenshot-path "~/Pictures/Screenshots/Screenshot-%Y-%m-%d-%H-%M-%S.png"

    // ============================================================
    // ХОТКЕИ
    // Mod = Super (Windows-клавиша)
    // ============================================================
    binds {
        // ----- Приложения -----
        Mod+T       hotkey-overlay-title="Terminal" { spawn "ghostty"; }
        Mod+E       hotkey-overlay-title="File Manager" { spawn "ghostty" "-e" "superfile"; }
        Mod+B       hotkey-overlay-title="Browser" { spawn "firefox"; }
        Mod+Shift+B hotkey-overlay-title="Nyxt" { spawn "nyxt"; }
        Mod+D       hotkey-overlay-title="Launcher" { spawn "fuzzel"; }
        Mod+N       hotkey-overlay-title="Editor" { spawn "ghostty" "-e" "nvim"; }

        // ----- Управление окнами -----
        Mod+Q       { close-window; }
        Mod+Shift+Q { quit; }

        // ----- Фокус -----
        Mod+Left   { focus-column-left; }
        Mod+Right  { focus-column-right; }
        Mod+Up     { focus-window-up; }
        Mod+Down   { focus-window-down; }
        Mod+H      { focus-column-left; }
        Mod+L      { focus-column-right; }
        Mod+K      { focus-window-up; }
        Mod+J      { focus-window-down; }

        // ----- Перемещение окон -----
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Down  { move-window-down; }

        // ----- Рабочие столы -----
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }

        // ----- Размер колонок -----
        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // ----- Громкость / яркость -----
        Mod+Page_Up { spawn "pamixer" "-i" "15"; }
        Mod+Page_Down { spawn "pamixer" "-d" "15"; }
        XF86AudioMute { spawn "pamixer" "-t"; }
        XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }

        // ----- Скриншоты -----
        Print { screenshot; }
        Mod+Print { screenshot-screen; }
        Mod+Shift+S { screenshot; }
    }
  '';

  # =====================================================================
  # SUPERFILE
  # =====================================================================
  # Superfile требует ЗАПИСЫВАЕМУЮ директорию ~/.config/superfile/
  # Если использовать xdg.configFile — будет symlink в read-only /nix/store,
  # и Superfile упадёт при попытке сохранить настройки.
  # Решение: создать ПУСТУЮ директорию, Superfile сам напишет туда конфиг.
  home.activation.superfileSetup = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/superfile"
  '';

  # =====================================================================
  # BASH
  # =====================================================================
  programs.bash = {
    enable = true;

    shellAliases = {
      # Современные replacements для классических команд
      ls = "eza --icons";
      ll = "eza -la --icons --git";
      la = "eza -a --icons";
      lt = "eza --tree --icons";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # Полезные
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      rebuild-test = "sudo nixos-rebuild test --flake /etc/nixos#nixos";
      gc = "sudo nix-collect-garbage -d";
      gens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";

      # Git shortcuts
      g = "git";
      gs = "git status";
      gl = "git log --oneline --graph";
      gd = "git diff";
    };

    initExtra = ''
      # zoxide — умный cd с историей. Используйте: z <часть-пути>
      eval "$(zoxide init bash)"

      # fzf — Ctrl+R для поиска по истории, Ctrl+T для файлов
      if [ -n "$BASH_VERSION" ]; then
        source ${pkgs.fzf}/share/fzf/key-bindings.bash
        source ${pkgs.fzf}/share/fzf/completion.bash
      fi

      # Цветной prompt уже от starship
    '';
  };


  # # =====================================================================
  # GIT
  # =====================================================================
  programs.git = {
    enable = true;
    settings = {
      user.name = "Your Name";
      user.email = "you@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      push.autoSetupRemote = true;
    };
  };
 
  # =====================================================================
  # LET HOME MANAGER MANAGE ITSELF
  # =====================================================================
  programs.home-manager.enable = true;
}
