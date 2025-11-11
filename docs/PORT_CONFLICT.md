# Port Conflict Issue in Microcosm Services

## Summary

This document outlines a port conflict issue identified in the `big-refactor` branch of the `atproto-nix/nur` repository. Multiple Microcosm services are hardcoded to use the same port `8765` for their Prometheus metrics servers, which prevents them from running simultaneously.

## Affected Services

The following services are affected by this issue:

*   `constellation`
*   `spacedust`
*   `slingshot`
*   `ufos`
*   `who-am-i`

## Problem Description

When attempting to run multiple Microcosm services at the same time, the services fail to start with an "Address already in use" error. This is because they all try to bind to port `8765` for their metrics server.

### Evidence

#### 1. Error Message from `journalctl`

```
thread '<unnamed>' panicked at constellation/src/bin/main.rs:156:22:
called `Result::unwrap()` on an `Err` value: failed to create HTTP listener: Address already in use (os error 98)
```

#### 2. Port Usage Analysis

An analysis of the source code for each service confirms that the metrics port is hardcoded to `8765`.

**`constellation` (`src/bin/main.rs`):**
```rust
fn install_metrics_server() -> Result<()> {
    ...
    let port = 8765;
    ...
        .with_http_listener((host, port))
    ...
}
```

**`spacedust` (`src/main.rs`):**
```rust
fn install_metrics_server() -> Result<(), metrics_exporter_prometheus::BuildError> {
    ...
    let port = 8765;
    ...
        .with_http_listener((host, port))
    ...
}
```

**(Similar code was found in `slingshot`, `ufos`, and `who-am-i`.)**

## Port Usage Summary

Here is a summary of the port usage for the investigated Microcosm services:

| Service | Main Port | Metrics Port | Configurable? |
| :--- | :--- | :--- | :--- |
| `pocket` | 3000 | None | No |
| `quasar` | None | None | N/A |
| `reflector` | 3001 | None | No |
| `slingshot` | 3000 / 443 | 8765 | Main port (via domain option) |
| `ufos` | 9999 | 8765 | No |
| `who-am-i` | 9997 | 8765 | Main port (via `--bind`) |
| `constellation` | 6789 | 8765 | No (in basic module) |

## Proposed Solution

The recommended solution is to make the metrics port configurable for each service. The `constellation-enhanced.nix` module already provides a good example of how this can be done:

1.  **Add a `metrics` submodule to the NixOS module options:**
    ```nix
    metrics = mkOption {
      type = types.submodule {
        options = {
          enable = mkEnableOption "Prometheus metrics endpoint";
          port = mkOption {
            type = types.port;
            default = 9090; // A unique default port
            description = "Metrics endpoint port";
          };
        };
      };
    };
    ```

2.  **Update the service's application code to accept a `--metrics-port` command-line argument.** This is a necessary change in the upstream `microcosm-rs` repository.

3.  **Update the `ExecStart` command in the NixOS module** to pass the configured port to the service binary:
    ```nix
    (optional cfg.metrics.enable [
      "--metrics-port"
      (escapeShellArg (toString cfg.metrics.port))
    ])
    ```

By implementing this for all affected services, the port conflict can be resolved, and users will be able to run multiple Microcosm services with metrics enabled.
