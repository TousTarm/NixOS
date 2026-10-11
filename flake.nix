{
  description = "NixOS config";

  # Odkud bereme balíčky. Přesná verze je zamčená ve flake.lock (aktualizace: `update`).
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  # Nejnovější balíčky pro programy, které na stabilní větvi rychle zastarávají (Cursor, ...)
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }@inputs:
    let
      # mkHost "jmeno" = sestav systém z hosts/jmeno/. `host` a `inputs` jsou pak dostupné
      # v každém modulu jako argument: { host, pkgs, ... }: ...
      mkHost = host: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs host; };
        modules = [ ./hosts/${host} ];
      };
    in {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        # laptop  = mkHost "laptop";   # viz GUIDE.md -> "Nový počítač"
      };
    };
}
