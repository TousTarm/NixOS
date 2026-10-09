# Vlastní příkazy a aliasy. `host` přichází z flake.nix (mkHost), takže aliasy
# na každém počítači sestaví ten správný config.
{ host, pkgs, ... }:
let
  flake = "/home/toust/NixOS";
in {
  environment.shellAliases = {
    rebuild      = "nh os switch -H ${host}";        # sestav a přepni
    rebuild-boot = "nh os boot -H ${host}";          # přepni až po restartu (bezpečnější u velkých změn)
    rebuild-test = "nh os test -H ${host}";          # vyzkoušej, po restartu zpět
    update       = "nh os switch -H ${host} --update"; # aktualizuj nixpkgs (flake.lock) + přepni
    nixcfg       = "cd ${flake}";
    generations  = "nixos-rebuild list-generations";
  };

  # Delší příkaz jako skript: `nixdiff` ukáže, co se změnilo mezi posledními dvěma generacemi.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixdiff" ''
      gens=( $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -2) )
      echo "''${gens[0]##*/} -> ''${gens[1]##*/}"
      nix store diff-closures "''${gens[0]}" "''${gens[1]}"
    '')
  ];
}
