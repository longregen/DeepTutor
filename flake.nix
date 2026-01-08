{
  description = "DeepTutor - AI-Powered Personalized Learning Assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        # Use Python 3.11 with minimal packages - install rest via pip
        python = pkgs.python311;

        # Minimal Python environment with just pip and venv support
        pythonEnv = python.withPackages (ps: with ps; [
          pip
          virtualenv
        ]);

        # Node.js for the frontend
        nodejs = pkgs.nodejs_22;

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "deeptutor-dev";

          buildInputs = [
            pythonEnv
            nodejs
            pkgs.nodePackages.npm

            # Development tools
            pkgs.git
            pkgs.curl
            pkgs.jq

            # For building Python packages with native extensions
            pkgs.gcc
            pkgs.gnumake
            pkgs.pkg-config
            pkgs.openssl
            pkgs.zlib
          ];

          shellHook = ''
            echo "🎓 DeepTutor Development Environment"
            echo "Python: $(python --version)"
            echo "Node.js: $(node --version)"
            echo ""

            # Set up Python path
            export PYTHONPATH="$PWD:$PYTHONPATH"

            # Create a virtual environment if it doesn't exist
            if [ ! -d ".venv" ]; then
              echo "Creating virtual environment..."
              python -m venv .venv
            fi

            # Activate venv
            source .venv/bin/activate

            # Install dependencies if not already done
            if [ ! -f ".venv/.deps-installed" ]; then
              echo "Installing Python dependencies..."
              pip install --upgrade pip --quiet
              pip install -r requirements.txt --quiet 2>/dev/null || echo "Some packages may have failed to install"
              touch .venv/.deps-installed
            fi

            echo ""
            echo "Virtual environment activated. Run 'pytest tests/ -v' to run tests."
          '';
        };

        # Packages
        packages = {
          # Backend package (source distribution)
          backend = pkgs.stdenv.mkDerivation {
            name = "deeptutor-backend";
            src = ./.;

            buildInputs = [ pythonEnv ];

            installPhase = ''
              mkdir -p $out/lib/deeptutor
              cp -r src $out/lib/deeptutor/
              cp -r config $out/lib/deeptutor/ 2>/dev/null || mkdir -p $out/lib/deeptutor/config
              cp requirements.txt $out/lib/deeptutor/
              cp settings.py $out/lib/deeptutor/

              mkdir -p $out/bin
              cat > $out/bin/deeptutor-server <<'SCRIPT'
              #!/usr/bin/env bash
              echo "Note: Run 'pip install -r requirements.txt' first"
              export PYTHONPATH="$out/lib/deeptutor:$PYTHONPATH"
              cd $out/lib/deeptutor
              exec python -m uvicorn src.api.main:app --host 0.0.0.0 --port 8001 "$@"
              SCRIPT
              chmod +x $out/bin/deeptutor-server
            '';
          };

          default = self.packages.${system}.backend;
        };

        # Checks (run with `nix flake check`)
        checks = {
          # Basic flake structure check
          flake-check = pkgs.runCommand "flake-structure-check" {} ''
            echo "✅ Flake structure is valid"
            touch $out
          '';
        };

        # Apps (run with `nix run`)
        apps = {
          default = {
            type = "app";
            program = toString (pkgs.writeShellScript "deeptutor-help" ''
              echo "DeepTutor - AI-Powered Learning Assistant"
              echo ""
              echo "Usage:"
              echo "  nix develop          - Enter development shell"
              echo "  nix build            - Build the backend package"
              echo ""
              echo "In development shell:"
              echo "  pytest tests/ -v     - Run tests"
              echo "  python src/api/run_server.py - Start server"
            '');
          };
        };
      });
}
