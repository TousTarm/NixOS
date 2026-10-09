# CurseForge (Minecraft modpacky) – není v nixpkgs. Výrobce dává AppImage zabalenou v zipu.
# appimageTools.wrapType2 spustí AppImage v prostředí, které vypadá jako "normální" Linux (FHS).
# Nová verze: změnit `version` a `hash` (hash = "" -> build vypíše správný).
{ lib, appimageTools, fetchurl, runCommand, unzip }:

let
  pname = "curseforge";
  version = "1.285.2-27841";

  zip = fetchurl {
    # Výrobce má jen "latest" URL -> po vydání nové verze přestane sedět hash a build selže.
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.zip";
    hash = "sha256-ksxrZLY0dYHCWTHsoyr0o5PEbGjGQ2IWqrXl43J/ASE=";
  };

  src = runCommand "${pname}-${version}.AppImage" { nativeBuildInputs = [ unzip ]; } ''
    unzip -p ${zip} 'CurseForge-*.AppImage' > $out
  '';

  extracted = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Knihovny pro Minecraft samotný (CurseForge si stahuje vlastní Javu, ta je potřebuje)
  extraPkgs = pkgs: with pkgs; [
    libGL libpulseaudio alsa-lib openal flite udev
    libx11 libxext libxcursor libxrandr libxxf86vm libxi
  ];

  extraInstallCommands = ''
    install -Dm444 ${extracted}/curseforge.desktop $out/share/applications/curseforge.desktop
    substituteInPlace $out/share/applications/curseforge.desktop --replace-fail 'Exec=AppRun' 'Exec=curseforge'
    cp -r ${extracted}/usr/share/icons $out/share/
  '';

  meta = {
    description = "CurseForge – správce Minecraft modů a modpacků";
    homepage = "https://www.curseforge.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "curseforge";
  };
}
