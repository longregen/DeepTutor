# Python packages overlay for DeepTutor
# Provides packages not available in nixpkgs

final: prev: {
  python311 = prev.python311.override {
    packageOverrides = pyFinal: pyPrev: {
      # Core utilities
      nano-vectordb = pyFinal.callPackage ./python-packages/nano-vectordb { };
      pipmaster = pyFinal.callPackage ./python-packages/pipmaster { };
      json-repair = pyFinal.callPackage ./python-packages/json-repair { };
      pypinyin = pyFinal.callPackage ./python-packages/pypinyin { };

      # Vector databases
      pymilvus = pyFinal.callPackage ./python-packages/pymilvus { };
      qdrant-client = pyFinal.callPackage ./python-packages/qdrant-client { };
      pgvector = pyFinal.callPackage ./python-packages/pgvector { };

      # LLM providers
      voyageai = pyFinal.callPackage ./python-packages/voyageai { };
      zhipuai = pyFinal.callPackage ./python-packages/zhipuai { };
      google-genai = pyFinal.callPackage ./python-packages/google-genai { };
      perplexityai = pyFinal.callPackage ./python-packages/perplexityai { };

      # Evaluation & Observability
      ragas = pyFinal.callPackage ./python-packages/ragas { };
      langfuse = pyFinal.callPackage ./python-packages/langfuse { };

      # Document processing
      docling = pyFinal.callPackage ./python-packages/docling { };
      mineru = pyFinal.callPackage ./python-packages/mineru { };

      # Visualization
      imgui-bundle = pyFinal.callPackage ./python-packages/imgui-bundle {
        inherit (prev) cmake pkg-config glfw libGL libGLU;
      };
      pyglm = pyFinal.callPackage ./python-packages/pyglm { };
      python-louvain = pyFinal.callPackage ./python-packages/python-louvain { };

      # RAG systems (depend on packages above)
      lightrag-hku = pyFinal.callPackage ./python-packages/lightrag-hku { };
      raganything = pyFinal.callPackage ./python-packages/raganything { };
    };
  };
}
