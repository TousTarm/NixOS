# Základ, který importuje každý počítač. Když se importuje složka, Nix načte její default.nix.
{ ... }: {
  imports = [
    ./nix.nix
    ./locale.nix
    ./users.nix
    ./shell.nix
    ./tailscale.nix
  ];
}
