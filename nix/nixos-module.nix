{
  config,
  lib,
  ...
}: let
  cfg = config.services.ling-shell;
in {
  options.services.ling-shell = {
    enable = lib.mkEnableOption "Ling shell systemd service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The ling-shell package to use";
    };

    target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = "The systemd target for the ling-shell service.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.ling-shell = {
      description = "Ling Shell - Wayland desktop shell";
      documentation = [""];
      after = [cfg.target];
      partOf = [cfg.target];
      wantedBy = [cfg.target];
      restartTriggers = [cfg.package];

      environment = {
        PATH = lib.mkForce null;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        Environment = [];
      };
    };

    environment.systemPackages = [cfg.package];
  };
}
