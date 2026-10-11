# Škola
{ pkgs, ... }: {
  imports = [ ./nextcloud.nix ];
  nextcloud.folders = [ "School" ];

  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/oxygen-xml-editor.nix { })  # vlastní balíček, viz pkgs/
  ];
}
