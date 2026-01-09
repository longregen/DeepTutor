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

        # Python with all packages (nixpkgs + overlay)
        pythonWithPackages = pkgs.python311.withPackages (ps: [
          # Core dependencies
          ps.python-dotenv      # >=1.0.0, nixpkgs: 1.2.1
          ps.pyyaml             # >=6.0, nixpkgs: 6.0.3
          ps.tiktoken           # >=0.5.0, nixpkgs: 0.12.0

          # HTTP and API clients
          ps.requests           # >=2.32.2, nixpkgs: 2.32.5
          ps.openai             # >=1.30.0, nixpkgs: 2.11.0
          ps.dashscope          # >=1.14.0, nixpkgs: 1.25.5
          ps.aiohttp            # >=3.9.4, nixpkgs: 3.13.2
          ps.httpx              # >=0.27.0, nixpkgs: 0.28.1
          ps.urllib3            # >=2.2.1, nixpkgs: 2.6.0
          ps.perplexityai       # >=0.1.0 (from overlay)

          # Async support
          ps.nest-asyncio       # >=1.5.8, nixpkgs: 1.6.0

          # Web framework and server
          ps.fastapi            # >=0.100.0, nixpkgs: 0.121.1
          ps.uvicorn            # >=0.24.0, nixpkgs: 0.38.0
          ps.websockets         # >=12.0, nixpkgs: 15.0.1
          ps.python-multipart   # >=0.0.6, nixpkgs: 0.0.20
          ps.pydantic           # >=2.0.0, nixpkgs: 2.12.4

          # RAG and knowledge base (from overlay)
          ps.lightrag-hku       # >=1.0.0 (from overlay)
          ps.raganything        # >=0.1.0 (from overlay)

          # Academic and research tools
          ps.arxiv              # >=2.0.0, nixpkgs: 2.3.1

          # LlamaIndex ecosystem (all available in nixpkgs)
          ps.llama-cloud                             # >=0.1.35, nixpkgs: 0.1.45
          ps.llama-cloud-services                    # >=0.6.54, nixpkgs: 0.6.79
          ps.llama-index                             # ==0.14.12
          ps.llama-index-cli                         # ==0.5.3
          ps.llama-index-core                        # ==0.14.12
          ps.llama-index-embeddings-openai           # ==0.5.1
          ps.llama-index-indices-managed-llama-cloud # ==0.9.4
          ps.llama-index-instrumentation             # ==0.4.2
          ps.llama-index-llms-openai                 # ==0.6.12
          ps.llama-index-readers-file                # ==0.5.6
          ps.llama-index-readers-llama-parse         # ==0.5.1
          ps.llama-index-workflows                   # ==2.11.6
          ps.llama-parse                             # >=0.6.54, nixpkgs: 0.6.79

          # Testing
          ps.pytest
          ps.pytest-asyncio
        ]);

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
            pkgs.pre-commit  # Development tool (standalone, not Python package)
            testScript
            groqTestScript
          ];

          shellHook = ''
            echo "DeepTutor Development Environment"
            echo "=================================="
            echo ""
            echo "All Python packages are pre-installed from nixpkgs."
            echo ""
            echo "Available commands:"
            echo "  run-tests        - Run all tests"
            echo "  test-groq        - Run Groq integration test"
            echo ""
            echo "Python version: $(python --version)"
            echo "Node version: $(node --version)"
            echo ""

            # Set PYTHONPATH
            export PYTHONPATH="$PWD:$PYTHONPATH"
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
