{ config, lib, pkgs, ... }:
let
  systemctl = "/run/current-system/systemd/bin/systemctl";
in
{
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Battery", ENV{POWER_SUPPLY_STATUS}=="Discharging", RUN+="${systemctl} start on-battery.target"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Battery", ENV{POWER_SUPPLY_STATUS}=="Charging", RUN+="${systemctl} stop on-battery.target"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${systemctl} start on-mains.target"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_STATUS}=="0", RUN+="${systemctl} stop on-mains.target"
  '';

  systemd.targets."on-battery" = {
    conflicts = [ "on-mains.target" ];
  };

  systemd.targets."on-mains" = {
    conflicts = [ "on-battery.target" ] ;
  };

  systemd.services."power-state" = {
    description = "Triggers initial powerstate change, as udev events are unreliable during boot";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "power-state" ''
      AC=$(cat /sys/class/power_supply/AC*/online)
      BAT=$(cat /sys/class/power_supply/BAT*/status)
      if [[ $BAT == "Charging" || $AC == "1" ]]; then
        ${systemctl} start on-mains.target
      fi

      if [[ $BAT=="Discharging" || $AC=="0" ]]; then
        ${systemctl} start on-battery.target
      fi
      '';
    };
  };


  systemd.services."low-power" = {
    description = "a low-power configuration";
    after = [ "on-battery.target" ];
    wantedBy = [ "on-battery.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "enable-low-power" ''
      echo balance_power | tee /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference >/dev/null
      '';
    };
  };

  systemd.services."high-power" = {
    description = "a high-power configuration";
    after = [ "on-mains.target" ];
    wantedBy = [ "on-mains.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "enable-high-power" ''
      echo balance_performance | tee /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference >/dev/null
      '';
    };
  };
}
