# Nastavení samotného Nixu
{ ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;  # stejné soubory ve /nix/store se ukládají jen jednou
  nixpkgs.config.allowUnfree = true;        # povolí proprietární balíčky (nvidia, steam, discord, ...)

  # nh = přívětivější nixos-rebuild: ukáže, co se změní, a umí uklízet staré generace.
  #   nh os switch     -> rebuild + přepnutí
  #   nh os boot       -> rebuild, přepne se až po restartu
  #   nh os test       -> rebuild + přepnutí, ale po restartu se vrátí zpět
  programs.nh = {
    enable = true;
    flake = "/home/toust/NixOS";
    clean.enable = true;                              # automatický úklid jednou týdně
    clean.extraArgs = "--keep-since 14d --keep 5";    # nech generace z posledních 14 dní, min. 5
  };
}
