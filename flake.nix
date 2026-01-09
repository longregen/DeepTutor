{
  description = "DeepTutor - AI-powered personalized learning assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Import the Python packages overlay
        pythonOverlay = import ./nix/overlay.nix;

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ pythonOverlay ];
        };

        # Python with all packages (nixpkgs + overlay)
        pythonWithPackages = pkgs.python311.withPackages (ps: [
          # ============================================
          # Core dependencies
          # ============================================
          ps.python-dotenv      # >=1.0.0, nixpkgs: 1.2.1
          ps.pyyaml             # >=6.0, nixpkgs: 6.0.3
          ps.tiktoken           # >=0.5.0, nixpkgs: 0.12.0

          # ============================================
          # HTTP and API clients
          # ============================================
          ps.requests           # >=2.32.2, nixpkgs: 2.32.5
          ps.openai             # >=1.30.0, nixpkgs: 2.11.0
          ps.dashscope          # >=1.14.0, nixpkgs: 1.25.5
          ps.aiohttp            # >=3.9.4, nixpkgs: 3.13.2
          ps.httpx              # >=0.27.0, nixpkgs: 0.28.1
          ps.urllib3            # >=2.2.1, nixpkgs: 2.6.0
          ps.perplexityai       # >=0.1.0 (from overlay)

          # ============================================
          # Async support
          # ============================================
          ps.nest-asyncio       # >=1.5.8, nixpkgs: 1.6.0

          # ============================================
          # Web framework and server
          # ============================================
          ps.fastapi            # >=0.100.0, nixpkgs: 0.121.1
          ps.uvicorn            # >=0.24.0, nixpkgs: 0.38.0
          ps.websockets         # >=12.0, nixpkgs: 15.0.1
          ps.python-multipart   # >=0.0.6, nixpkgs: 0.0.20
          ps.pydantic           # >=2.0.0, nixpkgs: 2.12.4
          ps.gunicorn           # for production

          # ============================================
          # RAG and knowledge base (from overlay)
          # ============================================
          ps.lightrag-hku       # >=1.0.0 (from overlay)
          ps.raganything        # >=0.1.0 (from overlay)

          # ============================================
          # LightRAG dependencies (from overlay)
          # ============================================
          ps.nano-vectordb      # (from overlay)
          ps.pipmaster          # (from overlay)
          ps.json-repair        # (from overlay)
          ps.pypinyin           # (from overlay)

          # ============================================
          # Vector database clients (from overlay)
          # ============================================
          ps.pymilvus           # (from overlay)
          ps.qdrant-client      # (from overlay)
          ps.pgvector           # (from overlay)

          # ============================================
          # LLM providers
          # ============================================
          ps.anthropic          # nixpkgs
          ps.ollama             # nixpkgs
          ps.voyageai           # (from overlay)
          ps.zhipuai            # (from overlay)
          ps.google-genai       # (from overlay)

          # ============================================
          # Storage backends (nixpkgs)
          # ============================================
          ps.asyncpg            # PostgreSQL async
          ps.neo4j              # Graph database
          ps.pymongo            # MongoDB
          ps.redis              # Redis

          # ============================================
          # Document processing (from overlay)
          # ============================================
          ps.docling            # (from overlay)
          ps.mineru             # (from overlay)

          # ============================================
          # Evaluation & Observability (from overlay)
          # ============================================
          ps.ragas              # (from overlay)
          ps.langfuse           # (from overlay)

          # ============================================
          # Visualization (from overlay)
          # ============================================
          ps.imgui-bundle       # (from overlay)
          ps.pyglm              # (from overlay)
          ps.python-louvain     # (from overlay)

          # ============================================
          # Scientific computing (nixpkgs)
          # ============================================
          ps.numpy
          ps.pandas
          ps.scipy
          ps.networkx
          ps.pillow
          ps.moderngl

          # ============================================
          # Academic and research tools (nixpkgs)
          # ============================================
          ps.arxiv              # >=2.0.0, nixpkgs: 2.3.1

          # ============================================
          # LlamaIndex ecosystem (nixpkgs)
          # ============================================
          ps.llama-cloud
          ps.llama-cloud-services
          ps.llama-index
          ps.llama-index-cli
          ps.llama-index-core
          ps.llama-index-embeddings-openai
          ps.llama-index-indices-managed-llama-cloud
          ps.llama-index-instrumentation
          ps.llama-index-llms-openai
          ps.llama-index-readers-file
          ps.llama-index-readers-llama-parse
          ps.llama-index-workflows
          ps.llama-parse

          # ============================================
          # ML/AI (nixpkgs)
          # ============================================
          ps.datasets
          ps.huggingface-hub
          ps.transformers
          ps.torch
          ps.torchvision
          ps.tokenizers

          # ============================================
          # LangChain (nixpkgs)
          # ============================================
          ps.langchain
          ps.langchain-core
          ps.langchain-community
          ps.langchain-openai

          # ============================================
          # Testing (nixpkgs)
          # ============================================
          ps.pytest
          ps.pytest-asyncio
        ]);

        # System dependencies needed for Python packages
        systemDeps = with pkgs; [
          # Build tools
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
        # Development shell with all Python packages from nixpkgs + overlay
        devShells.default = pkgs.mkShell {
          name = "deeptutor-dev";

          buildInputs = systemDeps ++ [
            pythonWithPackages
            pkgs.nodejs_20
            pkgs.nodePackages.npm
            pkgs.pre-commit
            testScript
            groqTestScript
          ];

          shellHook = ''
            echo "DeepTutor Development Environment"
            echo "=================================="
            echo ""
            echo "All Python packages are pre-installed from nixpkgs + overlay."
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
