{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./rsky/pds.nix
    ./rsky/relay.nix
    ./rsky/feedgen.nix
    ./rsky/satnav.nix
    ./rsky/firehose.nix
    ./rsky/jetstream-subscriber.nix
    ./rsky/labeler.nix
    # ./rsky/pdsadmin.nix  # Temporarily disabled - see package notes
    # Individual service modules will be imported here
  ];

  options.blacksky = {
    enable = mkEnableOption "Blacksky AT Protocol services";
  };

  config = mkIf config.blacksky.enable {
    services.blacksky.pds.enable = mkDefault false;
    services.blacksky.relay.enable = mkDefault false;
    services.blacksky.feedgen.enable = mkDefault false;
    services.blacksky.satnav.enable = mkDefault false;
    services.blacksky.firehose.enable = mkDefault false;
    services.blacksky.jetstream-subscriber.enable = mkDefault false;
    services.blacksky.labeler.enable = mkDefault false;
    # services.blacksky.pdsadmin.enable = mkDefault false;  # Temporarily disabled
  };
}