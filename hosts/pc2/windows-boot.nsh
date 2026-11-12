@echo -off
# Najde EFI oddíl s Windows (FS0..FS9) a spustí jejich bootloader.
# Spouští ho položka "Windows" v systemd-boot (viz default.nix).
for %a in 0 1 2 3 4 5 6 7 8 9
  if exist FS%a:\EFI\Microsoft\Boot\bootmgfw.efi then
    FS%a:\EFI\Microsoft\Boot\bootmgfw.efi
  endif
endfor
echo "Windows bootloader nenalezen (zkus map -c a ls FSx:\EFI)"
