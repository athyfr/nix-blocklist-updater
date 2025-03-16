{ pkgs, config }:
let
  inherit (pkgs) ipset wget;
  inherit (config.services.blocklist-updater)
    blocklists
    ipSetName
    ipV6SetName
    blocklistedIPs
    ;
in
''
  # Clear ipset from previous address.
  # Ignore if it fails, because we don't care

  set -e
  urls=(
    ${blocklists}
  )

  # Output file
  BLFILE="/tmp/ipblocklist.txt"
  BLFILE_PROCESSED="/tmp/ipblocklist_processed.txt"

  # Empty the output file if it exists
  > "$BLFILE"

  # Download the blocklist and add it to a file
  for url in "''${urls[@]}"; do
    echo "Downloading blocklist '$url'..."
    ${wget}/bin/wget -q -O - "$url" >> "$BLFILE"
    echo >> "$BLFILE" # Add a newline separator
  done

  # blocklist manual ips
  echo "${blocklistedIPs}">> $BLFILE

  ${import ./clear_blocklist.nix { inherit pkgs config; }}

  echo "Updating ip:s to ${ipSetName} ip-set"
  # Create an ip set and add each ip to it one by one

  # IPv4 and IPv6 regex patterns with CIDR notation support - WARNING: might not be correct for all IPs (e.g. ignore valid ones or accept wrong ones), but seems to work fine
  # Also supports hosts files, as well as plain lists of domains.
  ipv4_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$"
  ipv6_regex="^([0-9a-fA-F:]+::?[0-9a-fA-F]*)+(\/[0-9]{1,3})?$"
  domain_regex"^([A-Za-z0-9-]+(?<!-)\.)+[A-Za-z0-9-]+$"
  host_regex"$^0\.0\.0\.0 ''${domain_regex:1}"

  # Define the functions to be used.
  blockIPv4 () {
      echo -exist add "${ipSetName}" "$1"
  }

  blockIPv6 () {
      echo -exist add "${ipV6SetName}" "$1"
  }

  blockDomain () {
      hostIPv4=$(dig $1 A +short)
      while IFS= read -r IP; do
          echo $(blockIPv4 $1)
      done < $hostIPv4s

      hostIPv6=$(dig $1 AAAA +short)
      while IFS= read -r IP; do
          echo $(blockIPv6 $1)
      done < $hostIPv6s
  }

  # Use a temporary buffer to improve performance
  {
      while IFS= read -r IP; do
          if [[ $IP =~ $ipv4_regex ]]; then
              blockIPv4 $IP
          if [[ $IP =~ $ipv6_regex ]]; then
              blockIPv6 $IP
          elif [[ $IP =~ $host_regex ]]; then
              blockDomain ''${IP:8}
          elif [[ $IP =~ $domain_regex ]]; then
              blockDomain $IP
          else
              echo "Warning: Invalid line skipped -> $IP" >&2
          fi
      done < "$BLFILE"
  } > "$BLFILE_PROCESSED"
  ${ipset}/bin/ipset restore < "$BLFILE_PROCESSED"
''
