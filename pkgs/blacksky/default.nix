{ pkgs, craneLib, buildYarnPackage, ... }:

import ./rsky { inherit pkgs craneLib buildYarnPackage; }