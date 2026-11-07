# PC2: i7-12700K + RTX 3060 Ti, Windows na druhém disku.
# Věci specifické pro tenhle konkrétní počítač (hardware, bootloader, GPU) a výběr modulů.
{ inputs, ... }: {
  imports = [
    ./hardware-configuration.nix   # generuje nixos-generate-config, needitovat
    ../../modules/core             # základ pro všechny počítače
    ../../modules/plasma.nix
    ../../modules/apps.nix
    ../../modules/personal.nix
    ../../modules/gaming.nix
    ../../modules/dev.nix
    ../../modules/android.nix
    ../../modules/ai.nix
    ../../modules/school.nix
    inputs.work.nixosModules.default  # soukromá část (TousTarm/nixos-work)
  ];

  networking.hostName = "nixos";  # hostname je na všech počítačích stejný, rozlišuje je jméno configu

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;  # max 5 generací NixOS v menu
  boot.loader.systemd-boot.consoleMode = "max";     # nejvyšší rozlišení menu, které firmware nabídne
  boot.loader.efi.canTouchEfiVariables = true;

  # Windows je na druhém disku s vlastním EFI oddílem, systemd-boot ho sám nenajde.
  # Položka v menu ho spustí přes EFI Shell. Kdyby nefungovala, vyber v menu "EFI Shell",
  # spusť `map -c` a pak `ls FS0:\EFI`, `ls FS1:\EFI`, ... Kde je složka Microsoft,
  # to FSx napiš sem. (Zapojený USB flash disk může čísla posunout.)
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.windows."11" = {
    title = "Windows";
    efiDeviceHandle = "FS0";
  };

  # GPU: RTX 3060 Ti (monitory jsou zapojené do ní, integrovaná Intel grafika se nepoužívá)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = { enable = true; enable32Bit = true; };
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;  # při uspání uloží VRAM, bez toho se PC z uspání neprobudí
  };

  # Stejná sluchátka jako na desktopu: fwupd steelseries plugin každých 20 s odpojuje
  # Arctis Nova 5 -> na stejném USB řadiči pak cuká kurzor a ztrácí se kliky myši.
  services.fwupd.daemonSettings.DisabledPlugins = [ "steelseries" ];

  # Verze NixOS, na které byl systém PŮVODNĚ nainstalován. Neměnit ani při upgradu!
  system.stateVersion = "26.05";
}
