{ lib
, stdenv
, fetchFromTangled
, ruby_3_3
, bundlerEnv
, defaultGemConfig
, makeWrapper
}:

let
  ruby = ruby_3_3;

  # Create a Gemfile environment from the application's Gemfile
  env = bundlerEnv rec {
    name = "lycan-env";
    inherit ruby;

    # Point to the Gemfile in the source
    gemdir = fetchFromTangled {
      domain = "tangled.org";
      owner = "@mackuba.eu";
      repo = "lycan";
      rev = "ceea606e0b6f3ab8e89b7bfdc9e4b7e3c8c4e8df";
      hash = lib.fakeHash;
    };

    gemConfig = defaultGemConfig;
  };

in
stdenv.mkDerivation rec {
  pname = "lycan";
  version = "unstable-2025-01-14";

  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@mackuba.eu";
    repo = "lycan";
    rev = "ceea606e0b6f3ab8e89b7bfdc9e4b7e3c8c4e8df";
    hash = lib.fakeHash;
  };

  nativeBuildInputs = [ makeWrapper ruby ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{share/lycan,bin}

    # Copy all application files
    cp -r . $out/share/lycan/

    # Remove unnecessary files
    rm -rf $out/share/lycan/.git

    # Create wrapper script that sets up the Ruby environment
    makeWrapper ${ruby}/bin/ruby $out/bin/lycan \
      --set GEM_HOME ${env}/${ruby.gemPath} \
      --set GEM_PATH ${env}/${ruby.gemPath} \
      --add-flags "-I$out/share/lycan/lib" \
      --add-flags "$out/share/lycan/config.ru" \
      --add-flags "-p" \
      --add-flags "3000" \
      --chdir "$out/share/lycan"

    # Create db:migrate wrapper
    makeWrapper ${env}/bin/rake $out/bin/lycan-rake \
      --chdir "$out/share/lycan"

    # Create console wrapper
    makeWrapper ${env}/bin/irb $out/bin/lycan-console \
      --add-flags "-I$out/share/lycan/lib" \
      --add-flags "-r$out/share/lycan/app/init.rb" \
      --chdir "$out/share/lycan"

    runHook postInstall
  '';

  passthru = {
    rubyEnv = env;
    inherit ruby;
  };

  meta = with lib; {
    description = "Lycan - Custom feed generator for AT Protocol / Bluesky";
    longDescription = ''
      Lycan is a Ruby/Sinatra application for creating custom feeds on the AT Protocol.
      It provides a feed generator service that can be used with Bluesky and other
      ATProto clients.

      Features:
      - Custom feed generation based on user subscriptions
      - Firehose integration for real-time updates via Skyfall
      - Post importing and indexing
      - PostgreSQL database backend
      - OAuth authentication support
      - Uses minisky, didkit, and skyfall gems for ATProto integration

      Dependencies:
      - Ruby 3.3+
      - PostgreSQL database
      - Sinatra web framework
      - ActiveRecord ORM

      Environment variables required:
      - SERVER_HOSTNAME: Hostname for the server (default: lycan.feeds.blue)
      - DATABASE_URL: PostgreSQL connection string (required)
      - RELAY_HOST: ATProto relay host (default: bsky.network)
      - APPVIEW_HOST: AppView host (default: public.api.bsky.app)
      - FIREHOSE_USER_AGENT: User agent for firehose connections (optional)

      Commands:
      - lycan: Start the web server
      - lycan-rake: Run rake tasks (e.g., db:migrate)
      - lycan-console: Interactive Ruby console with app loaded
    '';
    homepage = "https://tangled.org/@mackuba.eu/lycan";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
    mainProgram = "lycan";
  };
}
