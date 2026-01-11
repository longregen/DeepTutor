#!/usr/bin/env python
"""
Knowledge Base Path Configuration Module - Unified management of all paths
"""

import os
from pathlib import Path
import sys

_project_root = Path(__file__).resolve().parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))

from src.services.config import get_knowledge_base_dir

KNOWLEDGE_BASES_DIR = get_knowledge_base_dir()

# raganything module path
RAGANYTHING_PATH = _project_root.parent / "raganything" / "RAG-Anything"


# Ensure raganything path existence check
def check_raganything():
    """Check if raganything module exists"""
    return RAGANYTHING_PATH.exists()


# Environment variable configuration
def get_env_config():
    """Get environment variable configuration (unified read from env_config)"""
    try:
        from src.services.llm import get_llm_config

        cfg = get_llm_config()
        return {
            "api_key": cfg.api_key,
            "base_url": cfg.base_url,
        }
    except Exception:
        # Compatibility fallback: directly read environment variables
        return {
            "api_key": os.getenv("LLM_API_KEY"),
            "base_url": os.getenv("LLM_HOST"),
        }


# Add necessary paths to sys.path
def setup_paths():
    """Set Python module search paths"""
    # Add project root directory
    if str(_project_root) not in sys.path:
        sys.path.insert(0, str(_project_root))

    # Add raganything path (if exists)
    if check_raganything() and str(RAGANYTHING_PATH) not in sys.path:
        sys.path.insert(0, str(RAGANYTHING_PATH))


__all__ = [
    "KNOWLEDGE_BASES_DIR",
    "RAGANYTHING_PATH",
    "check_raganything",
    "get_env_config",
    "setup_paths",
]
