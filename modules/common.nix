{ pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # RTX 3080 Ti
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = { enable = true; enable32Bit = true; };
  hardware.nvidia = { modesetting.enable = true; open = true; nvidiaSettings = true; };

  # fwupd steelseries plugin každých 20 s odpojuje Arctis Nova 5 -> na stejném USB řadiči pak blbne myš
  services.fwupd.daemonSettings.DisabledPlugins = [ "steelseries" ];

  # Steam
  programs.steam = { enable = true; extraCompatPackages = [ pkgs.proton-ge-bin ]; };
  programs.gamemode.enable = true;

  # práce
  programs.git.enable = true;
  programs.nix-ld.enable = true;
  networking.firewall.checkReversePath = "loose";

  environment.systemPackages = with pkgs; [
    code-cursor
    postgresql
    wireguard-tools
    signal-desktop
    spotify
    discord
    antigravity
    nodejs_22
  ];
}
