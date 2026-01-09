# Python packages for DeepTutor development environment
# Returns a function that takes python packages (ps) and returns list of packages
ps: [
  # ============================================================================
  # Core / Configuration
  # ============================================================================
  ps.python-dotenv
  ps.pyyaml
  ps.tiktoken
  ps.requests
  ps.openai
  ps.dashscope
  ps.aiohttp
  ps.httpx
  ps.urllib3

  # ============================================================================
  # Web Framework / API
  # ============================================================================
  ps.nest-asyncio
  ps.fastapi
  ps.uvicorn
  ps.websockets
  ps.python-multipart
  ps.pydantic
  ps.gunicorn

  # ============================================================================
  # Databases
  # ============================================================================
  ps.asyncpg
  ps.neo4j
  ps.pymongo
  ps.redis
  ps.qdrant-client

  # ============================================================================
  # Scientific / Numerical
  # ============================================================================
  ps.numpy
  ps.pandas
  ps.scipy
  ps.networkx
  ps.pillow
  ps.moderngl

  # ============================================================================
  # LlamaIndex
  # ============================================================================
  ps.arxiv
  ps.llama-cloud
  ps.llama-cloud-services
  ps.llama-index
  ps.llama-index-core
  ps.llama-index-embeddings-openai
  ps.llama-index-indices-managed-llama-cloud
  ps.llama-index-instrumentation
  ps.llama-index-llms-openai
  ps.llama-index-readers-file
  ps.llama-index-readers-llama-parse
  ps.llama-index-workflows

  # ============================================================================
  # ML / Deep Learning
  # ============================================================================
  ps.datasets
  ps.huggingface-hub
  ps.transformers
  ps.torch
  ps.torchvision
  ps.tokenizers

  # ============================================================================
  # LangChain
  # ============================================================================
  ps.langchain
  ps.langchain-core
  ps.langchain-community
  ps.langchain-openai

  # ============================================================================
  # LLM Providers / Clients
  # ============================================================================
  ps.anthropic
  ps.ollama
  ps.langfuse
  ps.pyglm
  ps.google-genai

  # ============================================================================
  # Utilities
  # ============================================================================
  ps.python-louvain
  ps.json-repair
  ps.pypinyin

  # ============================================================================
  # Testing
  # ============================================================================
  ps.pytest
  ps.pytest-asyncio

  # ============================================================================
  # Custom packages (from overlay)
  # ============================================================================
  ps.ascii-colors
  ps.nano-vectordb
  ps.pipmaster
  ps.pymilvus
  ps.pgvector
  ps.voyageai
  ps.zhipuai
  ps.perplexityai
  ps.scikit-network
  ps.ragas
  ps.docling-parse
  ps.docling
  ps.mineru
  ps.imgui-bundle
  ps.lightrag-hku
  ps.raganything
]
