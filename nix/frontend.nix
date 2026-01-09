{
  pkgs,
  src,
  apiBase ? "http://127.0.0.1:8001",
  apiBaseExternal ? null,
}:
pkgs.buildNpmPackage {
  pname = "deeptutor-frontend";
  version = "0.1.0";
  inherit src;

  npmDepsHash = "sha256-VhGOG5GlKlx86YRdjWOMNpEmvryj/rfym5ow6d4121c=";

  # Use external URL if provided, otherwise use internal
  env = {
    NEXT_PUBLIC_API_BASE = if apiBaseExternal != null then apiBaseExternal else apiBase;
  };

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r .next $out/
    cp -r public $out/ 2>/dev/null || true
    cp -r node_modules $out/
    cp package.json $out/
    cp next.config.* $out/ 2>/dev/null || true
    runHook postInstall
  '';
}
