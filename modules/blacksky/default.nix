{ ... }:

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
  ];
}