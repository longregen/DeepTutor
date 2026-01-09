{
  description = "DeepTutor - AI-powered personalized learning assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Python with packages from nixpkgs where available
        pythonPackages = pkgs.python311Packages;
        python = pkgs.python311;

        # System dependencies needed for Python packages
        systemDeps = with pkgs; [
          # Build tools
          gcc
          gnumake
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

          # Git for development
          git
        ];

        # Python development dependencies
        pythonDevDeps = with pythonPackages; [
          pip
          setuptools
          wheel
          virtualenv
        ];

        # Create a shell script to set up the Python environment
        setupScript = pkgs.writeShellScriptBin "setup-deeptutor" ''
          echo "Setting up DeepTutor development environment..."

          # Create virtual environment if it doesn't exist
          if [ ! -d ".venv" ]; then
            echo "Creating virtual environment..."
            python -m venv .venv
          fi

          # Activate and install dependencies
          source .venv/bin/activate
          echo "Installing Python dependencies..."
          pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-asyncio pytest-cov

          echo "Setup complete! Activate with: source .venv/bin/activate"
        '';

        # Script to run tests
        testScript = pkgs.writeShellScriptBin "run-tests" ''
          if [ -d ".venv" ]; then
            source .venv/bin/activate
          fi
          PYTHONPATH="$PWD" pytest tests/ -v --tb=short "$@"
        '';

        # Script to run the Groq integration test
        groqTestScript = pkgs.writeShellScriptBin "test-groq" ''
          if [ -d ".venv" ]; then
            source .venv/bin/activate
          fi
          PYTHONPATH="$PWD" pytest tests/integration/test_groq_llm.py -v --tb=short "$@"
        '';

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "deeptutor-dev";

          buildInputs = systemDeps ++ pythonDevDeps ++ [
            python
            pkgs.nodejs_20
            pkgs.nodePackages.npm
            setupScript
            testScript
            groqTestScript
          ];

          shellHook = ''
            echo "DeepTutor Development Environment"
            echo "=================================="
            echo ""
            echo "Available commands:"
            echo "  setup-deeptutor  - Set up Python virtual environment and install dependencies"
            echo "  run-tests        - Run all tests"
            echo "  test-groq        - Run Groq integration test"
            echo ""
            echo "Python version: $(python --version)"
            echo "Node version: $(node --version)"
            echo ""

            # Activate venv if it exists
            if [ -d ".venv" ]; then
              source .venv/bin/activate
              echo "Virtual environment activated."
            else
              echo "Run 'setup-deeptutor' to create the virtual environment."
            fi

            # Set PYTHONPATH
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';

          # Environment variables
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;
        };

        # Package for running tests in CI
        packages.default = pkgs.writeShellScriptBin "deeptutor-test" ''
          cd ${self}
          ${python}/bin/python -m pytest tests/ -v --tb=short
        '';

        # CI-specific shell with minimal dependencies for testing
        devShells.ci = pkgs.mkShell {
          name = "deeptutor-ci";

          buildInputs = systemDeps ++ [
            python
            pythonPackages.pip
            pythonPackages.setuptools
            pythonPackages.wheel
          ];

          shellHook = ''
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;
        };
      }
    );
}
