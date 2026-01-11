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

        # Pre-built frontend
        frontendPackage = import ./nix/frontend.nix {
          inherit pkgs;
          src = ./web;
          apiBase = "";  # Same-origin: API at /api
        };

        # Application wrappers
        deeptutor-app = pkgs.writeShellScriptBin "deeptutor" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/var/lib/deeptutor}"
          export DEEPTUTOR_CONFIG_DIR="''${DEEPTUTOR_CONFIG_DIR:-$DEEPTUTOR_DATA_DIR/config}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          BACKEND_HOST="''${BACKEND_HOST:-127.0.0.1}"
          BACKEND_PORT="''${BACKEND_PORT:-8001}"
          FRONTEND_HOST="''${FRONTEND_HOST:-127.0.0.1}"
          FRONTEND_PORT="''${FRONTEND_PORT:-3782}"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          # Ensure data directories exist
          mkdir -p "$DEEPTUTOR_DATA_DIR/user/logs"
          mkdir -p "$DEEPTUTOR_DATA_DIR/knowledge_bases"
          mkdir -p "$DEEPTUTOR_CONFIG_DIR"

          # Copy config files if they don't exist
          if [ ! -f "$DEEPTUTOR_CONFIG_DIR/main.yaml" ]; then
            echo "Initializing config files..."
            cp "$SOURCE_DIR/config/"*.yaml "$DEEPTUTOR_CONFIG_DIR/" 2>/dev/null || true
          fi

          echo "DeepTutor - AI-powered personalized learning assistant"
          echo "======================================================="
          echo "Data directory: $DEEPTUTOR_DATA_DIR"
          echo "Config directory: $DEEPTUTOR_CONFIG_DIR"
          echo ""

          cleanup() {
            echo "Shutting down..."
            kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
            wait
          }
          trap cleanup EXIT INT TERM

          # Start backend
          echo "Starting backend on $BACKEND_HOST:$BACKEND_PORT..."
          cd "$SOURCE_DIR"
          ${pythonWithPackages}/bin/uvicorn src.api.main:app \
            --host "$BACKEND_HOST" \
            --port "$BACKEND_PORT" &
          BACKEND_PID=$!

          # Start frontend using pre-built package
          echo "Starting frontend on $FRONTEND_HOST:$FRONTEND_PORT..."
          cd ${frontendPackage}
          PORT=$FRONTEND_PORT HOST=$FRONTEND_HOST \
            ${pkgs.nodejs_20}/bin/node node_modules/next/dist/bin/next start \
            -p $FRONTEND_PORT -H $FRONTEND_HOST &
          FRONTEND_PID=$!

          echo ""
          echo "DeepTutor is running!"
          echo "  Frontend: http://$FRONTEND_HOST:$FRONTEND_PORT"
          echo "  Backend:  http://$BACKEND_HOST:$BACKEND_PORT"
          echo ""
          echo "Press Ctrl+C to stop."

          wait
        '';

        deeptutor-backend = pkgs.writeShellScriptBin "deeptutor-backend" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/var/lib/deeptutor}"
          export DEEPTUTOR_CONFIG_DIR="''${DEEPTUTOR_CONFIG_DIR:-$DEEPTUTOR_DATA_DIR/config}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          mkdir -p "$DEEPTUTOR_DATA_DIR/user/logs"
          mkdir -p "$DEEPTUTOR_DATA_DIR/knowledge_bases"
          mkdir -p "$DEEPTUTOR_CONFIG_DIR"

          # Copy config files if they don't exist
          if [ ! -f "$DEEPTUTOR_CONFIG_DIR/main.yaml" ]; then
            cp "$SOURCE_DIR/config/"*.yaml "$DEEPTUTOR_CONFIG_DIR/" 2>/dev/null || true
          fi

          cd "$SOURCE_DIR"
          exec ${pythonWithPackages}/bin/uvicorn src.api.main:app \
            --host "''${BACKEND_HOST:-127.0.0.1}" \
            --port "''${BACKEND_PORT:-8001}" \
            "$@"
        '';

        deeptutor-frontend = pkgs.writeShellScriptBin "deeptutor-frontend" ''
          set -e
          FRONTEND_HOST="''${FRONTEND_HOST:-127.0.0.1}"
          FRONTEND_PORT="''${FRONTEND_PORT:-3782}"

          echo "Starting DeepTutor frontend on $FRONTEND_HOST:$FRONTEND_PORT..."
          cd ${frontendPackage}
          exec ${pkgs.nodejs_20}/bin/node node_modules/next/dist/bin/next start \
            -p $FRONTEND_PORT -H $FRONTEND_HOST
        '';

        deeptutor-cli = pkgs.writeShellScriptBin "deeptutor-cli" ''
          set -e
          SOURCE_DIR="''${DEEPTUTOR_SOURCE_DIR:-${self}}"
          export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/var/lib/deeptutor}"
          export DEEPTUTOR_CONFIG_DIR="''${DEEPTUTOR_CONFIG_DIR:-$DEEPTUTOR_DATA_DIR/config}"
          export PYTHONPATH="$SOURCE_DIR:$PYTHONPATH"

          # Load .env if present
          if [ -f "$SOURCE_DIR/.env" ]; then
            set -a
            source "$SOURCE_DIR/.env"
            set +a
          fi

          mkdir -p "$DEEPTUTOR_DATA_DIR/user/logs"
          mkdir -p "$DEEPTUTOR_CONFIG_DIR"

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
          frontend = deeptutor-frontend;
          cli = deeptutor-cli;

          # Test runner
          test = pkgs.writeShellScriptBin "deeptutor-test" ''
            cd ${self}
            export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/tmp/deeptutor-test}"
            mkdir -p "$DEEPTUTOR_DATA_DIR/user"
            ${pythonWithPackages}/bin/python -m pytest tests/ -v --tb=short "$@"
          '';

          # Pre-built frontend package (for use by other derivations)
          frontend-dist = frontendPackage;

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
          frontend = {
            type = "app";
            program = "${deeptutor-frontend}/bin/deeptutor-frontend";
          };
          cli = {
            type = "app";
            program = "${deeptutor-cli}/bin/deeptutor-cli";
          };
          test = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "deeptutor-test" ''
              cd ${self}
              export DEEPTUTOR_DATA_DIR="''${DEEPTUTOR_DATA_DIR:-/tmp/deeptutor-test}"
              export DEEPTUTOR_CONFIG_DIR="$DEEPTUTOR_DATA_DIR/config"
              mkdir -p "$DEEPTUTOR_DATA_DIR/user/logs"
              mkdir -p "$DEEPTUTOR_CONFIG_DIR"
              cp ${self}/config/*.yaml "$DEEPTUTOR_CONFIG_DIR/" 2>/dev/null || true
              ${pythonWithPackages}/bin/python -m pytest tests/ -v --tb=short "$@"
            ''}/bin/deeptutor-test";
          };
        };
      }
    );
}
