# Průvodce mým NixOS configem

Tenhle dokument vysvětluje, **jak config funguje, jak s ním pracovat a co na něm ještě není ideální**.
Je psaný pro přechod z Arche. Když se něco změní, aktualizuj ho.

---

## 1. Jak o NixOS přemýšlet (rozdíl oproti Archu)

| Arch | NixOS |
|---|---|
| `pacman -S balík` | balík napíšeš do `.nix` souboru a dáš `rebuild` |
| upravuješ `/etc/...` ručně | `/etc` se generuje z configu, ruční změny se přepíšou |
| stav systému = součet všeho, co jsi kdy udělal | stav systému = **tahle složka**, nic víc |
| rozbitý update = oprava ručně | rozbitý update = restart a v boot menu vybrat předchozí generaci |
| `pacman -Syu` | `update` (aktualizuje `flake.lock` a přepne) |

Klíčové pojmy:

- **/nix/store**: každý balíček a každý sestavený systém leží ve vlastní složce
  `/nix/store/<hash>-jméno`. Hash se počítá ze všeho, co do balíčku vstoupilo, takže dvě verze
  se nikdy nepřepíšou.
- **Generace**: každý rebuild vytvoří novou generaci systému. Staré zůstávají, dokud je neuklidí
  garbage collector, a jde je vybrat v boot menu. **Tohle je tvoje záchranná síť**, jak jsi viděl
  8. 10. při problému s uspáním.
- **Flake**: `flake.nix` říká, odkud se berou balíčky (nixpkgs) a jaké počítače existují.
  `flake.lock` zamyká přesnou verzi nixpkgs. Systém se tedy nezmění, dokud sám nespustíš `update`.
- **Dva zdroje balíčků**: `nixpkgs` (stabilní `nixos-26.05`) pro celý systém. Verze programů tam
  stojí a chodí jen opravy. `nixpkgs-unstable` jen pro programy, které na stabilní větvi rychle
  zastarávají (teď Cursor). Viz recept „Program je moc stará verze“.
- **Modul**: každý `.nix` soubor v `modules/` je modul, který nastavuje **volby**
  (`services.X.enable = true;`). NixOS všechny moduly sloučí:
  - seznamy se spojí, takže `environment.systemPackages` může být v každém modulu
    a výsledkem je jeden velký seznam,
  - jednoduchou hodnotu (`true`, `"text"`) nesmí dva moduly nastavit různě, jinak build skončí chybou.
- **Flake vidí jen soubory, o kterých ví git.** Nový soubor musíš aspoň `git add`, jinak build
  hlásí, že neexistuje. Tohle je nejčastější past.

---

## 2. Struktura

```
flake.nix                     vstupní bod: nixpkgs (+ unstable) + seznam počítačů (mkHost)
flake.lock                    zamčené verze nixpkgs a unstable (needitovat ručně)
hosts/
  desktop/
    default.nix               tenhle počítač: boot, GPU, hardwarové fixy + VÝBĚR MODULŮ
    hardware-configuration.nix vygenerované (disky, kernel moduly), needitovat
modules/
  core/                       základ pro VŠECHNY počítače
    default.nix                 importuje zbytek složky
    nix.nix                     nastavení Nixu, nh, automatický úklid
    locale.nix                  čas, jazyk, klávesnice
    users.nix                   uživatel toust
    shell.nix                   aliasy a vlastní příkazy
    tailscale.nix               Tailscale VPN (po instalaci: sudo tailscale up)
  plasma.nix                  KDE Plasma, zvuk, síť, tisk
  apps.nix                    běžné aplikace (Firefox, Discord, Spotify, ...)
  personal.nix                osobní věci, složka Projects
  gaming.nix                  Steam, Heroic, CurseForge
  dev.nix                     git, node, psql
  ai.nix                      Claude Code (podpora), Antigravity, Cursor (z unstable)
  school.nix                  Oxygen XML Editor, složka School
pkgs/                         vlastní balíčky (co není v nixpkgs)
  oxygen-xml-editor.nix
  curseforge.nix
certs/                        certifikáty
```

**Jak to do sebe zapadá:**

```
flake.nix
  └─ mkHost "desktop"  ──►  hosts/desktop/default.nix
                              ├─ hardware-configuration.nix
                              ├─ modules/core/        (vždy)
                              ├─ modules/plasma.nix   ┐
                              ├─ modules/gaming.nix   │ podle toho, co
                              ├─ modules/school.nix   │ na tom počítači chci
                              └─ ...                  ┘

personal.nix ─┐
school.nix   ─┼─ import ./nextcloud.nix + nextcloud.folders = [ ... ]
```

Modul se vypíná tak, že jeho řádek v `hosts/desktop/default.nix` zakomentuješ (`#`). Soubor
zůstane a zapneš ho odkomentováním.

Pravidlo: **modul = téma, host = výběr témat + hardware.** Notebook pak třeba vynechá `gaming.nix`
a nemá Nvidii, ale `core/`, `plasma.nix` a `school.nix` sdílí s desktopem.

`mkHost` ve `flake.nix` posílá každému modulu argument `host` (jméno configu, např. `"desktop"`).
Používá ho `core/shell.nix`, aby aliasy na každém počítači sestavily správný config.

### Jak fungují jednotlivé části

**Tailscale** (`core/tailscale.nix`): zapne službu a otevře firewall. Navíc nastavuje
WireGuard). Na novém počítači se jednou přihlásíš: `sudo tailscale up`.
a vypnuté subnet routy, exit node a Tailscale SSH (`extraSetFlags`).

**Nextcloud** (`nextcloud.nix`) je společný základ, který sám nic nesynchronizuje:
- nainstaluje desktop aplikaci Nextcloud,
- vytvoří `~/.config/Nextcloud/sync-exclude.lst` = co se nikdy nesynchronizuje (`node_modules/`,
  `venv/`, `__pycache__/`, ...). Platí pro všechny složky. Měň ho v modulu, ne v aplikaci, protože
  změny v aplikaci se neuloží,
- přidá vlastní volbu `nextcloud.folders`. Pro každou složku v ní vytvoří `~/<složka>` a odkaz
  na ploše. Seznamy z různých modulů se spojí (teď `[ "Projects" "School" ]`).

Které složky se párují se serverem, Nix neřídí. To je uložené v aplikaci Nextcloud
(`~/.config/Nextcloud/nextcloud.cfg`) a naklikává se ručně (viz recept „Nová synchronizovaná složka“).
Aplikace se po přihlášení spouští sama (zaškrtnuto v jejím nastavení).

| Lokálně | Server | Modul |
|---|---|---|
| `~/Projects` | `/Projects` | `personal.nix` |
| `~/School` | `/School` | `school.nix` |

obnovit pracovní prostředí na jiném zařízení. Proto:
  - `repos.tsv`: seznam repozitářů (cesta, URL `origin`, aktuální větev),
  - `files/`: jen IDE kontext (`.vscode/`, `.idea/`, `.cursor/`, `.claude/`, `CLAUDE.md`,
    `AGENTS.md`, ...), seznam je v `ideContext` na začátku modulu.
  repa a vrátí do nich IDE kontext.

**Cursor z unstable** (`ai.nix`): na začátku modulu se načte `nixpkgs-unstable`
(`unstable = import inputs.nixpkgs-unstable { ... }`) a v seznamu balíčků je pak
`unstable.code-cursor`. `inputs` přichází z `flake.nix` stejně jako `host`.

---

## 3. Každodenní příkazy

Aliasy jsou definované v `modules/core/shell.nix`.

| Příkaz | Co dělá |
|---|---|
| `rebuild` | sestaví config a přepne na něj (`nh os switch`) |
| `rebuild-test` | přepne, ale po restartu se vrátí zpět. Na zkoušení |
| `rebuild-boot` | nová generace se použije až po restartu. Bezpečnější u velkých změn (GPU, login) |
| `update` | aktualizuje nixpkgs (`flake.lock`) a přepne |
| `nixcfg` | `cd ~/NixOS` |
| `generations` | seznam generací |
| `nixdiff` | co se změnilo mezi posledními dvěma generacemi |
| `nix shell nixpkgs#htop` | program jen dočasně vyzkoušet, zmizí po zavření shellu |
| `sudo nixos-rebuild switch --rollback` | vrátit se o generaci zpět |

`nh` před přepnutím ukáže, které balíčky přibudou nebo zmizí. Jednou týdně sám uklidí generace
starší než 14 dní (vždy jich nechá aspoň 5).

**Po každé fungující změně commitni:**

```bash
git add -A && git commit -m "přidán X"
```

---

## 4. Recepty

### Přidat aplikaci z nixpkgs

1. Najdi ji na https://search.nixos.org/packages (pozor na kanál `26.05`).
2. Zkontroluj, jestli k ní neexistuje i **volba** (https://search.nixos.org/options, např.
   `programs.steam.enable`). Když ano, použij volbu, protože nastaví i věci okolo (firewall, oprávnění, ...).
3. Přidej ji do správného modulu:
   ```nix
   environment.systemPackages = with pkgs; [
     obs-studio
   ];
   ```
4. `rebuild`

### Přidat program, který v nixpkgs NENÍ

Od nejčistšího po nejšpinavější:

1. **Vlastní balíček v `pkgs/`.** Takhle je udělaný Oxygen (archiv + Java) a CurseForge (AppImage).
   Verze je zamčená hashem, takže je reprodukovatelná a funguje na všech počítačích.
   - archiv nebo binárka → podle `pkgs/oxygen-xml-editor.nix` (`stdenvNoCC.mkDerivation` + `fetchurl`)
   - AppImage → podle `pkgs/curseforge.nix` (`appimageTools.wrapType2`)
   - do modulu: `(pkgs.callPackage ../pkgs/jmeno.nix { })`
2. **Flatpak** (`services.flatpak.enable = true;`). Hodí se pro GUI aplikace, které jsou na Flathubu.
   Aplikace pak ale nejsou v configu.
3. **Ruční binárka + `nix-ld`.** Takhle běží Claude Code. Funguje, ale je mimo config: na novém
   počítači ji musíš nainstalovat znovu ručně.

### Program je moc stará verze

Stabilní větev (`nixos-26.05`) drží verze programů, které se rychle vyvíjejí (editory, AI nástroje),
často na stavu z doby vydání. `update` to nespraví, protože jen posune stabilní větev.

1. Porovnej verze:
   `nix eval --raw nixpkgs#jmeno.version` a `nix eval --raw github:NixOS/nixpkgs/nixos-unstable#jmeno.version`
2. Pokud je unstable novější, vezmi balíček odtud. V modulu přidej na začátek `let unstable = ...`
   (zkopíruj z `ai.nix`) a v seznamu napiš `unstable.jmeno` místo `jmeno`.
3. `rebuild`. `update` pak posouvá i unstable, takže program se bude aktualizovat s ním.

### Nová synchronizovaná složka (Nextcloud)

1. Do správného modulu přidej název do `nextcloud.folders`, např. `nextcloud.folders = [ "Projects" "Documents" ];`.
   Pokud modul ještě nemá `imports = [ ./nextcloud.nix ];`, přidej i to.
2. `rebuild` vytvoří `~/Documents` a odkaz na ploše.
3. V aplikaci Nextcloud: **Přidat synchronizaci složky** → `~/Documents` → na serveru vyber nebo
   vytvoř `/Documents`. Na serveru nic předem zakládat nemusíš.

### Aktualizovat vlastní balíček (Oxygen, CurseForge)

1. V `pkgs/xyz.nix` změň `version` (a URL, pokud v ní verze je).
2. Nastav `hash = "";`
3. `rebuild` → build selže s hláškou `got: sha256-...`
4. Ten hash zkopíruj do `hash = "..."` a dej `rebuild` znovu.

### Nový modul

1. Vytvoř `modules/neco.nix`:
   ```nix
   # Popis, co modul dělá
   { pkgs, ... }: {
     environment.systemPackages = with pkgs; [ ... ];
   }
   ```
2. `git add modules/neco.nix` (jinak ho flake nevidí!)
3. Přidej `../../modules/neco.nix` do `imports` v `hosts/<pocitac>/default.nix`.
4. `rebuild`

### Nový alias / příkaz

V `modules/core/shell.nix`:
- jednoduchý → `environment.shellAliases.jmeno = "příkaz";`
- složitější (víc řádků, argumenty) → `pkgs.writeShellScriptBin "jmeno" ''...''` do
  `environment.systemPackages`, viz `nixdiff`. Skript je pak normální příkaz v PATH, takže funguje
  i mimo bash.

### Nový počítač (např. notebook)

1. Na notebooku nainstaluj NixOS z ISO (grafický instalátor stačí).
2. Naklonuj repo: `git clone <repo> ~/NixOS`
3. `mkdir hosts/laptop && cp /etc/nixos/hardware-configuration.nix hosts/laptop/`
4. Vytvoř `hosts/laptop/default.nix` podle desktopu:
   - bez Nvidie a fwupd fixu (to je hardware desktopu),
   - `system.stateVersion` **zkopíruj z `/etc/nixos/configuration.nix` notebooku**, ne z desktopu,
   - vyber moduly.
5. Ve `flake.nix` odkomentuj nebo přidej `laptop = mkHost "laptop";`
6. `git add -A && sudo nixos-rebuild switch --flake ~/NixOS#laptop` (poprvé bez aliasů, ty ještě
   neexistují)
7. Doinstaluj věci mimo config (Claude Code: `curl -fsSL https://claude.ai/install.sh | bash`).

---

## 5. Co je dobře a co ne

### Dobře ✅
- **Flake + lock**: všechny počítače mají přesně stejnou verzi balíčků a update je vědomý krok.
- **Moduly po tématech** a hosty, které si je vybírají, takže je připraveno na 3 zařízení.
- **Git**: každá změna je vratná i na úrovni configu, nejen přes generace.
- **Vlastní balíčky jsou zamčené hashem**: když výrobce soubor změní, build selže a nenainstaluje
  potichu něco jiného.
- **Automatický úklid** starých generací (`nh clean`).
- Hardwarové fixy (Nvidia, fwupd) jsou u hosta, ne ve sdílených modulech.

### Není ideální / TODO ⚠️
- **Hostname `nixos` ≠ jméno configu `desktop`.** Aliasy to obchází přes `-H desktop`. Hostname
  byl vrácen kvůli problému s přihlášením 8. 10. Pokud se ukáže, že za to nemohl, je čistší ho
  sjednotit na `desktop`. **Pozor:** každá změna hostname může rozbít Chromium/Electron aplikace
  (viz „Když něco nejde“).
- **Git a rebuild nikdy pod `sudo`.** Soubory v `~/NixOS` pak patří rootovi a nejde do nich
  zapisovat (stalo se 11. 10.). `rebuild` si o heslo řekne sám.
  a `wireguard-tools`. Ve stínu zatím nejsou žádná data.
- **Párování složek v Nextcloudu není v configu.** Na novém počítači se musí naklikat znovu.
- **CurseForge má jen URL „latest“.** Po vydání nové verze přestane sedět hash a **celý rebuild
  selže**. Pak postupuj podle „Aktualizovat vlastní balíček“. Alternativa bez tohohle problému je
  Prism Launcher (`prismlauncher` v nixpkgs), který umí i CurseForge modpacky.
- **Oxygen běží bez JavaFX.** Pár funkcí (náhledy přes webový engine) nemusí fungovat.
- **Claude Code je mimo config** (nativní instalátor kvůli auto-updatu, nixpkgs verze zaostává).
  Na každém počítači se instaluje ručně.
- **`~/.config/plasma-workspace/env/cursor-test.sh`** (softwarový kurzor) je dočasný pokus
  mimo config. Myš ve skutečnosti rušil disk, takže ho smaž.
- **Žádný home-manager.** Nastavení v home (dotfiles, bash, KDE, git) není v configu. Další velký
  krok, až budeš chtít.
- **Všechno je systémové** (`environment.systemPackages`). Pro jednoho uživatele to nevadí.
- **`services.xserver.enable`** nejspíš není potřeba (Plasma běží na Waylandu). Nechávám to, dokud
  to nebude ověřené.
- **Do repa nikdy nedávej hesla ani tokeny.** Všechno z configu skončí v `/nix/store`, který může
  číst každý uživatel. Na tajnosti se používá `sops-nix` nebo `agenix`.
- **Upgrade NixOS** (např. na 26.11) znamená změnit `nixos-26.05` ve `flake.nix`. `stateVersion`
  přitom **neměnit**.

---

## 6. Když něco nejde

- **Build selže:** čti chybu odspodu. `error: attribute 'xyz' missing` = překlep nebo balík
  neexistuje. `has an unsupported value` / `defined multiple times` = dva moduly nastavují totéž.
  Víc detailů ukáže `rebuild --show-trace`.
- **„path ... does not exist“** u nového souboru → zapomenutý `git add`.
- **„Permission denied“ na `flake.lock` nebo v `.git`** → git nebo Nix běžel pod
  sudo. Oprava: `sudo chown -R toust:users ~/NixOS`.
- **Aplikace (Spotify, Discord, Cursor, ...) se po spuštění hned zavře** a předtím se měnil
  hostname → v její složce zůstal zámek se starým jménem počítače. Najdi ho:
  `find ~/.config ~/.cache -maxdepth 4 -name SingletonLock -printf '%p -> %l\n'`.
  Když aplikace neběží, smaž `SingletonLock`, `SingletonSocket` a `SingletonCookie` vedle něj.
- **Nextcloud nesynchronizuje** → ikona v liště ukáže chybu. Konflikty se ukládají jako
  `soubor (conflicted copy ...)` vedle originálu.
- **Po rebuildu něco nefunguje** → `sudo nixos-rebuild switch --rollback` nebo starší generace
  v boot menu. Pak v klidu hledat chybu.
- **Jaká je aktuální hodnota volby?**
  `nix eval .#nixosConfigurations.desktop.config.services.fwupd.daemonSettings`
- **Interaktivní průzkum configu:** `nix repl` → `:lf .` → `nixosConfigurations.desktop.config.<Tab>`
- **Logy:** `journalctl -b` (tento start), `journalctl -b -1` (předchozí start), `-p warning` jen varování.
- **Dokumentace:** https://search.nixos.org/options, https://nixos.org/manual/nixos/stable/,
  https://wiki.nixos.org

---

## 7. Historie problémů

| Datum | Problém | Příčina | Řešení |
|---|---|---|---|
| 8. 10. | cukání kurzoru, ztracené kliky | fwupd steelseries plugin každých 20 s odpojoval sluchátka (stejný USB řadič jako myš) | plugin vypnut v `hosts/desktop` |
| 8. 10. | myš dál občas nereagovala | USB 3 disk WD Elements ruší 2,4 GHz dongle | disk dál od dongle |
| 8. 10. | PC se neprobudilo z uspání | Nvidia bez `powerManagement` neukládá VRAM | `hardware.nvidia.powerManagement.enable` |
| 8. 10. | černá obrazovka 30 s při loginu, freeze po re-loginu | race v SDDM při předávání VT (Nvidia), příčina nepotvrzená | hostname zpět na `nixos`. Kdyby se vrátilo: `services.displayManager.sddm.wayland.enable = false` |
| 11. 10. | git a `nix flake lock` hlásí Permission denied | `.git/objects/e6` a `flake.lock` patřily rootovi (git/Nix pod sudo) | `sudo chown -R toust:users ~/NixOS` |
| 11. 10. | Cursor hlásí „very old version“ | stabilní nixpkgs drží Cursor na 3.5, `update` nepomůže | Cursor z `nixpkgs-unstable` (3.24) |
| 11. 10. | Spotify se po spuštění hned zavře | po rebuildu se hostname změnil `desktop` → `nixos`, v `~/.cache/spotify/SingletonLock` zůstal zámek se starým jménem | zámek smazán |
