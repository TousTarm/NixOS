# Oxygen XML Editor – není v nixpkgs (proprietární), tak si ho balíme sami.
# Nová verze: změnit `version`, hash nastavit na "" a spustit build – Nix vypíše správný hash.
{ lib, stdenvNoCC, fetchurl, makeWrapper, makeDesktopItem, copyDesktopItems, jdk21 }:

stdenvNoCC.mkDerivation rec {
  pname = "oxygen-xml-editor";
  version = "28.1";

  src = fetchurl {
    url = "https://archives.oxygenxml.com/Oxygen/Editor/InstData${version}/All/oxygen.tar.gz";
    hash = "sha256-BeuuFFk1gpSYY6ulZN/mzLTaSY25ITQrKprTs0MMI58=";
  };

  nativeBuildInputs = [ makeWrapper copyDesktopItems ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt $out/bin
    cp -r . $out/opt/oxygen
    # oxygen.sh si Javu hledá v JAVA_HOME; Java 21, protože novější odmítají -Djava.security.manager=allow
    makeWrapper $out/opt/oxygen/oxygen.sh $out/bin/oxygen --set JAVA_HOME ${jdk21}
    install -Dm644 Oxygen128.png $out/share/icons/hicolor/128x128/apps/oxygen-xml-editor.png
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "oxygen-xml-editor";
      desktopName = "Oxygen XML Editor";
      exec = "oxygen %F";
      icon = "oxygen-xml-editor";
      categories = [ "Development" "TextEditor" ];
      mimeTypes = [ "application/xml" "text/xml" ];
    })
  ];

  meta = {
    description = "Oxygen XML Editor";
    homepage = "https://www.oxygenxml.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "oxygen";
  };
}
