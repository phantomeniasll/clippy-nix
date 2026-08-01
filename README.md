# clippy-nix

A reproducible Nix package for the
[phantomeniasll/clippy](https://github.com/phantomeniasll/clippy) downstream
fork of Felix Rieseberg's local Clippy assistant.

This wrapper builds the Electron app from source and provides the modern
Vulkan-enabled `llama-server` needed by the fork's Gemma 4 and Qwen3.6
multi-token prediction (MTP) support.

## What the Package Provides

- Electron from the pinned nixpkgs input rather than a downloaded binary.
- A Vulkan-enabled llama.cpp server exposed to Clippy through
  `CLIPPY_LLAMA_SERVER`.
- The runtime libraries needed by Electron on NixOS.
- XWayland launch flags so KWin can honor Clippy's helper-window,
  skip-taskbar, and always-on-top hints. Native Wayland intentionally does not
  expose an application-controlled keep-above protocol.

The package currently supports `x86_64-linux` and expects a working Vulkan
driver plus XWayland when always-on-top behavior is desired.

## Run It

With Nix flakes enabled:

```sh
nix run github:phantomeniasll/clippy-nix
```

The first model download is managed by Clippy and is stored in the user's
application data directory, not in the Nix store.

## Add It to a Flake

```nix
{
  inputs.clippy-nix.url = "github:phantomeniasll/clippy-nix";
  inputs.clippy-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, clippy-nix, ... }: {
    # In a Home Manager module with `pkgs` in scope:
    home.packages = [
      clippy-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
```

To pin or develop a different checkout of the application fork, override the
non-flake `clippy-src` input:

```sh
nix build .#clippy --override-input clippy-src path:../clippy-src
```

## Build Locally

```sh
nix build
nix run
```

The build is intentionally offline after Nix has fetched the locked inputs and
npm dependency closure. Electron Forge receives an archive synthesized from
the nixpkgs Electron package, avoiding its normal binary download.

## Relationship to Upstream

This repository packages the downstream application fork; it is not itself a
fork of `felixrieseberg/clippy`. Clippy's source code remains under its
upstream MIT license, and the Clippy character and imagery retain the notices
in the application's `LICENSE.md`. This repository's Nix packaging code is
MIT-licensed separately.
