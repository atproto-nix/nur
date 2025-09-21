{ pkgs, craneLib, buildYarnPackage, ... }:

pkgs.callPackage ./rsky { inherit craneLib buildYarnPackage; }