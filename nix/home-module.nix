{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ling-shell;
  jsonFormat = pkgs.formats.json { };

  generateJson =
    name: value:
    if lib.isString value then
      pkgs.writeText "ling-${name}.json" value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "ling-${name}.json" value;
in
{
  options.programs.ling-shell = {
    enable = lib.mkEnableOption "Ling shell configuration";

    systemd.enable = lib.mkEnableOption "Ling shell systemd integration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The ling-shell package to use";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      description = ''
        Ling shell configuration settings, written to
        ~/.config/ling/settings.json.
      '';
    };

    colours = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      description = ''
        Ling shell color configuration, written to
        ~/.config/ling/colours.json.
      '';
    };

    extraRuntimePackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "Optional executables exposed to Ling Shell, such as ddcutil, mpvpaper, or mpv. Cava and Matugen are bundled.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.ling-shell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Ling Shell - Wayland desktop shell";
        # TODO
        # Documentation = "https://docs.ling.dev/docs";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        ConditionEnvironment = "NIRI_SOCKET";

        X-Restart-Triggers =
          lib.optional (cfg.settings != { }) config.xdg.configFile."ling/settings.json".source
          ++ lib.optional (cfg.colours != { }) config.xdg.configFile."ling/colours.json".source;
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "2s";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    home.packages = lib.optional (cfg.package != null) cfg.package ++ cfg.extraRuntimePackages;

    xdg.configFile = {
      "ling/settings.json" = lib.mkIf (cfg.settings != { }) {
        source = generateJson "settings" cfg.settings;
      };

      "ling/colours.json" = lib.mkIf (cfg.colours != { }) {
        source = generateJson "colours" cfg.colours;
      };
    };

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "ling-shell: The package option must not be null when systemd service is enabled.";
      }
    ];
  };
}
