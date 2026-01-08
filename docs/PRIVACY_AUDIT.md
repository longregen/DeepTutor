# DeepTutor Privacy Audit Report

**Audit Date:** 2026-01-08
**Auditor:** Claude Code (Opus 4.5)
**Scope:** Full codebase privacy and data leakage analysis

---

## Executive Summary

DeepTutor **CAN be configured to run fully privately** with local LLMs, but requires careful configuration to ensure no data leaks to external services. By default, the system uses OpenAI APIs which send user data externally.

### Key Findings

| Risk Level | Finding |
|------------|---------|
| **CRITICAL** | API keys stored in plaintext (`llm_providers.json`) |
| **HIGH** | CORS allows all origins (`allow_origins=["*"]`) |
| **HIGH** | No authentication on API endpoints |
| **MEDIUM** | Logs may contain sensitive query data |
| **INFO** | External services are fully configurable |
| **GOOD** | No telemetry, analytics, or phone-home functionality |
| **GOOD** | No author-owned domains in runtime code |
| **GOOD** | Usage statistics are LOCAL only |

---

## 1. External Services Analysis

### 1.1 Services That Can Send Data Externally

| Service | Default State | Data Sent | Can Be Disabled/Localized |
|---------|--------------|-----------|---------------------------|
| **LLM API** | Required | User queries, documents, prompts | ✅ Yes (Ollama/local) |
| **Embedding API** | Required | Document text for vectorization | ✅ Yes (Ollama/local) |
| **TTS API** | Optional | Narration scripts | ✅ Yes (local OpenAI-compatible TTS) |
| **Perplexity Search** | Optional | Search queries | ✅ Yes (disable web search) |
| **Baidu Search** | Optional | Search queries | ✅ Yes (disable web search) |
| **ArXiv API** | Optional | Paper search queries | ⚠️ Partially (no API key, public metadata only) |

### 1.2 Hardcoded External URLs

The following URLs are hardcoded but **only used as fallbacks when no configuration is provided**:

| File | URL | When Used |
|------|-----|-----------|
| `src/core/llm_factory.py:31` | `https://api.anthropic.com/v1/messages` | Only if Anthropic binding selected without base_url |
| `src/tools/web_search.py:32` | `https://qianfan.baidubce.com/v2/ai_search/chat/completions` | Only if Baidu search enabled |
| `settings.py:26` | `http://localhost:11434/v1/` | **DEFAULT** - Local Ollama (privacy-safe) |
| `settings.py:66` | `http://localhost:11434/v1/` | **DEFAULT** - Local Ollama (privacy-safe) |

**Good News:** The default settings in `settings.py` point to local Ollama (`localhost:11434`), making the default configuration privacy-friendly.

### 1.3 Telemetry, Analytics & Phone-Home Analysis

**VERIFIED: No telemetry or analytics services are present in the codebase.**

| Check | Result | Details |
|-------|--------|---------|
| Google Analytics | ❌ Not Found | No `gtag`, `gtm`, or GA scripts |
| Mixpanel | ❌ Not Found | No Mixpanel SDK |
| Segment | ❌ Not Found | No Segment tracking |
| Amplitude | ❌ Not Found | No Amplitude SDK |
| Sentry | ❌ Not Found | No error reporting service |
| PostHog | ❌ Not Found | No PostHog analytics |
| Custom Telemetry | ❌ Not Found | No phone-home endpoints |

### 1.4 Author/HKUDS Domain Analysis

**VERIFIED: No author-owned domains make runtime connections.**

The `HKUDS` (HKU Data Intelligence Lab) domain references are found ONLY in:

| Location | Type | Runtime Impact |
|----------|------|----------------|
| `README.md` | Documentation | ❌ None |
| `Communication.md` | Social links | ❌ None |
| `.github/workflows/` | CI/CD | ❌ None |
| `ghcr.io/hkuds/deeptutor` | Docker image | ❌ Only when pulling image |
| `scripts/generate_roster.py` | Development script | ❌ None |

**No runtime code connects to HKUDS domains.**

### 1.5 Usage Statistics & Observability

**All statistics are LOCAL only** - nothing is sent externally.

| Component | Location | Data Collected | Sent Externally |
|-----------|----------|----------------|-----------------|
| `LLMStats` | `src/core/logging/llm_stats.py` | Token counts, costs | ❌ No - terminal output only |
| `TokenTracker` | `src/agents/*/utils/token_tracker.py` | Per-agent token usage | ❌ No - saved to local JSON |
| `PerformanceMonitor` | `src/agents/solve/utils/performance_monitor.py` | Agent performance metrics | ❌ No - local `performance_report.json` |
| `ProgressTracker` | `src/knowledge/progress_tracker.py` | Document processing progress | ❌ No - internal WebSocket only |

All "callbacks" in the codebase are for **internal WebSocket communication** to the frontend, not external reporting.

### 1.6 Frontend External Dependencies

| Dependency | Source | When Loaded | Privacy Impact |
|------------|--------|-------------|----------------|
| **Google Fonts (Inter)** | `next/font/google` | Build time only | ✅ Downloaded during `npm build`, not at runtime |
| **KaTeX** | Local (`/katex/`) | Runtime (Guide page) | ✅ **BUNDLED LOCALLY** - No external requests |

**KaTeX is now bundled locally** in `web/public/katex/` - no CDN requests are made.

---

## 2. Data Flow Analysis

### 2.1 What Data Goes Where

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INPUT                                      │
│  (Questions, Documents, Knowledge Bases)                                    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DeepTutor Backend                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Solve Agent  │  │ Guide Agent  │  │Research Agent│  │Question Agent│    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
            ▼                       ▼                       ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│   LLM Provider   │   │ Embedding Service│   │  Optional Tools  │
│                  │   │                  │   │                  │
│ • OpenAI         │   │ • OpenAI         │   │ • Perplexity     │
│ • Anthropic      │   │ • Ollama ✓       │   │ • Baidu Search   │
│ • Ollama ✓       │   │ • Local LM       │   │ • ArXiv API      │
│ • DeepSeek       │   │                  │   │ • TTS Service    │
│ • OpenRouter     │   │                  │   │                  │
│ • Groq           │   │                  │   │                  │
│ • Gemini         │   │                  │   │                  │
│ • lollms ✓       │   │                  │   │                  │
└──────────────────┘   └──────────────────┘   └──────────────────┘
       │                       │                       │
       │                       │                       │
       ▼                       ▼                       ▼
    EXTERNAL               EXTERNAL                EXTERNAL
    (unless                (unless                 (all can be
    local)                 local)                  disabled)

✓ = Can be fully local/private
```

### 2.2 Data Stored Locally

All user data is stored locally in `/data/`:

```
data/
├── user/
│   ├── llm_providers.json    # ⚠️ Contains API keys in PLAINTEXT
│   ├── history.json          # User activity history
│   ├── logs/                 # Operation logs (may contain queries)
│   ├── solve/                # Problem solving outputs
│   ├── question/             # Generated questions
│   ├── research/             # Research reports
│   ├── guide/                # Learning sessions
│   ├── co_writer/            # Co-writer outputs + audio
│   ├── notebooks/            # User notebooks
│   └── performance/          # Performance metrics
└── knowledge_bases/
    └── <kb_name>/
        ├── metadata.json     # KB metadata
        ├── rag_storage/      # Vector DB (LightRAG)
        └── documents/        # Original uploaded files
```

---

## 3. Security Vulnerabilities

### 3.1 CRITICAL: Plaintext API Key Storage

**Location:** `src/core/llm_provider.py` → `/data/user/llm_providers.json`

```python
# API keys stored without encryption:
{
  "name": "openai-default",
  "api_key": "sk-...",  # PLAINTEXT!
  "base_url": "https://api.openai.com/v1",
  ...
}
```

**Recommendation:** For local-only deployment, this is acceptable. For any network-exposed deployment, implement encryption or use environment variables only.

### 3.2 HIGH: No Authentication

**Location:** `src/api/main.py:44-50`

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows ANY origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Risk:** Any website can make requests to the DeepTutor API.

**Recommendation:** For private deployment:
1. Run behind a firewall
2. Bind to `127.0.0.1` only (not `0.0.0.0`)
3. Add API key authentication if network-exposed

### 3.3 MEDIUM: Logging May Contain Sensitive Data

**Location:** `config/main.yaml` - Default log level is `DEBUG`

Logs stored in `/data/user/logs/` may contain:
- User queries
- LLM responses
- Document content

**Recommendation:** Set `level: INFO` or `WARNING` in production.

---

## 4. Complete Private Deployment Guide

### 4.1 Required Local Services

For **100% private operation** with no external data transmission:

| Service | Purpose | Recommended Solution |
|---------|---------|---------------------|
| **LLM** | Text generation | [Ollama](https://ollama.ai/) |
| **Embeddings** | Vector search | Ollama with embedding model |
| **TTS (Optional)** | Voice narration | [Coqui TTS](https://github.com/coqui-ai/TTS) or local OpenAI-compatible TTS server |

### 4.2 Minimal Private Setup (Ollama Only)

#### Step 1: Install Ollama

```bash
# Linux/macOS
curl -fsSL https://ollama.ai/install.sh | sh

# Windows: Download from https://ollama.ai/download
```

#### Step 2: Pull Required Models

```bash
# LLM Model (choose based on your hardware)
ollama pull llama3.2:3b        # Light (8GB VRAM)
ollama pull qwen2.5:7b         # Medium (16GB VRAM)
ollama pull qwen2.5:32b        # Heavy (32GB+ VRAM)

# Embedding Model
ollama pull nomic-embed-text   # Recommended
# OR
ollama pull mxbai-embed-large  # Alternative
```

#### Step 3: Configure DeepTutor

Create `.env` file:

```bash
# ============================================
# PRIVATE/LOCAL CONFIGURATION
# ============================================

# LLM Configuration - Local Ollama
LLM_BINDING=ollama
LLM_MODEL=qwen2.5:7b
LLM_HOST=http://localhost:11434/v1/
LLM_API_KEY=ollama

# Embedding Configuration - Local Ollama
EMBEDDING_BINDING=ollama
EMBEDDING_MODEL=nomic-embed-text
EMBEDDING_DIMENSION=768
EMBEDDING_HOST=http://localhost:11434/v1/
EMBEDDING_API_KEY=ollama

# DISABLE ALL EXTERNAL SERVICES
SEARCH_PROVIDER=
PERPLEXITY_API_KEY=
BAIDU_API_KEY=

# TTS - Disable or use local
TTS_MODEL=
TTS_URL=
TTS_API_KEY=

# Security
DISABLE_SSL_VERIFY=false
```

#### Step 4: Disable Web Search in Config

Edit `config/main.yaml`:

```yaml
tools:
  web_search:
    enabled: false  # Disable external web search
  query_item:
    enabled: true
research:
  researching:
    enable_web_search: false      # Disable Perplexity/Baidu
    enable_paper_search: false    # Disable ArXiv (or keep if public metadata is acceptable)
```

#### Step 5: Secure Network Access (Optional)

For maximum privacy, bind to localhost only. In `src/api/main.py` (line 127-132):

```python
uvicorn.run(
    "api.main:app",
    host="127.0.0.1",  # Change from 0.0.0.0 to 127.0.0.1
    port=backend_port,
    ...
)
```

### 4.3 Docker Private Deployment

```yaml
# docker-compose.private.yml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  deeptutor:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: deeptutor
    depends_on:
      - ollama
    environment:
      - LLM_BINDING=ollama
      - LLM_MODEL=qwen2.5:7b
      - LLM_HOST=http://ollama:11434/v1/
      - LLM_API_KEY=ollama
      - EMBEDDING_BINDING=ollama
      - EMBEDDING_MODEL=nomic-embed-text
      - EMBEDDING_DIMENSION=768
      - EMBEDDING_HOST=http://ollama:11434/v1/
      - EMBEDDING_API_KEY=ollama
      - SEARCH_PROVIDER=
      - PERPLEXITY_API_KEY=
      - BAIDU_API_KEY=
    ports:
      - "127.0.0.1:8001:8001"
      - "127.0.0.1:3782:3782"
    volumes:
      - ./data:/app/data
      - ./config:/app/config:ro

volumes:
  ollama_data:
```

---

## 5. Privacy Checklist

### Before Deployment

- [ ] Install Ollama locally
- [ ] Pull LLM model (e.g., `qwen2.5:7b`)
- [ ] Pull embedding model (e.g., `nomic-embed-text`)
- [ ] Configure `.env` with local endpoints
- [ ] Disable web search in `config/main.yaml`
- [ ] Set logging level to `INFO` or higher
- [ ] Bind API to localhost only (if not using Docker)
- [x] KaTeX bundled locally (no CDN dependency)

### Verification

Run these checks to verify no external calls:

```bash
# Monitor network connections (Linux)
sudo netstat -tuln | grep -E "11434|8001|3782"

# Watch for external connections (should only see localhost)
sudo tcpdump -i any port not 11434 and port not 8001 and port not 3782

# Check Ollama is being used
curl http://localhost:11434/api/tags
```

---

## 6. Feature Availability in Private Mode

| Feature | Available Privately | Notes |
|---------|:------------------:|-------|
| Problem Solving | ✅ | Full functionality with local LLM |
| Knowledge Base / RAG | ✅ | Full functionality with local embeddings |
| Question Generation | ✅ | Full functionality |
| Research Mode | ⚠️ | Works but no web/paper search |
| Interactive Guide | ✅ | Full functionality |
| Co-Writer | ⚠️ | Works but TTS requires local setup |
| IdeaGen | ✅ | Full functionality |
| Notebook | ✅ | Full functionality |

---

## 7. Services Required for Full Private Usage

### Minimum (Core Features)

1. **Ollama** - Local LLM inference server
   - Port: 11434
   - Models: LLM + Embedding model

### Extended (All Features)

1. **Ollama** - LLM and Embeddings
2. **Local TTS Server** - For Co-Writer narration (optional)
   - Options: Coqui TTS, Piper TTS, or any OpenAI-compatible TTS server

### Not Required (External-Only)

These services are NOT needed for private deployment:
- OpenAI API
- Anthropic API
- Perplexity API
- Baidu Search API
- Any cloud-based LLM service

---

## 8. Conclusion

DeepTutor is **well-designed for private deployment**. The default configuration already points to localhost Ollama, and all external services are configurable. Key recommendations:

1. **Use the default Ollama configuration** in `settings.py`
2. **Disable web search** if privacy is critical
3. **Bind to localhost** for maximum security
4. **Monitor logs** for sensitive data exposure
5. **Never expose the API** to the public internet without authentication

With proper configuration, DeepTutor can run completely air-gapped with zero data leakage to external services.

---

## Appendix A: Configuration Reference

### Environment Variables

| Variable | Description | Private Setting |
|----------|-------------|-----------------|
| `LLM_BINDING` | LLM provider type | `ollama` |
| `LLM_MODEL` | Model name | `qwen2.5:7b` (or similar) |
| `LLM_HOST` | API endpoint | `http://localhost:11434/v1/` |
| `LLM_API_KEY` | API key | `ollama` (anything works locally) |
| `EMBEDDING_BINDING` | Embedding provider | `ollama` |
| `EMBEDDING_MODEL` | Embedding model | `nomic-embed-text` |
| `EMBEDDING_HOST` | Embedding endpoint | `http://localhost:11434/v1/` |
| `EMBEDDING_API_KEY` | Embedding API key | `ollama` |
| `SEARCH_PROVIDER` | Search provider | `` (empty = disabled) |
| `TTS_MODEL` | TTS model | `` (empty = disabled) |

### Supported Local LLM Bindings

- `ollama` - Local Ollama server
- `lollms` - LoLLMs local server

### Embedding Dimensions by Model

| Model | Dimension |
|-------|-----------|
| `nomic-embed-text` | 768 |
| `mxbai-embed-large` | 1024 |
| `all-minilm` | 384 |
| `bge-large` | 1024 |

---

## Appendix B: KaTeX Local Bundling (COMPLETED)

**Status: ✅ IMPLEMENTED**

KaTeX v0.16.9 has been bundled locally for privacy. The files are located in:

```
web/public/katex/
├── katex.min.css
├── katex.min.js
├── contrib/
│   └── auto-render.min.js
└── fonts/
    └── (all KaTeX font files)
```

The Guide page (`web/app/guide/page.tsx`) now loads KaTeX from local files:

```javascript
const katexCSS = '<link rel="stylesheet" href="/katex/katex.min.css">';
const katexJS = '<script defer src="/katex/katex.min.js"></script>';
const katexAutoRender = '<script defer src="/katex/contrib/auto-render.min.js" onload="renderMathInElement(document.body);"></script>';
```

**No external CDN requests are made for math rendering.**

---

## Appendix C: Network Monitoring Commands

Use these commands to verify no unexpected external connections:

```bash
# Linux - Monitor all outgoing connections
sudo tcpdump -i any -n 'dst port 80 or dst port 443' | grep -v 'localhost\|127.0.0.1\|11434'

# macOS - Monitor connections
nettop -P -m route

# Windows PowerShell - Check established connections
Get-NetTCPConnection | Where-Object {$_.State -eq 'Established' -and $_.RemotePort -in 80,443} | Select RemoteAddress

# Docker - Monitor container network
docker run --rm --net=host nicolaka/netshoot tcpdump -i any -n 'dst port 80 or dst port 443'
```

---

*Report generated by Claude Code privacy audit tool*
