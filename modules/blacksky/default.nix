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
    # Individual service modules will be imported here
  ];

  options.blacksky = {
    enable = mkEnableOption "Blacksky AT Protocol services";
  };

  config = mkIf config.blacksky.enable {
    blacksky.pds.enable = false;
    blacksky.feedgen.enable = false;
    blacksky.satnav.enable = false;
    blacksky.firehose.enable = false;
    blacksky.jetstream-subscriber.enable = false;
    blacksky.labeler.enable = false;
  };
}