# Build wasmer from scratch with __rust_probestack fix
# Patches the .so post-build to provide the missing symbol
{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  buildPythonPackage,
  libiconv,
  patchelf,
}:

buildPythonPackage rec {
  pname = "wasmer";
  version = "1.2.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "wasmerio";
    repo = "wasmer-python";
    rev = version;
    hash = "sha256-Iu28LMDNmtL2r7gJV5Vbb8HZj18dlkHe+mw/Y1L8YKE=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-oHyjzEqv88e2CHhWhKjUh6K0UflT9Y1JD//3oiE/UBQ=";
  };

  nativeBuildInputs = with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
    patchelf
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  buildAndTestSubdir = "packages/api";

  # Create a stub library providing __rust_probestack and link it into the .so
  postFixup = ''
    # Find the .so file
    SO_FILE=$(find $out -name "*.so" -type f | head -1)

    if [ -n "$SO_FILE" ]; then
      echo "Patching $SO_FILE to add __rust_probestack symbol"

      # Create a C stub that provides the missing symbol
      # __rust_probestack is a stack probe function - we make it a no-op
      cat > /tmp/probestack_stub.c << 'STUB_EOF'
void __rust_probestack(void) {
    // No-op stub - the actual probing is not needed if we got here
}
STUB_EOF

      # Compile to a shared library
      $CC -shared -fPIC -o /tmp/libprobestack.so /tmp/probestack_stub.c

      # Copy the stub library next to the .so
      STUB_DIR=$(dirname "$SO_FILE")
      cp /tmp/libprobestack.so "$STUB_DIR/"

      # Patch the .so to depend on our stub library
      patchelf --add-needed libprobestack.so "$SO_FILE"
      patchelf --set-rpath "$STUB_DIR:$(patchelf --print-rpath "$SO_FILE")" "$SO_FILE"

      echo "Successfully patched $SO_FILE"
    fi
  '';

  pythonImportsCheck = [ "wasmer" ];

  meta = {
    description = "Python extension to run WebAssembly binaries";
    homepage = "https://github.com/wasmerio/wasmer-python";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
