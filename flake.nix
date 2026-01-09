{
  description = "DeepTutor - AI-powered personalized learning assistant";

  inputs = {
    nixpkgs.url = "git+ssh://gitea/mirrors/nixpkgs?shallow=1&ref=nixos-unstable";
    flake-utils.url = "git+ssh://gitea/mirrors/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    {
      # System-independent outputs

      nixosModules.default = import ./nix/nixos;
      nixosModules.deeptutor = import ./nix/nixos;

      # Overlays
      overlays.default = final: prev: let
        pythonPackagesOverlay = import ./nix/python-packages/overlay.nix {inherit prev;};
      in {
        python311 = prev.python311.override {
          packageOverrides = pythonPackagesOverlay;
        };
        python311Packages = final.python311.pkgs;
        loguru-cpp = prev.callPackage ./nix/cxx-packages/loguru-cpp {};
      };

      overlays.pythonPackages = final: prev:
        import ./nix/python-packages/overlay.nix {inherit prev;};
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            nvidia.acceptLicense = true;
            cudaSupport = true;
            cudaEnableForwardCompat = true;
          };
          overlays = [
            (final: prev: let
              pythonPackagesOverlay = import ./nix/python-packages/overlay.nix {inherit prev;};
            in {
              python311 = prev.python311.override {
                packageOverrides = pythonPackagesOverlay;
              };
              python311Packages = final.python311.pkgs;
              loguru-cpp = prev.callPackage ./nix/cxx-packages/loguru-cpp {};
            })
          ];
        };

        py = pkgs.python311Packages;

        pythonPackagesList = import ./nix/python-packages/packages.nix;
        pythonWithPackages = pkgs.python311.withPackages pythonPackagesList;

        systemDeps = with pkgs; [
          gcc
          gnumake
          cmake
          pkg-config

          # SSL/TLS
          openssl

          # For numpy/scipy
          blas
          lapack

          # For pillow/image processing
          zlib
          libjpeg
          libpng

          # For PDF processing
          poppler-utils

          # For imgui-bundle
          glfw
          libGL
          libGLU

          # Git for development
          git
        ];

        testScript = pkgs.writeShellScriptBin "run-tests" ''
          PYTHONPATH="$PWD:$PYTHONPATH" pytest tests/ -v --tb=short "$@"
        '';

        groqTestScript = pkgs.writeShellScriptBin "test-groq" ''
          PYTHONPATH="$PWD:$PYTHONPATH" pytest tests/integration/test_groq_llm.py -v --tb=short "$@"
        '';

        # Application wrappers
        deeptutor-app = pkgs.writeShellScriptBin "deeptutor" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-$HOME/.local/share/deeptutor}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          # Ensure data directory exists
          mkdir -p "$DEEPTUTOR_DATA_DIR/user"

          echo "DeepTutor - AI-powered personalized learning assistant"
          echo "======================================================="
          echo "Data directory: $DEEPTUTOR_DATA_DIR"
          echo ""

          cd "$SOURCE_DIR"
          exec ${pythonWithPackages}/bin/python scripts/start_web.py "$@"
        '';

        deeptutor-backend = pkgs.writeShellScriptBin "deeptutor-backend" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-$HOME/.local/share/deeptutor}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          mkdir -p "$DEEPTUTOR_DATA_DIR/user"

          cd "$SOURCE_DIR"
          exec ${pythonWithPackages}/bin/uvicorn src.api.main:app \
            --host "''${BACKEND_HOST:-127.0.0.1}" \
            --port "''${BACKEND_PORT:-8001}" \
            "$@"
        '';

        deeptutor-cli = pkgs.writeShellScriptBin "deeptutor-cli" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-$HOME/.local/share/deeptutor}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          mkdir -p "$DEEPTUTOR_DATA_DIR/user"

          cd "$SOURCE_DIR"
          exec ${pythonWithPackages}/bin/python scripts/start.py "$@"
        '';
      in {
        devShells.default = pkgs.mkShell {
          name = "deeptutor-dev";

          buildInputs =
            systemDeps
            ++ [
              pythonWithPackages
              pkgs.nodejs_20
              pkgs.nodePackages.npm
              pkgs.pre-commit
              testScript
              groqTestScript
            ];

          shellHook = ''
            echo "DeepTutor Development Environment"
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;
        };

        packages = {
          # Main application
          default = deeptutor-app;
          deeptutor = deeptutor-app;
          backend = deeptutor-backend;
          cli = deeptutor-cli;

          # Test runner
          test = pkgs.writeShellScriptBin "deeptutor-test" ''
            cd ${self}
            export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/tmp/deeptutor-test}"
            mkdir -p "$DEEPTUTOR_DATA_DIR/user"
            ${pythonWithPackages}/bin/python -m pytest tests/ -v --tb=short "$@"
          '';

          # Frontend (Next.js)
          frontend = import ./nix/frontend.nix {
            inherit pkgs;
            src = ./web;
          };

          # Python packages (all from overlay)
          inherit
            (py)
            wasmer
            ascii-colors
            nano-vectordb
            pipmaster
            pymilvus
            pgvector
            voyageai
            zhipuai
            perplexityai
            scikit-network
            ragas
            docling-parse
            docling
            mineru
            imgui-bundle
            lightrag-hku
            raganything
            pytest-doctestplus
            duckdb-engine
            pydevd
            ;

          # C++ packages
          loguru-cpp = pkgs.loguru-cpp;

          # Full Python environment
          python = pythonWithPackages;
        };

        # Apps for `nix run`
        apps = {
          default = {
            type = "app";
            program = "${deeptutor-app}/bin/deeptutor";
          };
          deeptutor = {
            type = "app";
            program = "${deeptutor-app}/bin/deeptutor";
          };
          backend = {
            type = "app";
            program = "${deeptutor-backend}/bin/deeptutor-backend";
          };
          cli = {
            type = "app";
            program = "${deeptutor-cli}/bin/deeptutor-cli";
          };
          test = {
            type = "app";
            program = "${testScript}/bin/run-tests";
          };
        };
      }
    );
}
