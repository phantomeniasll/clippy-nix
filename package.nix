{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libpulseaudio,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxkbcommon,
  libxshmfence,
  nspr,
  nss,
  pango,
  systemdLibs,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "clippy";
  version = "0.4.3";

  src = fetchurl {
    url = "https://github.com/felixrieseberg/clippy/releases/download/v${finalAttrs.version}/clippy_${finalAttrs.version}_amd64.deb";
    hash = "sha256-GBEZETvpmXz7gYjQA53f88lat6G8K6AIm9OFevV0xy8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libpulseaudio
    libxkbcommon
    libxshmfence
    nspr
    nss
    pango
    stdenv.cc.cc
    systemdLibs
    wayland
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
  ];

  # The package includes optional CUDA and Vulkan llama.cpp backends. CUDA
  # driver libraries are supplied by the host at runtime and may be absent.
  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libcudart.so.12"
    "libcublas.so.12"
    "libcublasLt.so.12"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" \
      | tar --extract --no-same-owner --no-same-permissions
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    mv usr/lib usr/share "$out/"
    mkdir -p "$out/bin"
    ln -s "$out/lib/clippy/Clippy" "$out/bin/clippy"

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      # node-llama-cpp detects glibc by searching LD_LIBRARY_PATH. NixOS
      # keeps both glibc and dynamically loaded graphics libraries in the
      # Nix store rather than conventional /lib and /usr/lib directories.
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        stdenv.cc.libc
        libglvnd
      ]}"
      --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
    )
  '';

  # The CPU, Vulkan, and CUDA bundles reuse the same shared-library names.
  # autoPatchelf can otherwise resolve a backend against another backend's
  # directory, so make each bundle prefer its own colocated libraries.
  postFixup = ''
    for backend in "$out"/lib/clippy/resources/app.asar.unpacked/node_modules/@node-llama-cpp/*/bins/*; do
      if [ -d "$backend" ]; then
        for executable in "$backend"/*.node "$backend"/*.so "$backend"/vulkan-shaders-gen; do
          if [ -f "$executable" ]; then
            patchelf --set-rpath "$backend:$(patchelf --print-rpath "$executable")" "$executable"
          fi
        done
      fi
    done
  '';

  meta = {
    description = "Classic Clippy interface for running local LLMs";
    homepage = "https://github.com/felixrieseberg/clippy";
    license = lib.licenses.mit;
    mainProgram = "clippy";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
