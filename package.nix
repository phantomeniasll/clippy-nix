{
  lib,
  stdenv,
  buildNpmPackage,
  runCommand,
  electron,
  llama-cpp,
  makeWrapper,
  wrapGAppsHook3,
  autoPatchelfHook,
  zip,
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
  libxslt,
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

let
  llamaCppVulkan = llama-cpp.override {
    vulkanSupport = true;
  };
  electronDist = runCommand "electron-${electron.version}-linux-x64-archive" {
    nativeBuildInputs = [ zip ];
  } ''
    mkdir -p "$out" "$TMPDIR/electron-template"
    cp -r ${electron.unwrapped}/libexec/electron/. "$TMPDIR/electron-template/"
    chmod -R u+w "$TMPDIR/electron-template"
    (cd "$TMPDIR/electron-template" && \
      zip -0qr "$out/electron-v${electron.version}-linux-x64.zip" .)
  '';
in
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
    libdrm libgbm libglvnd libpulseaudio libxslt libxkbcommon libxshmfence nspr nss
    pango stdenv.cc.cc systemdLibs wayland libx11 libxcb libxcomposite
    libxcursor libxdamage libxext libxfixes libxi libxrandr libxrender libxtst
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    ELECTRON_ZIP_DIR = electronDist;
  };

  preBuild = ''
    substituteInPlace package.json \
      --replace-fail '"electron": "41.10.3"' '"electron": "${electron.version}"'
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
    "libcudart.so.13"
    "libcublas.so.13"
    "libcublasLt.so.13"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ stdenv.cc.libc libglvnd ]}"
      --set CHROME_DEVEL_SANDBOX "${electron}/libexec/electron/chrome-sandbox"
      --set CLIPPY_LLAMA_SERVER "${llamaCppVulkan}/bin/llama-server"
      # KWin can enforce Electron's always-on-top hint through XWayland. The
      # native Wayland protocol intentionally gives clients no keep-above API.
      --add-flags "--ozone-platform=x11"
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
    homepage = "https://github.com/phantomeniasll/clippy";
    license = lib.licenses.mit;
    mainProgram = "clippy";
    platforms = [ "x86_64-linux" ];
  };
}
