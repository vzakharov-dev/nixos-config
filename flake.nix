{
  description = "Niri + Noctalia + Ghostty desktop on NixOS 25.11 (i7-7700K + GTX 1060)";

  # =====================================================================
  # INPUTS: внешние источники, версии которых фиксируются в flake.lock
  # =====================================================================
  inputs = {
    # Основной канал — стабильная ветка NixOS 25.11
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable — на случай если нужен пакет свежее, чем в стабильном
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager — управление конфигами пользователя декларативно
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quickshell — обязательная зависимость Noctalia (Qt6/QML фреймворк)
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Shell — desktop shell для Wayland-композиторов
    # ВАЖНО: programs.noctalia-shell живёт ТОЛЬКО здесь, не в nixpkgs
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };
  };

  # =====================================================================
  # OUTPUTS: что flake "производит" — здесь nixosConfigurations
  # =====================================================================
  outputs = inputs@{ self, nixpkgs, home-manager, noctalia, ... }:
    let
      system = "x86_64-linux";
    in {
      # Имя "nixos" должно совпадать с networking.hostName в configuration.nix
      # Применяется командой: sudo nixos-rebuild switch --flake /etc/nixos#nixos
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        # Пробрасываем inputs во все модули, чтобы они могли использовать
        # inputs.noctalia.packages.${system}.default и т.п.
        specialArgs = { inherit inputs; };

        modules = [
          # ====== Системные модули ======
          ./configuration.nix
          ./modules/nvidia.nix
          ./modules/desktop.nix
          # ./modules/mullvad.nix

          # ====== Home Manager как NixOS-модуль ======
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              # Использовать ТОТ ЖЕ pkgs, что и система — экономит место
              useGlobalPkgs = true;
              # Пакеты в home.packages устанавливать через users.users.<n>
              useUserPackages = true;
              # Пробросить inputs внутрь home.nix
              extraSpecialArgs = { inherit inputs; };
              # Конфиг пользователя
              users.vzakharov-dev = import ./home/vzakharov-dev.nix;
              # Если в $HOME уже есть конфликтующий файл — переименовать
              # с расширением .hm-backup вместо падения сборки
              backupFileExtension = "hm-backup";
            };
          }
        ];
      };
    };
}
