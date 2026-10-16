# Tailscale VPN. Po prvním rebuildu jednou přihlásit: sudo tailscale up
{ ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;  # otevře UDP port pro přímé spojení mezi zařízeními (jinak jde přes relay)
    extraSetFlags = [ "--shields-up=true" "--advertise-routes=" "--advertise-exit-node=false" "--ssh=false" ];
  };
  networking.firewall.checkReversePath = "loose";  # jinak firewall může zahazovat pakety z Tailscale
}
