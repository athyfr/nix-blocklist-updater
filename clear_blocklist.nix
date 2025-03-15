{ pkgs, config }: let
inherit (pkgs) ipset wget;
inherit (config.services.blocklist-updater) ipSetName ipV6SetName;
in ''
echo "Clearing ${ipSetName} ip-set..."
${ipset}/bin/ipset flush "${ipSetName}"
${ipset}/bin/ipset flush "${ipV6SetName}"
''
