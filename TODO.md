# TODO

Nedodělané věci a dočasná řešení (viz [RULES.md](RULES.md)). Hotové položky smaž.

- [ ] **Tailscale: místo shields-up ACL.** Shields-up (`core/tailscale.nix`) blokuje i spojení
      mezi mými PC. Lepší: v admin konzoli dát serveru tag `tag:server` a povolit jen
      `autogroup:member → autogroup:self` a `autogroup:member → tag:server`. Pak shields-up
      odebrat (ostatní flagy nechat). Viz poznámky v soukromém repu.
- [ ] **Smazat `~/.config/plasma-workspace/env/cursor-test.sh`** (softwarový kurzor, dočasný pokus
      mimo config; myš rušil disk). Po smazání se odhlásit a přihlásit.
- [ ] **Sjednotit hostname na `desktop`?** Vrácen na `nixos` kvůli problému s přihlášením 8. 10.
      Pozor: změna hostname může rozbít Chromium/Electron aplikace (viz GUIDE.md).
- [ ] **Ověřit, jestli je potřeba `services.xserver.enable`** (Plasma běží na Waylandu).
