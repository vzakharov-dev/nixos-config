{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # TUI файловые менеджеры
    superfile
    yazi

    # Modern CLI (Rust replacements)
    eza bat fd ripgrep fzf zoxide
    jq yq tldr duf dust procs

    # Git TUI
    lazygit

    # Мониторинг
    btop
  ];

  # Starship промпт — через programs, не packages
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
    };
  };

  # zoxide через programs
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  # fzf через programs
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };
}
