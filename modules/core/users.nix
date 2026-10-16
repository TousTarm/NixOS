# Uživatelské účty
{ pkgs, ... }: {
  users.users.toust = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "toust";
    extraGroups = [ "networkmanager" "wheel" ];  # wheel = smí používat sudo
  };
}
