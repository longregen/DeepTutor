# Python packages overlay for DeepTutor
# Contains all custom Python package definitions and nixpkgs overrides
{prev}: let
  loguru-cpp = prev.callPackage ../cxx-packages/loguru-cpp {};
in
  pyFinal: pyPrev: {
    # ============================================================================
    # Nixpkgs overrides (fix broken tests, etc.)
    # ============================================================================
    pytest-doctestplus = import ./pytest-doctestplus {
      inherit (pyPrev) pytest-doctestplus;
    };
    duckdb-engine = import ./duckdb-engine {
      inherit (pyPrev) duckdb-engine;
    };
    pydevd = import ./pydevd {
      inherit (pyPrev) pydevd;
    };
    ibis-framework = pyPrev.ibis-framework.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or []) ++ ["test_bfs"];
    });
    sqlframe = pyPrev.sqlframe.overridePythonAttrs (old: {
      disabledTests =
        (old.disabledTests or [])
        ++ [
          "test_activate_postgres"
          "test_activate_databricks"
          "test_activate_duckdb"
          "test_activate_bigquery"
          "test_replace_pyspark_spark"
          "test_activate_redshift"
          "test_activate_standalone"
          "test_activate_snowflake"
          "test_activate_no_engine"
          "test_activate_testing_context_manager"
          "test_activate_no_engine_context_manager"
        ];
    });
    docling = import ./docling {
      inherit (pyPrev) docling;
      inherit (pyFinal) docling-parse;
    };

    # Remove duplicate CLI binaries to avoid conflicts
    llama-index-cli = import ./llama-index-cli {
      inherit (pyPrev) llama-index-cli;
    };
    llama-parse = import ./llama-parse {
      inherit (pyPrev) llama-parse;
    };

    # ============================================================================
    # WebAssembly runtime
    # ============================================================================
    # Not in nixpkgs: wasmer-python bindings are not packaged in nixpkgs (only the CLI tool)
    # Built from source to fix __rust_probestack undefined symbol issue
    # Maintenance: Monitor wasmer-python releases; custom postFixup patches .so with stub library
    wasmer = pyFinal.callPackage ./wasmer {};
    wasmer-compiler-cranelift = pyFinal.callPackage ./wasmer-compiler-cranelift {};
    wasmer-compiler-llvm = pyFinal.callPackage ./wasmer-compiler-llvm {};
    wasmer-compiler-singlepass = pyFinal.callPackage ./wasmer-compiler-singlepass {};

    # ============================================================================
    # Core utilities
    # ============================================================================
    # Not in nixpkgs: Small utility packages not deemed significant enough for nixpkgs
    # ascii-colors: Terminal color formatting library (niche use case)
    # nano-vectordb: Minimal vector database (specialized dependency for LightRAG)
    # pipmaster: Package management utility (dependency of LightRAG)
    # Maintenance: Low churn, stable APIs; update when LightRAG requires newer versions
    ascii-colors = pyFinal.callPackage ./ascii-colors {};
    nano-vectordb = pyFinal.callPackage ./nano-vectordb {};
    pipmaster = pyFinal.callPackage ./pipmaster {
      inherit (pyFinal) ascii-colors;
    };

    # ============================================================================
    # Vector databases
    # ============================================================================
    # Not in nixpkgs: Specialized database client libraries not yet packaged
    # pymilvus: Official Milvus Python SDK (niche, rapidly evolving)
    # pgvector: PostgreSQL vector extension client (newer than nixpkgs stable)
    # Maintenance: Update quarterly or when API changes; ensure compatibility with server versions
    pymilvus = pyFinal.callPackage ./pymilvus {};
    pgvector = pyFinal.callPackage ./pgvector {};

    # ============================================================================
    # LLM providers
    # ============================================================================
    # Not in nixpkgs: Proprietary LLM provider SDKs not packaged in nixpkgs
    # These are commercial API clients that change frequently with provider updates
    # voyageai: Voyage AI embeddings API client
    # zhipuai: Zhipu AI (Chinese LLM provider) client
    # perplexityai: Perplexity AI search/chat API client
    # Maintenance: Update when providers release breaking API changes or new features
    voyageai = pyFinal.callPackage ./voyageai {};
    zhipuai = pyFinal.callPackage ./zhipuai {};
    perplexityai = pyFinal.callPackage ./perplexityai {};

    # ============================================================================
    # Graph algorithms
    # ============================================================================
    # Not in nixpkgs: Available but outdated version in nixpkgs
    # Requires specific version (0.33.5) with Cython 3 compatibility
    # Maintenance: Pin to versions compatible with scipy/numpy in nixpkgs; watch for Cython updates
    scikit-network = pyFinal.callPackage ./scikit-network {};

    # ============================================================================
    # Evaluation
    # ============================================================================
    # Not in nixpkgs: RAG evaluation framework too specialized/new for nixpkgs
    # Depends on custom scikit-network version and rapidly evolving LangChain ecosystem
    # Maintenance: Update when LangChain APIs change; ensure scikit-network compatibility
    ragas = pyFinal.callPackage ./ragas {
      inherit (pyFinal) scikit-network;
    };

    # ============================================================================
    # Language detection
    # ============================================================================
    fasttext-predict = pyFinal.callPackage ./fasttext-predict {};
    robust-downloader = pyFinal.callPackage ./robust-downloader {};
    fast-langdetect = pyFinal.callPackage ./fast-langdetect {
      inherit (pyFinal) robust-downloader fasttext-predict;
    };
    modelscope = pyFinal.callPackage ./modelscope {};
    qwen-vl-utils = pyFinal.callPackage ./qwen-vl-utils {};
    mineru-vl-utils = pyFinal.callPackage ./mineru-vl-utils {};

    # ============================================================================
    # Document processing
    # ============================================================================
    # Not in nixpkgs: Specialized document parsing libraries not yet packaged
    # docling-parse: C++ extension requiring custom build (loguru-cpp integration)
    # mineru: Advanced PDF/document extraction (MinerU project, rapidly evolving)
    # Maintenance: docling-parse needs C++ toolchain updates; mineru updates may break API
    docling-parse = pyFinal.callPackage ./docling-parse {
      inherit loguru-cpp;
      system-cmake = prev.cmake;
      inherit (prev) pkg-config nlohmann_json;
    };
    mineru = pyFinal.callPackage ./mineru {
      inherit (pyFinal) fast-langdetect modelscope qwen-vl-utils mineru-vl-utils;
    };

    # ============================================================================
    # Visualization
    # ============================================================================
    # Not in nixpkgs: ImGui Python bindings not packaged (complex C++ dependency tree)
    # Requires OpenGL, GLFW, and Dear ImGui C++ libraries with custom build configuration
    # Maintenance: Update carefully; breaks easily with ImGui/GLFW version mismatches
    imgui-bundle = pyFinal.callPackage ./imgui-bundle {
      inherit (prev) cmake pkg-config glfw libGL libGLU cudaPackages;
      glfw-py = pyFinal.glfw;
    };

    # ============================================================================
    # RAG systems
    # ============================================================================
    # Not in nixpkgs: Cutting-edge RAG frameworks too new for nixpkgs
    # lightrag-hku: LightRAG framework from HKU research (active development, v1.3.8)
    # raganything: RAG system combining LightRAG + MinerU (experimental integration)
    # Maintenance: High churn; update frequently to track upstream; expect breaking changes
    lightrag-hku = pyFinal.callPackage ./lightrag-hku {
      inherit (pyFinal) nano-vectordb pipmaster;
    };
    raganything = pyFinal.callPackage ./raganything {
      inherit (pyFinal) lightrag-hku mineru;
    };
  }
