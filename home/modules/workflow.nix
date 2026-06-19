{ pkgs, ... }:

{
  home.file.".local/bin/rebuild" = {
    executable = true;
    text = ''
      #!/bin/bash
      set -e
      cd /etc/nixos

      CURRENT=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
      echo "📌 Текущая генерация: $CURRENT"

      echo "🔍 Проверяю синтаксис..."
      sudo nix flake check . || { echo "❌ Ошибка синтаксиса"; exit 1; }

      echo "🧪 Пробная сборка..."
      sudo nixos-rebuild dry-build --flake /etc/nixos#nixos || { echo "❌ Ошибка сборки"; exit 1; }

      echo ""
      echo "Выбери:"
      echo "  1) test   — безопасно (откатится при reboot)"
      echo "  2) switch — постоянно"
      echo "  3) отмена"
      read -p ">>> " choice

      case $choice in
        1) sudo nixos-rebuild test --flake /etc/nixos#nixos ;;
        2) sudo nixos-rebuild switch --flake /etc/nixos#nixos ;;
        3) echo "Отменено"; exit 0 ;;
      esac

      echo ""
      echo "📦 Сохраняю в Git..."
      sudo git add -A
      sudo git commit -m "rebuild: $(date +%Y-%m-%d_%H:%M)" 2>/dev/null || echo "Нечего коммитить"
      sudo GIT_SSH_COMMAND="ssh -i /home/vzakharov-dev/.ssh/id_ed25519" git push 2>/dev/null || echo "⚠️ Push не удался"

      echo "✅ Готово!"
    '';
  };
}
