{
  lib,
  stdenv,
  buildNpmPackage,
  electron-unwrapped,
  makeWrapper,
  wrapGAppsHook3,
  autoPatchelfHook,
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
  clippySrc,
}:

buildNpmPackage {
  pname = "clippy";
  version = "0.4.3-modern-llama";

  src = clippySrc;
  npmDepsHash = "sha256-gTnr2dSohMrOegb5QloOaESul2A2DcwNQwADkGnJxpo=";
  makeCacheWritable = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib at-spi2-atk at-spi2-core cairo cups dbus expat glib gtk3
    libdrm libgbm libglvnd libpulseaudio libxkbcommon libxshmfence nspr nss
    pango stdenv.cc.cc systemdLibs wayland libx11 libxcb libxcomposite
    libxcursor libxdamage libxext libxfixes libxi libxrandr libxrender libxtst
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  preBuild = ''
    rm -rf node_modules/electron/dist
    ln -s ${electron-unwrapped}/libexec/electron node_modules/electron/dist
  '';

  npmBuildScript = "package";

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/clippy" "$out/bin"
    cp -r out/Clippy-linux-x64/. "$out/lib/clippy/"
    ln -s "$out/lib/clippy/Clippy" "$out/bin/clippy"
    runHook postInstall
  '';

  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libcudart.so.12"
    "libcublas.so.12"
    "libcublasLt.so.12"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ stdenv.cc.libc libglvnd ]}"
      --add-flags "''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
    )
  '';

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
  };
}
