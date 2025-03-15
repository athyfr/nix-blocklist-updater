{ lib, ... }:
with lib; {
  imports = [
    ./service.nix
    (lib.mkRemovedOptionModule [ "services" "blocklist-updater" "runInitially" ] ''
      The service is now performant and can be run on every boot. This avoids
      leaving the blocklist in place if the module is removed.
    '')
  ];
  options.services.blocklist-updater = {
    enable = mkEnableOption "blocklist-updater";
    blocklists = mkOption {
      type = types.listOf types.str;
      example = [ "example.com" ];
      default = [ "https://lists.blocklist.de/lists/all.txt" ];
      description = "URL lists containing new line separated IPs to be blocked";
      apply = lib.strings.concatMapStrings (x: "\n'${x}'");
    };
    blocklistedIPs = mkOption {
      type = with types; either str (listOf str);
      example = [ "1.2.3.4" "10.168.10.0/24" "2a06:4883:1000::2" ];
      default = [ ];
      description = "List of manually banned IPs";
      apply = v: if isList v then lib.strings.concatMapStrings (x: "\n" + x) v else v;
    };
    updateAt = mkOption {
      type = with types; either str (listOf str);
      default = "*-*-* 01:00:00";
      example = [ "Wed 14:00:00" "Sun 14:00:00" ];
      description = ''
        Automatically start this unit at the given date/time, which
        must be in the format described in
        {manpage}`systemd.time(7)`.  This is equivalent
        to adding a corresponding timer unit with
        {option}`OnCalendar` set to the value given here.
      '';
    };
    ipSetName = mkOption {
      type = types.str;
      default = "BlackList";
      description = "Name of ipset SETNAME";
    };
    ipV6SetName = mkOption {
      type = types.str;
      default = "BlackList6";
      description = "Name of ipset SETNAME for IPv6 addresses";
    };
  };
}
