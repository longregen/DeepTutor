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
    # Fix __rust_probestack undefined symbol with CARGO_BUILD_RUSTFLAGS = "-C probe-stack=inline"
    # ============================================================================
    wasmer = pyFinal.callPackage ./wasmer {};
    wasmer-compiler-cranelift = pyFinal.callPackage ./wasmer-compiler-cranelift {};
    wasmer-compiler-llvm = pyFinal.callPackage ./wasmer-compiler-llvm {};
    wasmer-compiler-singlepass = pyFinal.callPackage ./wasmer-compiler-singlepass {};

    # ============================================================================
    # Core utilities
    # ============================================================================
    ascii-colors = pyFinal.callPackage ./ascii-colors {};
    nano-vectordb = pyFinal.callPackage ./nano-vectordb {};
    pipmaster = pyFinal.callPackage ./pipmaster {
      inherit (pyFinal) ascii-colors;
    };

    # ============================================================================
    # Vector databases
    # ============================================================================
    pymilvus = pyFinal.callPackage ./pymilvus {};
    pgvector = pyFinal.callPackage ./pgvector {};

    # ============================================================================
    # LLM providers
    # ============================================================================
    voyageai = pyFinal.callPackage ./voyageai {};
    zhipuai = pyFinal.callPackage ./zhipuai {};
    perplexityai = pyFinal.callPackage ./perplexityai {};

    # ============================================================================
    # Graph algorithms
    # ============================================================================
    scikit-network = pyFinal.callPackage ./scikit-network {};

    # ============================================================================
    # Evaluation
    # ============================================================================
    ragas = pyFinal.callPackage ./ragas {
      inherit (pyFinal) scikit-network;
    };

    # ============================================================================
    # Document processing
    # ============================================================================
    docling-parse = pyFinal.callPackage ./docling-parse {
      inherit loguru-cpp;
      system-cmake = prev.cmake;
      inherit (prev) pkg-config nlohmann_json;
    };
    mineru = pyFinal.callPackage ./mineru {};

    # ============================================================================
    # Visualization
    # ============================================================================
    imgui-bundle = pyFinal.callPackage ./imgui-bundle {
      inherit (prev) cmake pkg-config glfw libGL libGLU cudaPackages;
      glfw-py = pyFinal.glfw;
    };

    # ============================================================================
    # RAG systems
    # ============================================================================
    lightrag-hku = pyFinal.callPackage ./lightrag-hku {
      inherit (pyFinal) nano-vectordb pipmaster;
    };
    raganything = pyFinal.callPackage ./raganything {
      inherit (pyFinal) lightrag-hku mineru;
    };
  }
