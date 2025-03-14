{ pkgs, config }: let
inherit (pkgs) ipset iptables;
inherit (config.services.blacklist-updater) ipSetName ipV6SetName;
in ''
echo "Running blacklist initializer"

# Stop if the set already exists
echo "Checking if ip-set ${ipSetName} already exists"

if ! ${ipset}/bin/ipset -L ${ipSetName} >/dev/null 2>&1; then
    echo "${ipSetName} doesn't exist. Creating."

    ${ipset}/bin/ipset create "${ipSetName}" hash:ip hashsize 262144

    # Blacklist all addresses from this ip set
    ${iptables}/bin/iptables -I INPUT -m set --match-set ${ipSetName} src -j DROP
    ${iptables}/bin/iptables -I INPUT -m set --match-set ${ipSetName} src -j LOG --log-prefix "FW_DROPPED: "

    ${iptables}/bin/iptables -I FORWARD -m set --match-set ${ipSetName} src -j DROP
    ${iptables}/bin/iptables -I FORWARD -m set --match-set ${ipSetName} src -j LOG --log-prefix "FW_DROPPED: "

    ${iptables}/bin/iptables -t raw -I PREROUTING -m set --match-set ${ipSetName} src -j DROP
    ${iptables}/bin/iptables -t raw -I PREROUTING -m set --match-set ${ipSetName} src -j LOG --log-prefix "FW_DROPPED: "
fi

if ! ${ipset}/bin/ipset -L ${ipV6SetName} >/dev/null 2>&1; then
    echo "${ipV6SetName} doesn't exist. Creating."

    ${ipset}/bin/ipset create "${ipV6SetName}" hash:ip hashsize 262144 family inet6

    # Blacklist all addresses from this ip set
    ${iptables}/bin/ip6tables -I INPUT -m set --match-set ${ipV6SetName} src -j DROP
    ${iptables}/bin/ip6tables -I INPUT -m set --match-set ${ipV6SetName} src -j LOG --log-prefix "FW_DROPPED: "

    ${iptables}/bin/ip6tables -I FORWARD -m set --match-set ${ipV6SetName} src -j DROP
    ${iptables}/bin/ip6tables -I FORWARD -m set --match-set ${ipV6SetName} src -j LOG --log-prefix "FW_DROPPED: "

    ${iptables}/bin/ip6tables -t raw -I PREROUTING -m set --match-set ${ipV6SetName} src -j DROP
    ${iptables}/bin/ip6tables -t raw -I PREROUTING -m set --match-set ${ipV6SetName} src -j LOG --log-prefix "FW_DROPPED: "
fi
''
