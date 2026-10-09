# Škola
{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/oxygen-xml-editor.nix { })  # vlastní balíček, viz pkgs/
  ];
}
