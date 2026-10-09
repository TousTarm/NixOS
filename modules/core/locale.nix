# Jazyk, časová zóna, klávesnice
{ ... }: {
  time.timeZone = "Europe/Prague";

  i18n.defaultLocale = "en_US.UTF-8";  # systém anglicky
  i18n.extraLocaleSettings = {         # ale formáty (datum, měna, ...) české
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  services.xserver.xkb = { layout = "cz"; variant = "winkeys"; };
  console.keyMap = "cz-lat2";
}
