# Hry
{ pkgs, ... }: {
  programs.steam = { enable = true; extraCompatPackages = [ pkgs.proton-ge-bin ]; };
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    heroic                                 # Epic / GOG launcher
    (callPackage ../pkgs/curseforge.nix { })  # Minecraft modpacky, vlastní balíček
  ];
}
