# Běžné aplikace
{ pkgs, ... }: {
  programs.firefox.enable = true;
  programs.obs-studio.enable = true;   # nahrávání a streamování obrazovky

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    signal-desktop
    spotify
    discord
    vlc
    libreoffice-qt6-fresh   # Qt verze ladí s KDE Plasma
    hunspell
    hunspellDicts.cs_CZ     # česká kontrola pravopisu v LibreOffice
  ];
}
