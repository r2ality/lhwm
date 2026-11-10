{ config, lib, pkgs, ... }:
let
  cfg = config.services.xserver.windowManager.lhwm;
in
{
  options.services.xserver.windowManager.lhwm = {
    enable = lib.mkEnableOption "LHWM, the Lightweight HolyWM window manager";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lhwm;
      defaultText = lib.literalExpression "pkgs.lhwm";
      description = "The LHWM package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.sessionPackages = [ cfg.package ];
    environment.systemPackages = [ cfg.package pkgs.dmenu ];
    fonts.packages = [ pkgs.font-misc-misc ];
  };
}
