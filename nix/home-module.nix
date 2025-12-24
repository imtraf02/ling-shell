{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.ling-shell;
  jsonFormat = pkgs.formats.json {};

  generateJson = name: value:
    if lib.isString value
    then pkgs.writeText "ling-${name}.json" value
    else if builtins.isPath value || lib.isStorePath value
    then value
    else jsonFormat.generate "ling-${name}.json" value;
in {
  options.programs.ling-shell = {
    enable = lib.mkEnableOption "Ling shell configuration";

    systemd.enable = lib.mkEnableOption "Ling shell systemd integration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The ling-shell package to use";
    };

    settings = lib.mkOption {
      type = with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = {};
      description = ''
        Ling shell configuration settings, written to
        ~/.local/state/quickshell/ling/settings.json.
      '';
    };

    config = lib.mkOption {
      type = with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = {};
      description = ''
        Ling shell configuration, written to
        ~/.config/quickshell/ling/config.json.
      '';
    };

    colours = lib.mkOption {
      type = with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = {};
      description = ''
        Ling shell color configuration, written to
        ~/.local/state/quickshell/ling/colours.json.
      '';
    };

    app2unit.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.app2unit;
      description = ''
        The app2unit package to use when appLauncher.useApp2Unit is enabled.
      '';
    };
  };

  config = let
    useApp2Unit = true;
  in
    lib.mkIf cfg.enable {
      systemd.user.services.ling-shell = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "Ling Shell - Wayland desktop shell";
          Documentation = "https://docs.ling.dev/docs";
          PartOf = [config.wayland.systemd.target];
          After = [config.wayland.systemd.target];

          X-Restart-Triggers =
            lib.optional (cfg.config != {})
            config.xdg.configFile."quickshell/ling/config.json".source
            ++ lib.optional (cfg.settings != {})
            config.xdg.stateFile."quickshell/ling/settings.json".source
            ++ lib.optional (cfg.colours != {})
            config.xdg.stateFile."quickshell/ling/colours.json".source;
        };

        Service = {
          ExecStart = lib.getExe cfg.package;
          Restart = "on-failure";
          Environment = [];
        };

        Install.WantedBy = [config.wayland.systemd.target];
      };

      home.packages =
        lib.optional useApp2Unit cfg.app2unit.package
        ++ lib.optional (cfg.package != null) cfg.package;

      xdg.stateFile = {
        "quickshell/ling/settings.json" = lib.mkIf (cfg.settings != {}) {
          source = generateJson "settings" cfg.settings;
        };

        "quickshell/ling/colours.json" = lib.mkIf (cfg.colours != {}) {
          source = generateJson "colours" cfg.colours;
        };
      };

      xdg.configFile = {
        "quickshell/ling/config.json" = lib.mkIf (cfg.config != {}) {
          source = generateJson "config" cfg.config;
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
