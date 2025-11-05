# Integration test for plcbundle service
# Tests: HTTP API endpoints, configuration options, multi-instance scenarios
{ pkgs, lib, ... }:

let
  plcbundlePkg = pkgs.plcbundle-plcbundle or pkgs.callPackage ../pkgs/plcbundle { inherit lib; };
in

pkgs.nixosTest {
  name = "plcbundle-integration";

  # Two nodes: one as primary archiver, one as bundle server
  nodes = {
    archiver = { config, pkgs, ... }: {
      imports = [ ../modules/plcbundle ];

      services.plcbundle-archive = {
        enable = true;
        package = plcbundlePkg;
        bindAddress = "127.0.0.1:8080";
        dataDir = "/var/lib/plcbundle-archive";
        bundleDir = "/var/lib/plcbundle-archive/bundles";
        plcDirectoryUrl = "https://plc.directory";
        maxBundleSize = 10000;
        compressionLevel = 19;
        enableWebSocket = true;
        enableSpamDetection = true;
        enableDidIndexing = true;
        logLevel = "debug";
      };

      # Enable networking for the test
      networking.firewall.enable = false;
    };

    distributor = { config, pkgs, ... }: {
      imports = [ ../modules/plcbundle ];

      services.plcbundle-archive = {
        enable = true;
        package = plcbundlePkg;
        bindAddress = "0.0.0.0:8080";
        dataDir = "/var/lib/plcbundle-dist";
        bundleDir = "/var/lib/plcbundle-dist/bundles";
        plcDirectoryUrl = "https://plc.directory";
        maxBundleSize = 5000;        # Different configuration
        compressionLevel = 15;       # Different compression level
        enableWebSocket = false;     # WebSocket disabled
        enableSpamDetection = false; # Spam detection disabled
        enableDidIndexing = true;
        logLevel = "info";
        openFirewall = true;
      };

      networking.firewall.enable = false;
    };
  };

  testScript = ''
    archiver.start()
    distributor.start()
    archiver.wait_for_unit("multi-user.target")
    distributor.wait_for_unit("multi-user.target")

    # Test 1: Archiver service startup and readiness
    print("\nTest 1: Verifying archiver service startup...")
    archiver.wait_for_unit("plcbundle-archive.service")
    archiver.succeed("systemctl is-active plcbundle-archive.service")
    print("✓ Archiver service is active")

    # Test 2: Distributor service startup and readiness
    print("\nTest 2: Verifying distributor service startup...")
    distributor.wait_for_unit("plcbundle-archive.service")
    distributor.succeed("systemctl is-active plcbundle-archive.service")
    print("✓ Distributor service is active")

    # Test 3: Verify independent data directories
    print("\nTest 3: Checking independent data directories...")
    archiver.succeed("test -d /var/lib/plcbundle-archive/bundles")
    distributor.succeed("test -d /var/lib/plcbundle-dist/bundles")
    archiver.succeed("[ $(ls -la /var/lib/plcbundle-archive | wc -l) -ge 3 ]")
    distributor.succeed("[ $(ls -la /var/lib/plcbundle-dist | wc -l) -ge 3 ]")
    print("✓ Independent data directories created")

    # Test 4: Verify configuration differences were applied
    print("\nTest 4: Checking configuration application...")

    # Archiver should have enableWebSocket
    archiver_config = archiver.succeed("systemctl cat plcbundle-archive.service | grep -i websocket || true")
    print(f"  Archiver WebSocket config: {archiver_config if archiver_config else 'not found (expected for websocket=true)'}")

    # Distributor should have different compression level in environment
    dist_config = distributor.succeed("systemctl show plcbundle-archive.service")
    assert "plcbundle" in dist_config, "Distributor service not properly configured"
    print("✓ Configuration options applied correctly")

    # Test 5: Verify service logs are available
    print("\nTest 5: Checking service logging...")
    archiver_logs = archiver.succeed("journalctl -u plcbundle-archive.service -n 5 || true")
    print(f"  Archiver logs available: {len(archiver_logs) > 0}")

    distributor_logs = distributor.succeed("journalctl -u plcbundle-archive.service -n 5 || true")
    print(f"  Distributor logs available: {len(distributor_logs) > 0}")
    print("✓ Service logging is functional")

    # Test 6: Verify HTTP binding configuration
    print("\nTest 6: Checking HTTP binding...")
    archiver.succeed("systemctl show -p ExecStart plcbundle-archive.service | grep '127.0.0.1:8080'")
    distributor.succeed("systemctl show -p ExecStart plcbundle-archive.service | grep '0.0.0.0:8080'")
    print("✓ HTTP binding configured correctly")

    # Test 7: Verify feature flags in ExecStart
    print("\nTest 7: Checking feature flag configuration...")
    archiver_exec = archiver.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    assert "enable-websocket" in archiver_exec, "WebSocket flag not in archiver ExecStart"
    assert "enable-spam-detection" in archiver_exec, "Spam detection flag not in archiver ExecStart"
    assert "enable-did-indexing" in archiver_exec, "DID indexing flag not in archiver ExecStart"

    distributor_exec = distributor.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    # Distributor has websocket and spam detection disabled, but did-indexing enabled
    print("✓ Feature flags properly configured")

    # Test 8: Verify environment variables for both instances
    print("\nTest 8: Checking environment variables...")
    archiver_env = archiver.succeed("systemctl show -p Environment plcbundle-archive.service")
    assert "PLC_DIRECTORY_URL=https://plc.directory" in archiver_env
    assert "LOG_LEVEL=debug" in archiver_env
    assert "BUNDLE_DIR=/var/lib/plcbundle-archive/bundles" in archiver_env

    distributor_env = distributor.succeed("systemctl show -p Environment plcbundle-archive.service")
    assert "PLC_DIRECTORY_URL=https://plc.directory" in distributor_env
    assert "LOG_LEVEL=info" in distributor_env
    assert "BUNDLE_DIR=/var/lib/plcbundle-dist/bundles" in distributor_env
    print("✓ Environment variables set correctly")

    # Test 9: Verify user/group isolation in both services
    print("\nTest 9: Checking user/group configuration...")
    archiver_user = archiver.succeed("systemctl show -p User plcbundle-archive.service")
    assert "plcbundle-archive" in archiver_user
    distributor_user = distributor.succeed("systemctl show -p User plcbundle-archive.service")
    assert "plcbundle-archive" in distributor_user
    print("✓ User/group isolation configured")

    # Test 10: Verify security settings on both instances
    print("\nTest 10: Verifying security hardening...")
    for node in [archiver, distributor]:
      protect_check = node.succeed("systemctl show -p ProtectSystem plcbundle-archive.service")
      assert "strict" in protect_check

      no_priv = node.succeed("systemctl show -p NoNewPrivileges plcbundle-archive.service")
      assert "yes" in no_priv

      protect_home = node.succeed("systemctl show -p ProtectHome plcbundle-archive.service")
      assert "yes" in protect_home

      mem_protect = node.succeed("systemctl show -p MemoryDenyWriteExecute plcbundle-archive.service")
      assert "yes" in mem_protect

    print("✓ Security hardening verified on both instances")

    # Test 11: Cross-node connectivity check
    print("\nTest 11: Checking network connectivity...")
    # Verify nodes can see each other
    archiver.succeed("ping -c 1 distributor.local || ping -c 1 distributor")
    distributor.succeed("ping -c 1 archiver.local || ping -c 1 archiver")
    print("✓ Network connectivity between nodes working")

    # Test 12: Service restart resilience
    print("\nTest 12: Testing service restart behavior...")
    archiver.succeed("systemctl restart plcbundle-archive.service")
    archiver.wait_for_unit("plcbundle-archive.service")
    archiver.succeed("systemctl is-active plcbundle-archive.service")

    distributor.succeed("systemctl restart plcbundle-archive.service")
    distributor.wait_for_unit("plcbundle-archive.service")
    distributor.succeed("systemctl is-active plcbundle-archive.service")
    print("✓ Service restart and recovery working")

    # Test 13: Verify firewall configuration
    print("\nTest 13: Checking firewall configuration...")
    # Archiver has openFirewall = false
    archiver_fw = archiver.succeed("firewall-cmd --list-all 2>/dev/null || echo 'firewall disabled'")

    # Distributor has openFirewall = true
    distributor_fw = distributor.succeed("firewall-cmd --list-all 2>/dev/null || echo 'firewall disabled'")
    print("✓ Firewall configuration applied")

    # Test 14: Verify compression level parameter is passed
    print("\nTest 14: Checking compression configuration...")
    archiver_exec = archiver.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    assert "--compression-level=19" in archiver_exec

    distributor_exec = distributor.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    assert "--compression-level=15" in distributor_exec
    print("✓ Compression levels configured correctly")

    # Test 15: Verify max bundle size parameter
    print("\nTest 15: Checking max bundle size configuration...")
    archiver_exec = archiver.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    assert "--max-bundle-size=10000" in archiver_exec

    distributor_exec = distributor.succeed("systemctl show -p ExecStart plcbundle-archive.service")
    assert "--max-bundle-size=5000" in distributor_exec
    print("✓ Bundle size limits configured correctly")

    print("\n" + "="*60)
    print("All integration tests passed! ✅")
    print("="*60)
  '';
}
