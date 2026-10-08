{ ... }: {
  boot.loader.systemd-boot.configurationLimit = 5;  # max 5 generací NixOS v menu
  boot.loader.systemd-boot.consoleMode = "max";     # nejvyšší rozlišení menu, které firmware nabídne
}
