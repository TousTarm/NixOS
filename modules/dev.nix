# Programování
{ pkgs, ... }: {
  programs.git = {
    enable = true;
    config.user = { name = "toust"; email = "tomas.rindt@gmail.com"; };
    config.init.defaultBranch = "main";
  };

  environment.systemPackages = with pkgs; [
    nodejs_22
    postgresql  # kvůli klientovi psql
    python3
  ];
}
