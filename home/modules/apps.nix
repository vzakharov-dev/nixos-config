{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Browsers
    firefox
    vivaldi

    # Notes / Knowledge
    obsidian
    logseq

    # mail_manager
    thunderbird

    # Media
    mpv
    pavucontrol

    # Other GUI
    networkmanagerapplet
  ];
}
