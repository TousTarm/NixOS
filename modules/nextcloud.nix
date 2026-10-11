# Základ pro synchronizaci s vlastním Nextcloud serverem (oficiální desktop klient).
# school.nix) přes vlastní volbu `nextcloud.folders`, např.:
#
#   imports = [ ./nextcloud.nix ];
#   nextcloud.folders = [ "Projects" ];
#
# Pro každou složku se vytvoří ~/<jmeno> a odkaz na ploše. Spárování se serverem se pak
# jednou naklikne v aplikaci Nextcloud: "Přidat synchronizaci složky" -> ~/<jmeno> <-> /<jmeno>.
# V nastavení klienta zaškrtnout "Spouštět při startu systému".
{ config, lib, pkgs, ... }:
let
  home = "/home/toust";

  # Co se NEsynchronizuje (formát Nextcloudu: "jmeno/" = složka kdekoliv ve stromu, * = wildcard).
  syncExclude = pkgs.writeText "sync-exclude.lst" ''
    node_modules/
    .venv/
    venv/
    __pycache__/
    .pytest_cache/
    .mypy_cache/
    .next/
    .nuxt/
    .cache/
    .direnv/
    .gradle/
    target/
    *.pyc
  '';
in {
  # Vlastní volba. Seznamy z více modulů NixOS spojí do jednoho.
  options.nextcloud.folders = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Složky v ~, které se synchronizují s Nextcloudem a mají odkaz na ploše.";
  };

  config = {
    environment.systemPackages = [ pkgs.nextcloud-client ];

    # systemd-tmpfiles při bootu/rebuildu vytvoří složky a odkazy (L+ = symlink, přepíše existující).
    systemd.tmpfiles.rules = [
      "d  ${home}/.config/Nextcloud 0700 toust users - -"
      "L+ ${home}/.config/Nextcloud/sync-exclude.lst - - - - ${syncExclude}"
    ] ++ lib.concatMap (name: [
      "d  ${home}/${name} 0755 toust users - -"
      "L+ ${home}/Desktop/${name} - - - - ${home}/${name}"
    ]) config.nextcloud.folders;
  };
}
