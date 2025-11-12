# fetchFromTangled utility for Tangled.org repository access
#
# This is a fork of fetchFromGitHub, but adapted for Tangled.org repositories
# with a few key changes due to incompatibilities. All private/authentication
# concepts have been removed as they don't apply to Tangled.org.
#
# Usage:
#   fetchFromTangled {
#     domain = "tangled.org";  # optional, default
#     owner = "@owner-name";   # Tangled.org uses @-prefixed owners
#     repo = "repo-name";
#     rev = "commit-hash";     # provide one of rev or tag
#     # OR
#     tag = "v1.0.0";          # not both
#
#     # Optional: fetchgit options for submodule/git support
#     fetchSubmodules = false;
#     leaveDotGit = false;
#     deepClone = false;
#     forceFetchGit = false;
#     fetchLFS = false;
#     sparseCheckout = [];
#   }

{ lib, repoRevToNameMaybe, fetchgit, fetchzip }:

lib.makeOverridable (
  {
    domain ? "tangled.org",
    owner,
    repo,
    rev ? null,
    tag ? null,

    # TODO: add back when doing FP
    # name ? repoRevToNameMaybe repo (lib.revOrTag rev tag) "tangled",

    # fetchgit options
    fetchSubmodules ? false,
    leaveDotGit ? false,
    deepClone ? false,
    forceFetchGit ? false,
    fetchLFS ? false,
    sparseCheckout ? [ ],

    passthru ? { },
    meta ? { },
    ...
  }@args:

  assert lib.assertMsg (lib.xor (tag != null) (rev != null))
    "fetchFromTangled requires one of either `rev` or `tag` to be provided (not both).";

  let
    position = (
      if args.meta.description or null != null then
        builtins.unsafeGetAttrPos "description" args.meta
      else if tag != null then
        builtins.unsafeGetAttrPos "tag" args
      else
        builtins.unsafeGetAttrPos "rev" args
    );

    baseUrl = "https://${domain}/${owner}/${repo}";

    newMeta =
      meta
      // {
        homepage = meta.homepage or baseUrl;
      }
      // lib.optionalAttrs (position != null) {
        # to indicate where derivation originates, similar to make-derivation.nix's mkDerivation
        position = "${position.file}:${toString position.line}";
      };

    passthruAttrs = removeAttrs args [
      "domain"
      "owner"
      "repo"
      "tag"
      "rev"
      "fetchSubmodules"
      "forceFetchGit"
    ];

    useFetchGit =
      fetchSubmodules || leaveDotGit || deepClone || forceFetchGit || fetchLFS || (sparseCheckout != [ ]);

    # We prefer fetchzip in cases we don't need submodules as the hash
    # is more stable in that case.
    fetcher =
      if useFetchGit then
        fetchgit
      # fetchzip may not be overridable when using external tools, for example nix-prefetch
      else if fetchzip ? override then
        fetchzip.override { withUnzip = false; }
      else
        fetchzip;

    fetcherArgs =
      finalAttrs:
      passthruAttrs
      // (
        if useFetchGit then
          {
            inherit
              tag
              rev
              deepClone
              fetchSubmodules
              sparseCheckout
              fetchLFS
              leaveDotGit
              ;
            url = baseUrl;
            inherit passthru;
            derivationArgs = {
              inherit
                domain
                owner
                repo
                ;
            };
          }
        else
          let
            revWithTag = finalAttrs.rev;
          in
          {
            url = "${baseUrl}/archive/${revWithTag}";
            extension = "tar.gz";

            derivationArgs = {
              inherit
                domain
                owner
                repo
                tag
                ;
              rev = fetchgit.getRevWithTag {
                inherit (finalAttrs) tag;
                rev = finalAttrs.revCustom;
              };
              revCustom = rev;
            };

            passthru = {
              gitRepoUrl = baseUrl;
            }
            // passthru;
          }
      )
      // {
        name =
          args.name
            or (repoRevToNameMaybe finalAttrs.repo (lib.revOrTag finalAttrs.revCustom finalAttrs.tag) "tangled");
        meta = newMeta;
      };
  in

  fetcher fetcherArgs
)
