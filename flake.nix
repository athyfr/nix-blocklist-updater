{
  description = "A service for updating blocklists of IPs";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    lib = nixpkgs.lib;
    blocklistModule = import ./.;
  in {
    nixosModules = rec {
      blocklist-updater = blocklistModule;
      default = blocklist-updater;
    };
  };
}
