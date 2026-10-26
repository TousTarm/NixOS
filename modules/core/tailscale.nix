# Tailscale VPN. Po prvním rebuildu jednou přihlásit: sudo tailscale up
{ ... }: {
  services.tailscale = {
    enable = true;
    openFirewall = true;  # otevře UDP port pro přímé spojení mezi zařízeními (jinak jde přes relay)
    # nic z tailnetu se k tomuhle stroji nepřipojí (odchozí spojení fungují dál)
    # a stroj nikomu nezpřístupní žádnou síť (žádné subnet routy, exit node ani Tailscale SSH)
    extraSetFlags = [ "--shields-up=true" "--advertise-routes=" "--advertise-exit-node=false" "--ssh=false" ];
  };
  networking.firewall.checkReversePath = "loose";  # jinak firewall může zahazovat pakety z Tailscale
}
