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
  cliphist,
  ddcutil,
  matugen,
  wlsunset,
  wl-clipboard,
  imagemagick,
  wget,
  gpu-screen-recorder, # optional
  # fonts
  makeFontsConf,
  material-symbols,
  rubik,
  nerd-fonts,
}: let
  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      !(builtins.any (prefix: lib.path.hasPrefix (../. + prefix) (/. + path)) [
        /.github
        /.gitignore
        /bin/dev
        /nix
        /LICENSE
        /README.md
        /flake.nix
        /flake.lock
        /shell.nix
      ]);
  };

  runtimeDeps =
    [
      brightnessctl
      cava
      cliphist
      ddcutil
      matugen
      wlsunset
      wl-clipboard
      imagemagick
      wget
    ]
    ++ lib.optionals (stdenvNoCC.hostPlatform.system == "x86_64-linux") [
      gpu-screen-recorder
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
        --add-flags "-p $out/share/ling-shell"
      )
    '';

    meta = {
      description = "A sleek and minimal desktop shell thoughtfully crafted for Wayland, built with Quickshell.";
      homepage = "https://github.com/imtraf02/ling-shell";
      license = lib.licenses.mit;
      mainProgram = "ling-shell";
    };
  }
