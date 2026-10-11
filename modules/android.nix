# Vývoj pro Android (Capacitor): Android SDK, adb, Java 21
#
# SDK je v /nix/store, takže je jen pro čtení: Gradle si do něj NEMŮŽE sám stáhnout chybějící
# verzi. Když projekt chce jinou (chyba "Failed to find Build Tools revision X" / "platform android-X"),
# přidej ji níž do platformVersions / buildToolsVersions a dej rebuild.
{ pkgs, ... }:
let
  android = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "35" ];          # compileSdkVersion v android/variables.gradle
    buildToolsVersions = [ "34.0.0" "35.0.0" ];  # 34.0.0 = výchozí pro Android Gradle Plugin 8.7
    includeEmulator = false;              # testuje se na telefonu přes USB
  };
  sdk = "${android.androidsdk}/libexec/android-sdk";
in {
  nixpkgs.config.android_sdk.accept_license = true;  # licence Googlu, bez toho SDK nejde sestavit

  programs.java = { enable = true; package = pkgs.jdk21; };  # Capacitor 7 = Java 21, nastaví JAVA_HOME

  environment.systemPackages = [ android.platform-tools ];  # adb, fastboot (novější než android-tools)

  environment.variables = {
    ANDROID_HOME = sdk;
    ANDROID_SDK_ROOT = sdk;  # starší nástroje (native-run) čtou tohle
  };

  # Gradle si stahuje aapt2 z Maven repozitáře jako běžnou linuxovou binárku. Ta na NixOS běží
  # díky programs.nix-ld (zapnuté v ai.nix).
}
