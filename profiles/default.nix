# ATProto Deployment Profiles
# Pre-configured deployment profiles for different ATProto use cases
{
  imports = [
    ./pds-simple.nix
    ./pds-managed.nix
    ./pds-enterprise.nix
    ./tangled-deployment.nix
  ];
}