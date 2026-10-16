# Vlastní příkazy a aliasy. `host` přichází z flake.nix (mkHost), takže aliasy
# na každém počítači sestaví ten správný config.
{ host, pkgs, ... }:
let
  flake = "/home/toust/NixOS";
  # natrvalo se přepíná jen na commitnutý config (viz RULES.md); zkoušet jde přes rebuild-test
  clean = ''[ -z "$(git -C ${flake} status --porcelain)" ] || { echo "~/NixOS má necommitnuté změny: vyzkoušej rebuild-test, pak commit (viz RULES.md)"; false; } &&'';
in {
  environment.shellAliases = {
    rebuild      = "${clean} nh os switch -H ${host}";        # sestav a přepni
    rebuild-boot = "${clean} nh os boot -H ${host}";          # přepni až po restartu (bezpečnější u velkých změn)
    rebuild-test = "nh os test -H ${host}";                   # vyzkoušej (i necommitnuté), po restartu zpět
    update       = "${clean} nh os switch -H ${host} --update"; # aktualizuj nixpkgs (flake.lock) + přepni
    nixcfg       = "cd ${flake}";
    generations  = "nixos-rebuild list-generations";
  };

  # Zsh pro všechny počítače: zelené/červené příkazy, našeptávač z historie, powerlevel10k.
  # Vzhled promptu nastavíš `p10k configure` (uloží ~/.p10k.zsh).
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;   # platný příkaz zeleně, neplatný červeně
    autosuggestions.enable = true;      # šedý návrh z historie, přijmeš šipkou →
    histSize = 10000;
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';
  };
  # Ikony v powerlevel10k potřebují Nerd Font (v terminálu nastav "MesloLGS Nerd Font").
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  # Delší příkaz jako skript: `nixdiff` ukáže, co se změnilo mezi posledními dvěma generacemi.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixdiff" ''
      gens=( $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -2) )
      echo "''${gens[0]##*/} -> ''${gens[1]##*/}"
      nix store diff-closures "''${gens[0]}" "''${gens[1]}"
    '')
  ];
}
