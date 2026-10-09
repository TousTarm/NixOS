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
flake.nix                     vstupní bod: nixpkgs + seznam počítačů (mkHost)
flake.lock                    zamčená verze nixpkgs (needitovat ručně)
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
  gaming.nix                  Steam, Heroic, CurseForge
  dev.nix                     git, node, psql
  ai.nix                      Claude Code (podpora), Antigravity, Cursor
  school.nix                  Oxygen XML Editor
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
```

Pravidlo: **modul = téma, host = výběr témat + hardware.** Notebook pak třeba vynechá `gaming.nix`
a nemá Nvidii, ale `core/`, `plasma.nix` a `school.nix` sdílí s desktopem.

`mkHost` ve `flake.nix` posílá každému modulu argument `host` (jméno configu, např. `"desktop"`).
Používá ho `core/shell.nix`, aby aliasy na každém počítači sestavily správný config.

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
  sjednotit na `desktop`.
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
