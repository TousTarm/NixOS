# Grafické prostředí (KDE Plasma 6), zvuk, síť, tisk
{ ... }: {
  services.xserver.enable = true;  # X11 (Plasma běží na Waylandu, tohle je kvůli X11 session/kompatibilitě)
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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
