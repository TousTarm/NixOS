# Pravidla pro tenhle config

Platí pro mě i pro Claude Code (načítá je přes `CLAUDE.md`).

1. **Natrvalo se přepíná jen na commitnutý config.** Všechna 3 PC (notebook + 2 desktopy) staví
   stejný config z gitu. Flake ale vidí i necommitnuté soubory, takže bez commitu poběží na každém
   PC něco jiného. `rebuild`, `rebuild-boot` a `update` proto se změnami v `~/NixOS` odmítnou běžet.
2. **Postup změny:** upravit → `rebuild-test` (přepne jen do restartu) → vyzkoušet →
   `git add -A && git commit` → `rebuild` → `git push` → na ostatních PC `git pull && rebuild`.
3. **Nic nedodělaného v aktivním configu.** Rozpracovanou věc vykomentuj (`# TODO: viz TODO.md`)
   nebo ji vůbec nezapisuj a zapiš ji do [TODO.md](TODO.md). Do commitu jde jen to, co funguje.
4. **Dočasné pokusy mimo repo** (soubory v `~/.config`, ručně spuštěné příkazy) zapsat do TODO.md,
   ať se na ně nezapomene.
5. **Jeden commit = jedno téma**, a [GUIDE.md](GUIDE.md) se upravuje ve stejném commitu.
6. **Git a rebuild nikdy pod `sudo`.** Hesla a tokeny nikdy do repa.
7. Po `update` je změněný `flake.lock`, commitni ho hned (`git commit -am "update"`).
