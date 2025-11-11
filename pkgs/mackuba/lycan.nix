{ lib
, stdenv
, fetchFromTangled
, ruby_3_3
, bundlerApp
, makeWrapper
}:

let
  ruby = ruby_3_3;
  src = fetchFromTangled {
    domain = "tangled.org";
    owner = "@mackuba.eu";
    repo = "lycan";
    rev = "ceea606fba2e03905dbb3be7997fc6a3298cda58";
    hash = "sha256-3CutDYVYkfxuU1SrqtuBeocS+TIPUOM2W4BfIIfaNqs=";
    forceFetchGit = true; # Tangled doesn't support /archive endpoint
  };
  gemset = {
    activemodel = {
      dependencies = ["activesupport"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1pc4ffzs2ay4jddhvmsy10z9kxgyrkvf1n35kxr2bmr8y0dbk638";
        type = "gem";
      };
      version = "7.2.2.2";
    };
    activerecord = {
      dependencies = ["activemodel" "activesupport" "timeout"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0058rmkm9774jmx2pp45ppss33aqc22qm0ppv7zw7w8qj14y3cg6";
        type = "gem";
      };
      version = "7.2.2.2";
    };
    activesupport = {
      dependencies = ["base64" "benchmark" "bigdecimal" "concurrent-ruby" "connection_pool" "drb" "i18n" "logger" "minitest" "securerandom" "tzinfo"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1w5y2nm4v5q39ivh2a7lbw6zxz1q6lh6i3zvfbrz29wh7nxq8kn5";
        type = "gem";
      };
      version = "7.2.2.2";
    };
    base32 = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1fjs0l3c5g9qxwp43kcnhc45slx29yjb6m6jxbb2x1krgjmi166b";
        type = "gem";
      };
      version = "0.3.4";
    };
    base58 = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1gpk3g32c3w976k9kax2y13bm274s710jlqs1nnjkd58pp9wb9gx";
        type = "gem";
      };
      version = "0.2.3";
    };
    base64 = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
        type = "gem";
      };
      version = "0.3.0";
    };
    bcrypt_pbkdf = {
      groups = ["development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "04rb3rp9bdxn1y3qiflfpj7ccwb8ghrfbydh5vfz1l9px3fpg41g";
        type = "gem";
      };
      version = "1.1.1";
    };
    benchmark = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1kicilpma5l0lwayqjb5577bm0hbjndj2gh150xz09xsgc1l1vyl";
        type = "gem";
      };
      version = "0.4.1";
    };
    bigdecimal = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1p2szbr4jdvmwaaj2kxlbv1rp0m6ycbgfyp0kjkkkswmniv5y21r";
        type = "gem";
      };
      version = "3.2.2";
    };
    capistrano = {
      dependencies = ["highline" "net-scp" "net-sftp" "net-ssh" "net-ssh-gateway"];
      groups = ["development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0x4vcxqrnv3lwmqhnwcqpddidy4h6860xiinj9sq7zgipli540c0";
        type = "gem";
      };
      version = "2.15.11";
    };
    cbor = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1w3d5dhx4vjd707ihkcmq7fy78p5fgawcjdqw2byxnfw32gzgkbr";
        type = "gem";
      };
      version = "0.5.10.1";
    };
    "concurrent-ruby" = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1ipbrgvf0pp6zxdk5ascp6i29aybz2bx9wdrlchjmpx6mhvkwfw1";
        type = "gem";
      };
      version = "1.3.5";
    };
    connection_pool = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0nrhsk7b3sjqbyl1cah6ibf1kvi3v93a7wf4637d355hp614mmyg";
        type = "gem";
      };
      version = "2.5.3";
    };
    date = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0kz6mc4b9m49iaans6cbx031j9y7ldghpi5fzsdh0n3ixwa8w9mz";
        type = "gem";
      };
      version = "3.4.1";
    };
    didkit = {
      groups = ["default"];
      platforms = [];
      source = {
        fetchSubmodules = false;
        rev = "ec23c98d73a023eeb6d38a41879dc36b7f612b93";
        sha256 = "0q17rvq7g6x26sqjr1gfaqxpchgrcm4dh3wzh7i2xqkyhllw25by";
        type = "git";
        url = "https://tangled.sh/@mackuba.eu/didkit";
      };
      version = "0.2.3";
    };
    dotenv = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1hwjsddv666wpp42bip3fqx7c5qq6s8lwf74dj71yn7d1h37c4cy";
        type = "gem";
      };
      version = "3.1.8";
    };
    drb = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0wrkl7yiix268s2md1h6wh91311w95ikd8fy8m5gx589npyxc00b";
        type = "gem";
      };
      version = "2.2.3";
    };
    ed25519 = {
      groups = ["development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "01n5rbyws1ijwc5dw7s88xx3zzacxx9k97qn8x11b6k8k18pzs8n";
        type = "gem";
      };
      version = "1.4.0";
    };
    erb = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "03vcq8g8rxdq8njp9j9k9fxwjw19q4m08c7lxjs0yc6l8f0ja3yk";
        type = "gem";
      };
      version = "5.0.2";
    };
    eventmachine = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0wh9aqb0skz80fhfn66lbpr4f86ya2z5rx6gm5xlfhd05bj1ch4r";
        type = "gem";
      };
      version = "1.2.7";
    };
    "faye-websocket" = {
      dependencies = ["eventmachine" "websocket-driver"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1qa2mf22893cf4w5zfqmmwli2rjpjrr51r7fp89hlv9hs3y7v7xd";
        type = "gem";
      };
      version = "0.12.0";
    };
    highline = {
      dependencies = ["reline"];
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0jmvyhjp2v3iq47la7w6psrxbprnbnmzz0hxxski3vzn356x7jv7";
        type = "gem";
      };
      version = "3.1.2";
    };
    i18n = {
      dependencies = ["concurrent-ruby"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "03sx3ahz1v5kbqjwxj48msw3maplpp2iyzs22l4jrzrqh4zmgfnf";
        type = "gem";
      };
      version = "1.14.7";
    };
    "io-console" = {
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1jszj95hazqqpnrjjzr326nn1j32xmsc9xvd97mbcrrgdc54858y";
        type = "gem";
      };
      version = "0.8.1";
    };
    irb = {
      dependencies = ["pp" "rdoc" "reline"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1fpxa2m83rb7xlzs57daqwnzqjmz6j35xr7zb15s73975sak4br2";
        type = "gem";
      };
      version = "1.15.2";
    };
    jwt = {
      dependencies = ["base64"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0dfm4bhl4fzn076igh0bmh2v1vphcrxdv6ldc46hdd3bkbqr2sdg";
        type = "gem";
      };
      version = "3.1.2";
    };
    logger = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
        type = "gem";
      };
      version = "1.7.0";
    };
    minisky = {
      dependencies = ["base64"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "09d2wr9s5a9llwvf153cmjp3x7b6xaw01fxvjmn38c71g499z1b5";
        type = "gem";
      };
      version = "0.5.0";
    };
    minitest = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0mn7q9yzrwinvfvkyjiz548a4rmcwbmz2fn9nyzh4j1snin6q6rr";
        type = "gem";
      };
      version = "5.25.5";
    };
    mustermann = {
      dependencies = ["ruby2_keywords"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "08ma2fmxlm6i7lih4mc3har2fzsbj1pl4hhva65kljf6nfvdryl5";
        type = "gem";
      };
      version = "3.0.4";
    };
    "net-scp" = {
      dependencies = ["net-ssh"];
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0p8s7l4pr6hkn0l6rxflsc11alwi1kfg5ysgvsq61lz5l690p6x9";
        type = "gem";
      };
      version = "4.1.0";
    };
    "net-sftp" = {
      dependencies = ["net-ssh"];
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0r33aa2d61hv1psm0l0mm6ik3ycsnq8symv7h84kpyf2b7493fv5";
        type = "gem";
      };
      version = "4.0.0";
    };
    "net-ssh" = {
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1w1ypxa3n6mskkwb00b489314km19l61p5h3bar6zr8cng27c80p";
        type = "gem";
      };
      version = "7.3.0";
    };
    "net-ssh-gateway" = {
      dependencies = ["net-ssh"];
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1l3v761y32aw0n8lm0c0m42lr4ay8cq6q4sc5yc68b9fwlfvb70x";
        type = "gem";
      };
      version = "2.0.0";
    };
    nio4r = {
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1a9www524fl1ykspznz54i0phfqya4x45hqaz67in9dvw1lfwpfr";
        type = "gem";
      };
      version = "2.7.4";
    };
    pg = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0swf0a0r2xryx788q09w4zcwdq7v1pwq5fvkgr9m8abhbxgaf472";
        type = "gem";
      };
      version = "1.6.1";
    };
    pp = {
      dependencies = ["prettyprint"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1zxnfxjni0r9l2x42fyq0sqpnaf5nakjbap8irgik4kg1h9c6zll";
        type = "gem";
      };
      version = "0.6.2";
    };
    prettyprint = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "14zicq3plqi217w6xahv7b8f7aj5kpxv1j1w98344ix9h5ay3j9b";
        type = "gem";
      };
      version = "0.2.0";
    };
    psych = {
      dependencies = ["date" "stringio"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0vii1xc7x81hicdbp7dlllhmbw5w3jy20shj696n0vfbbnm2hhw1";
        type = "gem";
      };
      version = "5.2.6";
    };
    puma = {
      dependencies = ["nio4r"];
      groups = ["development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "07pajhv7pqz82kcjc6017y4d0hwz5kp746cydpx1npd79r56xddr";
        type = "gem";
      };
      version = "6.6.1";
    };
    rack = {
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "04inzfa1psgl8mywgzaks31am1zh00lyc0mf3zb5jv399m8j3kbr";
        type = "gem";
      };
      version = "3.2.0";
    };
    "rack-protection" = {
      dependencies = ["base64" "logger" "rack"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0sniswjyi0yn949l776h7f67rvx5w9f04wh69z5g19vlsnjm98ji";
        type = "gem";
      };
      version = "4.1.1";
    };
    "rack-session" = {
      dependencies = ["base64" "rack"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1sg4laz2qmllxh1c5sqlj9n1r7scdn08p3m4b0zmhjvyx9yw0v8b";
        type = "gem";
      };
      version = "2.1.1";
    };
    rackup = {
      dependencies = ["rack"];
      groups = ["development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "13brkq5xkj6lcdxj3f0k7v28hgrqhqxjlhd4y2vlicy5slgijdzp";
        type = "gem";
      };
      version = "2.2.1";
    };
    rainbow = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0smwg4mii0fm38pyb5fddbmrdpifwv22zv3d3px2xx497am93503";
        type = "gem";
      };
      version = "3.1.1";
    };
    rake = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "14s4jdcs1a4saam9qmzbsa2bsh85rj9zfxny5z315x3gg0nhkxcn";
        type = "gem";
      };
      version = "13.3.0";
    };
    rdoc = {
      dependencies = ["erb" "psych"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "09lj8d16wx5byj0nbcb9wc6v9farsvgn98n91kknm18g2ggl9pcz";
        type = "gem";
      };
      version = "6.14.2";
    };
    reline = {
      dependencies = ["io-console"];
      groups = ["default" "development"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0ii8l0q5zkang3lxqlsamzfz5ja7jc8ln905isfdawl802k2db8x";
        type = "gem";
      };
      version = "0.6.2";
    };
    ruby2_keywords = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1vz322p8n39hz3b4a9gkmz9y7a5jaz41zrm2ywf31dvkqm03glgz";
        type = "gem";
      };
      version = "0.0.5";
    };
    securerandom = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1cd0iriqfsf1z91qg271sm88xjnfd92b832z49p1nd542ka96lfc";
        type = "gem";
      };
      version = "0.4.1";
    };
    sinatra = {
      dependencies = ["logger" "mustermann" "rack" "rack-protection" "rack-session" "tilt"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "002dkzdc1xqhvz5sdnj4vb0apczhs07mnpgq4kkd5dd1ka2pp6af";
        type = "gem";
      };
      version = "4.1.1";
    };
    "sinatra-activerecord" = {
      dependencies = ["activerecord" "sinatra"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "049qr5qi3nflq9xvpf4hhdshndim07hgnzl79wmx0i52vz155wwr";
        type = "gem";
      };
      version = "2.0.28";
    };
    skyfall = {
      dependencies = ["base32" "base64" "cbor" "eventmachine" "faye-websocket"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "17rv7dk1z03radmvfm8hv9ms2yfdixgngrl2k4s5a2fa8xzax77j";
        type = "gem";
      };
      version = "0.6.0";
    };
    stringio = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "1yh78pg6lm28c3k0pfd2ipskii1fsraq46m6zjs5yc9a4k5vfy2v";
        type = "gem";
      };
      version = "3.1.7";
    };
    tilt = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0w27v04d7rnxjr3f65w1m7xyvr6ch6szjj2v5wv1wz6z5ax9pa9m";
        type = "gem";
      };
      version = "2.6.1";
    };
    timeout = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "03p31w5ghqfsbz5mcjzvwgkw3h9lbvbknqvrdliy8pxmn9wz02cm";
        type = "gem";
      };
      version = "0.4.3";
    };
    tzinfo = {
      dependencies = ["concurrent-ruby"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "16w2g84dzaf3z13gxyzlzbf748kylk5bdgg3n1ipvkvvqy685bwd";
        type = "gem";
      };
      version = "2.0.6";
    };
    "websocket-driver" = {
      dependencies = ["base64" "websocket-extensions"];
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0qj9dmkmgahmadgh88kydb7cv15w13l1fj3kk9zz28iwji5vl3gd";
        type = "gem";
      };
      version = "0.8.0";
    };
    "websocket-extensions" = {
      groups = ["default"];
      platforms = [];
      source = {
        remotes = ["https://rubygems.org"];
        sha256 = "0hc2g9qps8lmhibl5baa91b4qx8wqw872rgwagml78ydj8qacsqw";
        type = "gem";
      };
      version = "0.1.5";
    };
  };

  # Create gemdir with the inline gemset
  gemdir = stdenv.mkDerivation {
    name = "lycan-gemdir";
    inherit src;
    phases = [ "installPhase" ];
    installPhase = ''
      cp -r $src $out
      chmod -R +w $out
      cp $out/gemset.nix $out/gemset.nix.bak 2>/dev/null || true
      cat > $out/gemset.nix <<'GEMSET_EOF'
${lib.generators.toPretty {} gemset}
GEMSET_EOF
    '';
  };
  # Build the bundler environment
  bundlerEnv = bundlerApp {
    pname = "rackup";
    inherit gemdir ruby;
    exes = [ "rackup" "rake" ];
  };
in

# Wrap the bundler app with custom executables
stdenv.mkDerivation {
  pname = "lycan";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    # Copy application files
    mkdir -p $out/share/lycan
    cp -r $src/* $out/share/lycan/
    chmod -R u+w $out/share/lycan

    # Patch server.rb to configure Rack::Protection with allowed hosts from env
    sed -i '/set :port, 3000/a\
\
  # Configure Rack::Protection to allow specified hosts\
  if ENV["RACK_PROTECTION_ALLOWED_HOSTS"]\
    allowed_hosts = ENV["RACK_PROTECTION_ALLOWED_HOSTS"].split(",").map(&:strip)\
    set :protection, :host_authorization => { :permitted_hosts => allowed_hosts }\
  end' $out/share/lycan/app/server.rb

    # Patch init.rb to fix SSL certificate verification for NixOS
    # Ruby's OpenSSL has issues with CRL checking in NixOS
    sed -i '/RubyVM::YJIT.enable/a\
\
# Monkey patch Net::HTTP to fix SSL for NixOS\
# See: https://github.com/NixOS/nixpkgs/issues/14369\
require '"'"'net/http'"'"'\
require '"'"'openssl'"'"'\
\
module Net\
  class HTTP\
    alias_method :original_start, :start\
\
    def start(&block)\
      if use_ssl?\
        self.cert_store = OpenSSL::X509::Store.new\
        self.cert_store.set_default_paths\
        self.verify_mode = OpenSSL::SSL::VERIFY_PEER\
      end\
      original_start(&block)\
    end\
  end\
end' $out/share/lycan/app/init.rb

    # Create bin directory
    mkdir -p $out/bin

    # Link bundler environment
    ln -s ${bundlerEnv}/bin/rackup $out/bin/.rackup-wrapped
    ln -s ${bundlerEnv}/bin/rake $out/bin/.rake-wrapped

    # Create custom lycan executable
    makeWrapper $out/bin/.rackup-wrapped $out/bin/lycan \
      --chdir "$out/share/lycan"

    # Create rake wrapper for db:migrate
    makeWrapper $out/bin/.rake-wrapped $out/bin/lycan-rake \
      --chdir "$out/share/lycan"
  '';

  passthru = {
    inherit ruby bundlerEnv;
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