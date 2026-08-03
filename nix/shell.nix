{
  quickshell,
  alejandra,
  statix,
  deadnix,
  shfmt,
  shellcheck,
  jsonfmt,
  lefthook,
  kdePackages,
  makeFontsConf,
  material-symbols,
  rubik,
  nerd-fonts,
  mkShellNoCC,
}:
let
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

  #it's faster than mkDerivation / mkShell
  packages = [
    quickshell

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
