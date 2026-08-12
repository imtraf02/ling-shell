{
  version ? "dirty",
  lib,
  stdenvNoCC,
  # build
  qt6,
  quickshell,
  # runtime deps
  brightnessctl,
  cava,
  matugen,
  # fonts
  makeFontsConf,
  material-symbols,
  rubik,
  nerd-fonts,
}: let
  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      !(lib.hasSuffix ".tmp" (builtins.baseNameOf path))
      && !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.github
        /.gitignore
        /bin/dev
        /nix
        /LICENSE
        /README.md
        /result
        /flake.nix
        /flake.lock
        /shell.nix
      ]);
  };

  runtimeDeps =
    [
      brightnessctl
      cava
      matugen
    ]
    ++ lib.optionals (stdenvNoCC.hostPlatform.system == "x86_64-linux") [
    ];

  fontconfig = makeFontsConf {
    fontDirectories = [
      material-symbols
      rubik
      nerd-fonts.caskaydia-cove
    ];
  };
in
  stdenvNoCC.mkDerivation {
    pname = "ling-shell";
    inherit version src;

    nativeBuildInputs = [
      qt6.wrapQtAppsHook
    ];

    buildInputs = [
      qt6.qtbase
      qt6.qtmultimedia
    ];

    installPhase = ''
      mkdir -p $out/share/ling-shell $out/bin
      cp -r . $out/share/ling-shell
      ln -s ${quickshell}/bin/qs $out/bin/ling-shell
    '';

    preFixup = ''
      qtWrapperArgs+=(
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
        --set FONTCONFIG_FILE ${fontconfig}
        --add-flags "--no-duplicate -p $out/share/ling-shell"
      )
    '';

    meta = {
      description = "A sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell.";
      homepage = "https://github.com/imtraf02/ling-shell";
      license = lib.licenses.mit;
      mainProgram = "ling-shell";
    };
  }
