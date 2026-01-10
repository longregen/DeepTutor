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
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            nvidia.acceptLicense = true;
            sdImage.compressImage = false;
            cudaSupport = true;
            cudaCapabilities = ["8.9"];
            cudaEnableForwardCompat = true;

            permittedInsecurePackages = [
              "jitsi-meet-1.0.8792"
              #   "olm-3.2.16"
            ];
          };
          overlays = [
            (final: prev: {
              python311Packages = prev.python311Packages.override {
                overrides = pyFinal: pyPrev: {
                  pytest-doctestplus = import ./nix/python-packages/pytest-doctestplus {
                    inherit (pyPrev) pytest-doctestplus;
                  };
                  duckdb-engine = import ./nix/python-packages/duckdb-engine {
                    inherit (pyPrev) duckdb-engine;
                  };
                  pydevd = import ./nix/python-packages/pydevd {
                    inherit (pyPrev) pydevd;
                  };
                };
              };
            })
          ];
        };

        py = pkgs.python311Packages;

        loguru-cpp = pkgs.callPackage ./nix/cxx-packages/loguru-cpp {};

        # Core utilities
        ascii-colors = py.callPackage ./nix/python-packages/ascii-colors {};
        nano-vectordb = py.callPackage ./nix/python-packages/nano-vectordb {};
        pipmaster = py.callPackage ./nix/python-packages/pipmaster {
          inherit ascii-colors;
        };

        # Vector databases (newer versions than nixpkgs)
        pymilvus = py.callPackage ./nix/python-packages/pymilvus {};
        pgvector = py.callPackage ./nix/python-packages/pgvector {};

        # LLM providers
        voyageai = py.callPackage ./nix/python-packages/voyageai {};
        zhipuai = py.callPackage ./nix/python-packages/zhipuai {};
        perplexityai = py.callPackage ./nix/python-packages/perplexityai {};

        # Graph algorithms (dependency for ragas)
        scikit-network = py.callPackage ./nix/python-packages/scikit-network {};

        # Evaluation
        ragas = py.callPackage ./nix/python-packages/ragas {
          inherit scikit-network;
        };

        # Document processing
        docling-parse = py.callPackage ./nix/python-packages/docling-parse {
          inherit loguru-cpp;
          system-cmake = pkgs.cmake;
          inherit (pkgs) pkg-config nlohmann_json;
        };
        docling = import ./nix/python-packages/docling {
          inherit (py) docling;
          inherit docling-parse;
        };

        mineru = py.callPackage ./nix/python-packages/mineru {};

        # Visualization
        imgui-bundle = py.callPackage ./nix/python-packages/imgui-bundle {
          inherit (pkgs) cmake pkg-config glfw libGL libGLU cudaPackages;
          glfw-py = py.glfw;
        };

        # RAG systems (depend on other custom packages)
        lightrag-hku = py.callPackage ./nix/python-packages/lightrag-hku {
          inherit nano-vectordb pipmaster;
        };
        raganything = py.callPackage ./nix/python-packages/raganything {
          inherit lightrag-hku mineru;
        };

        pythonWithPackages = pkgs.python311.withPackages (ps: [
          ps.python-dotenv
          ps.pyyaml
          ps.tiktoken
          ps.requests
          ps.openai
          ps.dashscope
          ps.aiohttp
          ps.httpx
          ps.urllib3

          ps.nest-asyncio
          ps.fastapi
          ps.uvicorn
          ps.websockets
          ps.python-multipart
          ps.pydantic
          ps.gunicorn

          ps.asyncpg
          ps.neo4j
          ps.pymongo
          ps.redis
          ps.qdrant-client

          ps.numpy
          ps.pandas
          ps.scipy
          ps.networkx
          ps.pillow
          ps.moderngl

          ps.arxiv
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

          ps.datasets
          ps.huggingface-hub
          ps.transformers
          ps.torch
          ps.torchvision
          ps.tokenizers

          ps.langchain
          ps.langchain-core
          ps.langchain-community
          ps.langchain-openai

          ps.anthropic
          ps.ollama
          ps.langfuse
          ps.pyglm
          ps.python-louvain
          ps.json-repair
          ps.pypinyin
          ps.google-genai

          ps.pytest
          ps.pytest-asyncio

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
        ]);

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
          default = pkgs.writeShellScriptBin "deeptutor-test" ''
            cd ${self}
            ${pythonWithPackages}/bin/python -m pytest tests/ -v --tb=short
          '';

          # Python packages (custom)
          inherit
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
            ;

          # Python packages (nixpkgs overrides)
          pytest-doctestplus = py.pytest-doctestplus;
          duckdb-engine = py.duckdb-engine;
          pydevd = py.pydevd;

          # C++ packages
          inherit loguru-cpp;

          # Full Python environment
          python = pythonWithPackages;
        };
      }
    );
}
