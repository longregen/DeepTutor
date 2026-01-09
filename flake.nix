{
  description = "DeepTutor - AI-powered personalized learning assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Overlay to add missing Python packages not in nixpkgs
        pythonOverlay = final: prev: {
          python311 = prev.python311.override {
            packageOverrides = pyFinal: pyPrev: {
              # perplexityai - Perplexity AI official SDK (not in nixpkgs)
              perplexityai = pyFinal.buildPythonPackage rec {
                pname = "perplexityai";
                version = "0.1.0";
                format = "setuptools";

                src = pyFinal.fetchPypi {
                  inherit pname version;
                  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
                };

                propagatedBuildInputs = with pyFinal; [
                  requests
                  openai
                ];

                # Skip tests as they require API keys
                doCheck = false;

                pythonImportsCheck = [ "perplexityai" ];

                meta = with prev.lib; {
                  description = "Perplexity AI Python SDK";
                  homepage = "https://github.com/perplexityai/perplexity-py";
                  license = licenses.mit;
                };
              };

              # lightrag-hku - HKU Data Science Lab's LightRAG (not in nixpkgs)
              lightrag-hku = pyFinal.buildPythonPackage rec {
                pname = "lightrag-hku";
                version = "1.0.0";
                format = "pyproject";

                src = pyFinal.fetchPypi {
                  inherit pname version;
                  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
                };

                build-system = [ pyFinal.setuptools ];

                propagatedBuildInputs = with pyFinal; [
                  numpy
                  networkx
                  tiktoken
                  openai
                  pydantic
                ];

                # Skip tests
                doCheck = false;

                pythonImportsCheck = [ "lightrag" ];

                meta = with prev.lib; {
                  description = "LightRAG - Simple and Fast Retrieval-Augmented Generation";
                  homepage = "https://github.com/HKUDS/LightRAG";
                  license = licenses.mit;
                };
              };

              # raganything - HKU's multimodal RAG system (not in nixpkgs)
              raganything = pyFinal.buildPythonPackage rec {
                pname = "raganything";
                version = "0.1.0";
                format = "pyproject";

                src = pyFinal.fetchPypi {
                  inherit pname version;
                  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
                };

                build-system = [ pyFinal.setuptools ];

                propagatedBuildInputs = with pyFinal; [
                  numpy
                  openai
                  pydantic
                  pillow
                ];

                # Skip tests
                doCheck = false;

                pythonImportsCheck = [ "raganything" ];

                meta = with prev.lib; {
                  description = "RAG-Anything - Multimodal RAG System";
                  homepage = "https://github.com/HKUDS/RAG-Anything";
                  license = licenses.mit;
                };
              };
            };
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ pythonOverlay ];
        };

        # Python with packages from nixpkgs where available
        python = pkgs.python311;
        pythonPackages = pkgs.python311Packages;

        # All Python packages available from nixpkgs for DeepTutor
        # Packages marked with (pip) need to be installed via pip as they are not in nixpkgs
        nixPythonPackages = with pythonPackages; [
          # Core dependencies
          python-dotenv      # >=1.0.0, nixpkgs: 1.2.1
          pyyaml             # >=6.0, nixpkgs: 6.0.3
          tiktoken           # >=0.5.0, nixpkgs: 0.12.0

          # HTTP and API clients
          requests           # >=2.32.2, nixpkgs: 2.32.5
          openai             # >=1.30.0, nixpkgs: 2.11.0
          dashscope          # >=1.14.0, nixpkgs: 1.25.5
          aiohttp            # >=3.9.4, nixpkgs: 3.13.2
          httpx              # >=0.27.0, nixpkgs: 0.28.1
          urllib3            # >=2.2.1, nixpkgs: 2.6.0
          # perplexityai     # (pip) not in nixpkgs

          # Async support
          nest-asyncio       # >=1.5.8, nixpkgs: 1.6.0

          # Web framework and server
          fastapi            # >=0.100.0, nixpkgs: 0.121.1
          uvicorn            # >=0.24.0, nixpkgs: 0.38.0
          websockets         # >=12.0, nixpkgs: 15.0.1
          python-multipart   # >=0.0.6, nixpkgs: 0.0.20
          pydantic           # >=2.0.0, nixpkgs: 2.12.4

          # RAG and knowledge base
          # lightrag-hku     # (pip) not in nixpkgs
          # raganything      # (pip) not in nixpkgs

          # Academic and research tools
          arxiv              # >=2.0.0, nixpkgs: 2.3.1

          # Development tools
          pre-commit         # >=3.0.0, nixpkgs: 4.5.1

          # LlamaIndex ecosystem (all available in nixpkgs)
          llama-cloud                           # ==0.1.45 (nixpkgs newer than required 0.1.35)
          llama-cloud-services                  # ==0.6.79 (nixpkgs newer than required 0.6.54)
          llama-index                           # ==0.14.12
          llama-index-cli                       # ==0.5.3
          llama-index-core                      # ==0.14.12
          llama-index-embeddings-openai         # ==0.5.1
          llama-index-indices-managed-llama-cloud # ==0.9.4
          llama-index-instrumentation           # ==0.4.2
          llama-index-llms-openai               # ==0.6.12
          llama-index-readers-file              # ==0.5.6
          llama-index-readers-llama-parse       # ==0.5.1
          llama-index-workflows                 # ==2.11.6
          llama-parse                           # ==0.6.79 (nixpkgs newer than required 0.6.54)

          # Build/dev tools
          pip
          setuptools
          wheel
          virtualenv
        ];

        # Python with all nixpkgs packages
        pythonWithPackages = python.withPackages (ps: nixPythonPackages);

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

        # Create a shell script to install pip-only dependencies
        installPipDeps = pkgs.writeShellScriptBin "install-pip-deps" ''
          echo "Installing packages not available in nixpkgs..."
          pip install --user perplexityai>=0.1.0 lightrag-hku>=1.0.0 raganything>=0.1.0
          echo "Done! Pip-only dependencies installed."
        '';

        # Script to run tests
        testScript = pkgs.writeShellScriptBin "run-tests" ''
          PYTHONPATH="$PWD:$PYTHONPATH" pytest tests/ -v --tb=short "$@"
        '';

        # Script to run the Groq integration test
        groqTestScript = pkgs.writeShellScriptBin "test-groq" ''
          PYTHONPATH="$PWD:$PYTHONPATH" pytest tests/integration/test_groq_llm.py -v --tb=short "$@"
        '';

      in
      {
        # Development shell with all Python packages from nixpkgs
        devShells.default = pkgs.mkShell {
          name = "deeptutor-dev";

          buildInputs = systemDeps ++ [
            pythonWithPackages
            pkgs.nodejs_20
            pkgs.nodePackages.npm
            installPipDeps
            testScript
            groqTestScript
          ];

          shellHook = ''
            echo "DeepTutor Development Environment"
            echo "=================================="
            echo ""
            echo "Python packages from nixpkgs are pre-installed."
            echo ""
            echo "Available commands:"
            echo "  install-pip-deps - Install packages not in nixpkgs (perplexityai, lightrag-hku, raganything)"
            echo "  run-tests        - Run all tests"
            echo "  test-groq        - Run Groq integration test"
            echo ""
            echo "Python version: $(python --version)"
            echo "Node version: $(node --version)"
            echo ""

            # Set PYTHONPATH
            export PYTHONPATH="$PWD:$PYTHONPATH"

            # Add user pip packages to path
            export PATH="$HOME/.local/bin:$PATH"
            export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"
          '';

          # Environment variables
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;
        };

        # Package for running tests in CI
        packages.default = pkgs.writeShellScriptBin "deeptutor-test" ''
          cd ${self}
          ${pythonWithPackages}/bin/python -m pytest tests/ -v --tb=short
        '';

        # CI-specific shell with minimal dependencies for testing
        devShells.ci = pkgs.mkShell {
          name = "deeptutor-ci";

          buildInputs = systemDeps ++ [
            pythonWithPackages
          ];

          shellHook = ''
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;
        };
      }
    );
}
