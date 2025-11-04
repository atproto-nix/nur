# ==============================================================================
# PLC Bundle NixOS Modules
# ==============================================================================
#
# This directory contains NixOS service modules for plcbundle.
#
# Available modules:
# - plcbundle: Main PLC Bundle archiving and serving service
#
# ==============================================================================

{ pkgs, lib, config, ... }:

{
  # Import all plcbundle service modules
  imports = [
    ./plcbundle.nix
  ];
}
