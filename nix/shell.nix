{
  quickshell,
  cava,
  matugen,
  alejandra,
  statix,
  deadnix,
  shfmt,
  shellcheck,
  jsonfmt,
  lefthook,
  qt6,
  kdePackages,
  makeFontsConf,
  material-symbols,
  rubik,
  nerd-fonts,
  mkShellNoCC,
}: let
  fontconfig = makeFontsConf {
    fontDirectories = [
      material-symbols
      rubik
      nerd-fonts.caskaydia-cove
    ];
  };
in
  mkShellNoCC {
    FONTCONFIG_FILE = fontconfig;

    shellHook = ''
      export NIXPKGS_QT6_QML_IMPORT_PATH="${qt6.qtmultimedia}/lib/qt-6/qml:$NIXPKGS_QT6_QML_IMPORT_PATH"
      export QT_PLUGIN_PATH="${qt6.qtmultimedia}/lib/qt-6/plugins:$QT_PLUGIN_PATH"
    '';

    #it's faster than mkDerivation / mkShell
    packages = [
      quickshell
      cava
      matugen
      qt6.qtmultimedia

      # nix
      alejandra # formatter
      statix # linter
      deadnix # linter

      # shell
      shfmt # formatter
      shellcheck # linter

      # json
      jsonfmt # formatter

      # CoC
      lefthook # githooks
      kdePackages.qtdeclarative # qmlfmt, qmllint, qmlls and etc; Qt6
    ];
  }
