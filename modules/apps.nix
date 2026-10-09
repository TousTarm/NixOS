# Běžné aplikace
{ pkgs, ... }: {
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    signal-desktop
    spotify
    discord
  ];
}
