# Dependency Security & Privacy Review

This document provides a comprehensive security and privacy analysis of all Python dependencies used by DeepTutor. Each package has been reviewed for telemetry, network behavior, data collection, and potential security concerns.

**Review Date:** January 2025
**Total Packages Reviewed:** 36 direct dependencies + transitive dependencies

---

## Table of Contents

- [Quick Reference: Telemetry Opt-Out](#quick-reference-telemetry-opt-out)
- [Risk Summary](#risk-summary)
- [Detailed Package Analysis](#detailed-package-analysis)
  - [Core Dependencies](#core-dependencies)
  - [HTTP and API Clients](#http-and-api-clients)
  - [Async Support](#async-support)
  - [Web Framework and Server](#web-framework-and-server)
  - [RAG and Knowledge Base](#rag-and-knowledge-base)
  - [Academic and Research Tools](#academic-and-research-tools)
  - [Development Tools](#development-tools)
  - [LlamaIndex Ecosystem](#llamaindex-ecosystem)
- [Packages Not in Nixpkgs](#packages-not-in-nixpkgs)
- [Recommendations](#recommendations)

---

## Quick Reference: Telemetry Opt-Out

Add these environment variables to disable all telemetry in dependencies:

```bash
# Ragas - RAG evaluation framework
export RAGAS_DO_NOT_TRACK=true

# Langfuse - LLM observability (if used)
export LANGFUSE_TRACING_ENABLED=false

# Optional: Reduce langfuse data if you want partial tracing
# export LANGFUSE_SAMPLE_RATE=0.1  # Only 10% of traces

# Qdrant - Disable version check
# (Set check_compatibility=False in QdrantClient constructor)
```

**Recommended `.env` addition:**

```bash
# Privacy: Disable dependency telemetry
RAGAS_DO_NOT_TRACK=true
LANGFUSE_TRACING_ENABLED=false
```

---

## Risk Summary

| Risk Level | Count | Packages |
|------------|-------|----------|
| 🟢 LOW | 32 | Most packages - no concerns |
| 🟡 LOW-MEDIUM | 2 | ragas, pipmaster |
| 🟠 MEDIUM | 0 | None |
| 🔴 HIGH | 0 | None |

### Packages with Telemetry

| Package | Telemetry Type | Opt-Out Method | Data Collected |
|---------|---------------|----------------|----------------|
| **ragas** | Usage analytics | `RAGAS_DO_NOT_TRACK=true` | User UUID, metrics used, LLM provider info |
| **langfuse** | Observability | `LANGFUSE_TRACING_ENABLED=false` | LLM traces, prompts, responses (to your endpoint) |

### Packages with Expected Network Activity

These packages make network requests as part of their core functionality:

| Package | Endpoint | Purpose |
|---------|----------|---------|
| openai | api.openai.com | OpenAI API calls |
| perplexityai | api.perplexity.ai | Perplexity API calls |
| dashscope | dashscope.aliyuncs.com | Alibaba Cloud API |
| lightrag-hku | User's vector DB | RAG operations |
| llama-cloud | cloud.llamaindex.ai | LlamaCloud services |

---

## Detailed Package Analysis

### Core Dependencies

#### python-dotenv
- **Version Required:** ≥1.0.0
- **Nixpkgs Version:** 1.2.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None
- **Author:** Saurabh Kumar
- **Repository:** [theskumar/python-dotenv](https://github.com/theskumar/python-dotenv)
- **Notes:** Pure configuration loader, no external communication

#### PyYAML
- **Version Required:** ≥6.0
- **Nixpkgs Version:** 6.0.3
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None
- **Author:** Kirill Simonov
- **Repository:** [yaml/pyyaml](https://github.com/yaml/pyyaml)
- **Notes:** YAML parser, fully offline

#### tiktoken
- **Version Required:** ≥0.5.0
- **Nixpkgs Version:** 0.12.0
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Downloads encoding files on first use (cached locally)
- **Author:** OpenAI (Shantanu Jain)
- **Repository:** [openai/tiktoken](https://github.com/openai/tiktoken)
- **Notes:** BPE tokenizer, one-time download then offline

---

### HTTP and API Clients

#### requests
- **Version Required:** ≥2.32.2
- **Nixpkgs Version:** 2.32.5
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** User-initiated only
- **Author:** Kenneth Reitz (PSF maintained)
- **Repository:** [psf/requests](https://github.com/psf/requests)

#### openai
- **Version Required:** ≥1.30.0
- **Nixpkgs Version:** 2.11.0
- **Risk Level:** 🟢 LOW
- **Telemetry:** None (sends SDK version in headers - standard practice)
- **Network:** OpenAI API endpoints only
- **Author:** OpenAI
- **Repository:** [openai/openai-python](https://github.com/openai/openai-python)

#### perplexityai
- **Version Required:** ≥0.1.0
- **Nixpkgs:** ❌ Not available
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Perplexity API only
- **Author:** Perplexity AI
- **Repository:** [perplexityai/perplexity-py](https://github.com/perplexityai/perplexity-py)
- **Notes:** Privacy-protective - strips system info from headers before sending

#### dashscope
- **Version Required:** ≥1.14.0
- **Nixpkgs Version:** 1.25.5
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Alibaba Cloud DashScope API
- **Author:** Alibaba Cloud
- **Repository:** [dashscope/dashscope-sdk-python](https://github.com/dashscope)

#### aiohttp
- **Version Required:** ≥3.9.4
- **Nixpkgs Version:** 3.13.2
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** User-initiated only
- **Author:** aio-libs team
- **Repository:** [aio-libs/aiohttp](https://github.com/aio-libs/aiohttp)

#### httpx
- **Version Required:** ≥0.27.0
- **Nixpkgs Version:** 0.28.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** User-initiated only
- **Author:** Tom Christie (Encode)
- **Repository:** [encode/httpx](https://github.com/encode/httpx)

#### urllib3
- **Version Required:** ≥2.2.1
- **Nixpkgs Version:** 2.6.0
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** User-initiated only
- **Author:** Andrey Petrov
- **Repository:** [urllib3/urllib3](https://github.com/urllib3/urllib3)

---

### Async Support

#### nest_asyncio
- **Version Required:** ≥1.5.8
- **Nixpkgs Version:** 1.6.0
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None
- **Author:** Ewald de Wit (deceased, now community maintained)
- **Repository:** [erdewit/nest_asyncio](https://github.com/erdewit/nest_asyncio) (archived)
- **New Maintainer:** [ib-api-reloaded/nest_asyncio](https://github.com/ib-api-reloaded/nest_asyncio)
- **Notes:** Patches asyncio for nested event loops, fully offline

---

### Web Framework and Server

#### fastapi
- **Version Required:** ≥0.100.0
- **Nixpkgs Version:** 0.121.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None (framework only)
- **Author:** Sebastián Ramírez (@tiangolo)
- **Repository:** [fastapi/fastapi](https://github.com/fastapi/fastapi)

#### uvicorn
- **Version Required:** ≥0.24.0
- **Nixpkgs Version:** 0.38.0
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Serves user application only
- **Author:** Tom Christie / Marcelo Trylesinski
- **Repository:** [encode/uvicorn](https://github.com/encode/uvicorn)

#### websockets
- **Version Required:** ≥12.0
- **Nixpkgs Version:** 15.0.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** User-initiated only
- **Author:** Aymeric Augustin
- **Repository:** [python-websockets/websockets](https://github.com/python-websockets/websockets)

#### python-multipart
- **Version Required:** ≥0.0.6
- **Nixpkgs Version:** 0.0.20
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None
- **Author:** Andrew Dunham / Kludex
- **Repository:** [Kludex/python-multipart](https://github.com/Kludex/python-multipart)

#### pydantic
- **Version Required:** ≥2.0.0
- **Nixpkgs Version:** 2.12.4
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** None
- **Author:** Samuel Colvin
- **Repository:** [pydantic/pydantic](https://github.com/pydantic/pydantic)

---

### RAG and Knowledge Base

#### lightrag-hku
- **Version Required:** ≥1.0.0
- **Nixpkgs:** ❌ Not available
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Connects to user-configured vector databases and LLM APIs
- **Author:** Zirui Guo (HKUDS)
- **Repository:** [HKUDS/LightRAG](https://github.com/HKUDS/LightRAG)
- **Security Notes:**
  - Uses `eval()` for dynamic class loading from config (validated against whitelist)
  - Standard ML framework pattern, not exploitable with trusted configs

#### raganything
- **Version Required:** ≥0.1.0
- **Nixpkgs:** ❌ Not available
- **Risk Level:** 🟢 LOW
- **Telemetry:** None (inherits from lightrag-hku)
- **Network:** User-configured endpoints only
- **Author:** Zirui Guo (HKUDS)
- **Repository:** [HKUDS/RAG-Anything](https://github.com/HKUDS/RAG-Anything)
- **Dependencies:** Depends on lightrag-hku and mineru

---

### Academic and Research Tools

#### arxiv
- **Version Required:** ≥2.0.0
- **Nixpkgs Version:** 2.3.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** arXiv API only (documented)
- **Author:** Lukas Schwab
- **Repository:** [lukasschwab/arxiv.py](https://github.com/lukasschwab/arxiv.py)

---

### Development Tools

#### pre-commit
- **Version Required:** ≥3.0.0
- **Nixpkgs Version:** 4.5.1
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Downloads hooks from configured repos
- **Author:** Anthony Sottile
- **Repository:** [pre-commit/pre-commit](https://github.com/pre-commit/pre-commit)

---

### LlamaIndex Ecosystem

All LlamaIndex packages are authored by **Jerry Liu** and the **run-llama team**.
Repository: [run-llama/llama_index](https://github.com/run-llama/llama_index)

| Package | Required | Nixpkgs | Risk |
|---------|----------|---------|------|
| llama-cloud | 0.1.35 | 0.1.45 | 🟢 LOW |
| llama-cloud-services | 0.6.54 | 0.6.79 | 🟢 LOW |
| llama-index | 0.14.12 | 0.14.12 | 🟢 LOW |
| llama-index-cli | 0.5.3 | 0.5.3 | 🟢 LOW |
| llama-index-core | 0.14.12 | 0.14.12 | 🟢 LOW |
| llama-index-embeddings-openai | 0.5.1 | 0.5.1 | 🟢 LOW |
| llama-index-indices-managed-llama-cloud | 0.9.4 | 0.9.4 | 🟢 LOW |
| llama-index-instrumentation | 0.4.2 | 0.4.2 | 🟢 LOW |
| llama-index-llms-openai | 0.6.12 | 0.6.12 | 🟢 LOW |
| llama-index-readers-file | 0.5.6 | 0.5.6 | 🟢 LOW |
| llama-index-readers-llama-parse | 0.5.1 | 0.5.1 | 🟢 LOW |
| llama-index-workflows | 2.11.6 | 2.11.6 | 🟢 LOW |
| llama-parse | 0.6.54 | 0.6.79 | 🟢 LOW |

**Notes:**
- Network requests go to LlamaCloud services when using cloud features
- Local-only operation possible with appropriate configuration
- No hidden telemetry

---

## Packages Not in Nixpkgs

The following packages require pip installation and have been security-reviewed:

### Clean Packages (No Concerns)

| Package | Author | Repository | Notes |
|---------|--------|------------|-------|
| **nano-vectordb** | JianbaiYe | [gusye1234/nano-vectordb](https://github.com/gusye1234/nano-vectordb) | Local JSON vector DB, 472 lines, no network |
| **json_repair** | mangiucugna | [mangiucugna/json_repair](https://github.com/mangiucugna/json_repair) | Pure Python JSON fixer, no dependencies |
| **pypinyin** | mozillazg | [mozillazg/python-pinyin](https://github.com/mozillazg/python-pinyin) | Offline Chinese→pinyin, no network |
| **pgvector** | pgvector | [pgvector/pgvector-python](https://github.com/pgvector/pgvector-python) | PostgreSQL extension, 1,580 lines |
| **imgui_bundle** | Pascal Thomet | [pthom/imgui_bundle](https://github.com/pthom/imgui_bundle) | GUI library, no telemetry |
| **pyglm** | Zuzu_Typ | [Zuzu-Typ/PyGLM](https://github.com/Zuzu-Typ/PyGLM) | Math library, no network |
| **python-louvain** | taynaud | [taynaud/python-louvain](https://github.com/taynaud/python-louvain) | Graph algorithm, 865 lines, offline |

### API SDKs (Expected Network Usage)

| Package | Author | Repository | Endpoint |
|---------|--------|------------|----------|
| **voyageai** | Voyage AI | [voyage-ai/voyageai-python](https://github.com/voyage-ai/voyageai-python) | api.voyageai.com |
| **zhipuai** | MetaGLM | [MetaGLM/zhipuai-sdk-python-v4](https://github.com/MetaGLM/zhipuai-sdk-python-v4) | open.bigmodel.cn |
| **google-genai** | Google | [googleapis/python-genai](https://github.com/googleapis/python-genai) | googleapis.com |
| **pymilvus** | Milvus | [milvus-io/pymilvus](https://github.com/milvus-io/pymilvus) | User's Milvus server |
| **qdrant-client** | Qdrant | [qdrant/qdrant-client](https://github.com/qdrant/qdrant-client) | User's Qdrant server |

### Packages with Telemetry

#### ragas
- **Author:** Ragas team
- **Repository:** [explodinggradients/ragas](https://github.com/explodinggradients/ragas)
- **Risk Level:** 🟡 LOW-MEDIUM
- **Telemetry Endpoint:** `https://t.explodinggradients.com`
- **Data Collected:**
  - Persistent user UUID (stored at `~/.local/share/ragas/uuid.json`)
  - Package version
  - Metrics used, evaluation events
  - LLM/embedding provider names (not API keys)
- **Opt-Out:**
  ```bash
  export RAGAS_DO_NOT_TRACK=true
  ```
- **Notes:** Telemetry is documented in README and data is anonymized

#### langfuse-python
- **Author:** Langfuse
- **Repository:** [langfuse/langfuse-python](https://github.com/langfuse/langfuse-python)
- **Risk Level:** 🟢 LOW (telemetry is core functionality)
- **Default Endpoint:** `https://cloud.langfuse.com` (configurable)
- **Data Collected:** LLM traces, prompts, responses (sent to YOUR configured endpoint)
- **Opt-Out:**
  ```bash
  export LANGFUSE_TRACING_ENABLED=false
  ```
- **Privacy Controls:**
  - `LANGFUSE_SAMPLE_RATE=0.1` - Send only 10% of traces
  - `mask` parameter - Custom data redaction function
  - Self-hosted option available
- **Notes:** This is an observability SDK - data collection is its purpose

### Packages with Security Notes

#### pipmaster
- **Author:** ParisNeo
- **Repository:** [ParisNeo/pipmaster](https://github.com/ParisNeo/pipmaster)
- **Risk Level:** 🟡 LOW-MEDIUM
- **Telemetry:** None
- **Security Concern:** Shell injection vulnerability in specialized functions
- **Vulnerable Functions:**
  - `check_vulnerabilities()` with untrusted `extra_args`
  - `UvPackageManager` methods
  - Async functions with untrusted input
- **Safe Functions:** `install()`, `install_multiple()`, `ensure_packages()`
- **Mitigation:** Don't pass untrusted user input to `extra_args` parameters

#### docling
- **Author:** IBM Research / DS4SD
- **Repository:** [DS4SD/docling](https://github.com/DS4SD/docling)
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** Remote fetch disabled by default
- **Notes:** Set `enable_remote_fetch=True` only if needed for HTML remote resources

#### MinerU (mineru)
- **Author:** OpenDataLab
- **Repository:** [opendatalab/MinerU](https://github.com/opendatalab/MinerU)
- **Risk Level:** 🟢 LOW
- **Telemetry:** None
- **Network:** One-time model download from HuggingFace Hub
- **Security Notes:**
  - Uses `eval()` for ML config loading (validated against whitelist)
  - Standard ML framework pattern

---

## Recommendations

### For Production Deployment

1. **Set telemetry opt-out environment variables:**
   ```bash
   export RAGAS_DO_NOT_TRACK=true
   export LANGFUSE_TRACING_ENABLED=false
   ```

2. **Review API key handling:**
   - All API keys should be in environment variables
   - Never commit `.env` files to version control

3. **For air-gapped environments, these packages work fully offline:**
   - python-dotenv, PyYAML, pydantic
   - nano-vectordb, json_repair, python-pinyin, pgvector
   - imgui_bundle, pyglm, python-louvain
   - nest_asyncio, python-multipart

4. **Network-dependent packages require:**
   - tiktoken: One-time encoding download
   - LlamaIndex: Cloud features need connectivity
   - LLM SDKs: API access

### For Maximum Privacy

```bash
# Add to your .env or environment
RAGAS_DO_NOT_TRACK=true
LANGFUSE_TRACING_ENABLED=false

# If using qdrant-client, in code:
# client = QdrantClient(..., check_compatibility=False)
```

### For Security-Sensitive Deployments

1. **Avoid pipmaster** for package management with untrusted input
2. **Pin all dependency versions** in requirements.txt (already done)
3. **Use virtual environments** to isolate dependencies
4. **Regularly update** dependencies for security patches

---

## Appendix: Nixpkgs Availability

| Status | Count | Notes |
|--------|-------|-------|
| ✅ In Nixpkgs | 33 | Available via `python311Packages.*` |
| ❌ Not in Nixpkgs | 3 | Require pip: perplexityai, lightrag-hku, raganything |

### Version Comparison (Nixpkgs vs Required)

| Package | Required | Nixpkgs | Status |
|---------|----------|---------|--------|
| llama-cloud | 0.1.35 | 0.1.45 | ⚠️ Newer in nixpkgs |
| llama-cloud-services | 0.6.54 | 0.6.79 | ⚠️ Newer in nixpkgs |
| llama-parse | 0.6.54 | 0.6.79 | ⚠️ Newer in nixpkgs |

All other packages have compatible versions in nixpkgs.

---

## References

- [NixOS Package Search](https://search.nixos.org/packages)
- [PyPI](https://pypi.org/)
- Individual package repositories linked above
