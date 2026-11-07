# Grafické prostředí (KDE Plasma 6), zvuk, síť, tisk
{ ... }: {
  services.xserver.enable = true;  # X11 (Plasma běží na Waylandu, tohle je kvůli X11 session/kompatibilitě)
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Electron/Chromium aplikace (Discord, Cursor, ...) poběží nativně na Waylandu. Jinak jdou přes
  # XWayland, kde mají jedno DPI pro všechny monitory (podle 4K se scale 1.7) a na 1080p jsou obří.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  networking.networkmanager.enable = true;

  # Zvuk přes PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;
}
