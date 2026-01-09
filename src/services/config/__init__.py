"""
Configuration Service
=====================

Unified configuration loading for all DeepTutor modules.

Usage:
    from src.services.config import load_config_with_main, PROJECT_ROOT

    # Load module configuration
    config = load_config_with_main("solve_config.yaml")

    # Get agent parameters
    params = get_agent_params("guide")

    # Get data directories (respects DEEPTUTOR_DATA_DIR env var)
    from src.services.config import get_data_dir, get_user_dir, get_knowledge_base_dir
    data_path = get_data_dir()
    user_path = get_user_dir()
    kb_path = get_knowledge_base_dir()
"""

from .loader import (
    PROJECT_ROOT,
    _deep_merge,
    get_agent_params,
    get_data_dir,
    get_knowledge_base_dir,
    get_path_from_config,
    get_user_dir,
    load_config_with_main,
    parse_language,
)

__all__ = [
    "PROJECT_ROOT",
    "load_config_with_main",
    "get_path_from_config",
    "parse_language",
    "get_agent_params",
    "get_data_dir",
    "get_user_dir",
    "get_knowledge_base_dir",
    "_deep_merge",
]
