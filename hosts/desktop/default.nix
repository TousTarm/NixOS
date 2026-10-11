# Desktop: věci specifické pro tenhle konkrétní počítač (hardware, bootloader, GPU)
# a výběr modulů, které na něm chceme.
{ ... }: {
  imports = [
    ./hardware-configuration.nix   # generuje nixos-generate-config, needitovat
    ../../modules/core             # základ pro všechny počítače
    ../../modules/plasma.nix
    ../../modules/apps.nix
    ../../modules/personal.nix
    ../../modules/gaming.nix
    ../../modules/dev.nix
    ../../modules/ai.nix
    ../../modules/school.nix
  ];

  networking.hostName = "nixos";  # změna na "desktop" (8. 10.) se kryla s problémy při přihlášení, proto zpět

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;  # max 5 generací NixOS v menu
  boot.loader.systemd-boot.consoleMode = "max";     # nejvyšší rozlišení menu, které firmware nabídne
  boot.loader.efi.canTouchEfiVariables = true;

  # GPU: RTX 3080 Ti
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = { enable = true; enable32Bit = true; };
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # při uspání uloží VRAM, bez toho se PC z uspání neprobudí
  };

  # fwupd steelseries plugin každých 20 s odpojuje Arctis Nova 5 -> na stejném USB řadiči
  # pak cuká kurzor a ztrácí se kliky myši.
  services.fwupd.daemonSettings.DisabledPlugins = [ "steelseries" ];

  # Verze NixOS, na které byl systém PŮVODNĚ nainstalován. Neměnit ani při upgradu!
  system.stateVersion = "26.05";
}
