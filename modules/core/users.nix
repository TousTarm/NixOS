# Uživatelské účty
{ ... }: {
  users.users.toust = {
    isNormalUser = true;
    description = "toust";
    extraGroups = [ "networkmanager" "wheel" ];  # wheel = smí používat sudo
  };
}
