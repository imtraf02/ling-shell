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

    extraRuntimePackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Optional executables exposed to Ling Shell, such as ddcutil or xdg-utils. Cava and Matugen are bundled.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.ling-shell = {
      description = "Ling Shell - Wayland desktop shell";
      documentation = [""];
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];
      restartTriggers = [cfg.package];
      unitConfig.ConditionEnvironment = "NIRI_SOCKET";

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };

    environment.systemPackages = [cfg.package] ++ cfg.extraRuntimePackages;
  };
}
