# AI nástroje na programování
{ pkgs, ... }: {
  # Claude Code se instaluje NATIVNÍM instalátorem (sám se aktualizuje, nixpkgs verze zaostává):
  #   curl -fsSL https://claude.ai/install.sh | bash
  # Binárka skončí v ~/.local/bin a je předkompilovaná pro "normální" Linux, proto:
  programs.nix-ld.enable = true;        # dynamický linker na FHS cestě, bez něj cizí binárky nespustíš
  environment.localBinInPath = true;    # ~/.local/bin na PATH (projeví se po novém přihlášení)

  environment.systemPackages = with pkgs; [
    antigravity   # Google Antigravity
    code-cursor   # Cursor
  ];
}
