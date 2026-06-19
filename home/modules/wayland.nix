{pkgs, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    grim slurp
    swappy
    brightnessctl
    playerctl
    pamixer
    fuzzel
    swaybg
    swayidle
    swaylock
   ];
} 

