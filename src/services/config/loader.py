#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Configuration Loader
====================

Unified configuration loading for all DeepTutor modules.
"""

from pathlib import Path
from typing import Any

import yaml
import os


PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent


def _get_config_dir() -> Path:
    """
    Get the configuration directory path, respecting DEEPTUTOR_CONFIG_DIR environment variable.
    Defaults to PROJECT_ROOT/config.

    Returns:
        Path to the configuration directory
    """
    config_dir_env = os.environ.get("DEEPTUTOR_CONFIG_DIR")
    if config_dir_env:
        return Path(config_dir_env)
    return PROJECT_ROOT / "config"


def _deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """
    Deep merge two dictionaries, values in override will override values in base

    Args:
        base: Base configuration
        override: Override configuration

    Returns:
        Merged configuration
    """
    result = base.copy()

    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            # Recursively merge dictionaries
            result[key] = _deep_merge(result[key], value)
        else:
            # Direct override
            result[key] = value

    return result


def load_config_with_main(config_file: str) -> dict[str, Any]:
    """
    Load configuration file, automatically merge with main.yaml common configuration

    Args:
        config_file: Sub-module configuration file name (e.g., "solve_config.yaml")

    Returns:
        Merged configuration dictionary
    """
    config_dir = _get_config_dir()

    # 1. Load main.yaml (common configuration)
    main_config = {}
    main_config_path = config_dir / "main.yaml"
    if main_config_path.exists():
        try:
            with open(main_config_path, encoding="utf-8") as f:
                main_config = yaml.safe_load(f) or {}
        except Exception as e:
            print(f"⚠️ Failed to load main.yaml: {e}")

    # 2. Load sub-module configuration file
    module_config = {}
    module_config_path = config_dir / config_file
    if module_config_path.exists():
        try:
            with open(module_config_path, encoding="utf-8") as f:
                module_config = yaml.safe_load(f) or {}
        except Exception as e:
            print(f"⚠️ Failed to load {config_file}: {e}")

    # 3. Merge configurations: main.yaml as base, sub-module config overrides
    merged_config = _deep_merge(main_config, module_config)

    return merged_config


def parse_language(language: Any) -> str:
    """
    Unified language configuration parser, supports multiple input formats

    Supported language representations:
    - English: "en", "english", "English"
    - Chinese: "zh", "chinese", "Chinese"

    Args:
        language: Language configuration value (can be "zh"/"en"/"Chinese"/"English" etc.)

    Returns:
        Standardized language code: 'zh' or 'en', defaults to 'zh'
    """
    if not language:
        return "zh"

    if isinstance(language, str):
        lang_lower = language.lower()
        if lang_lower in ["en", "english"]:
            return "en"
        if lang_lower in ["zh", "chinese"]:
            return "zh"

    return "zh"  # Default Chinese


def get_agent_params(module_name: str) -> dict:
    """
    Get agent parameters (temperature, max_tokens) for a specific module.

    This function loads parameters from config/agents.yaml which serves as the
    SINGLE source of truth for all agent temperature and max_tokens settings.

    Args:
        module_name: Module name, one of:
            - "guide": Guide module agents
            - "solve": Solve module agents
            - "research": Research module agents
            - "question": Question module agents
            - "ideagen": IdeaGen module agents
            - "co_writer": CoWriter module agents
            - "narrator": Narrator agent (independent, for TTS)

    Returns:
        dict: Dictionary containing:
            - temperature: float, default 0.5
            - max_tokens: int, default 4096

    Example:
        >>> params = get_agent_params("guide")
        >>> params["temperature"]  # 0.5
        >>> params["max_tokens"]   # 8192
    """
    # Default values
    defaults = {
        "temperature": 0.5,
        "max_tokens": 4096,
    }

    # Try to load from agents.yaml
    try:
        config_path = _get_config_dir() / "agents.yaml"

        if config_path.exists():
            with open(config_path, encoding="utf-8") as f:
                agents_config = yaml.safe_load(f) or {}

            if module_name in agents_config:
                module_config = agents_config[module_name]
                return {
                    "temperature": module_config.get("temperature", defaults["temperature"]),
                    "max_tokens": module_config.get("max_tokens", defaults["max_tokens"]),
                }
    except Exception as e:
        print(f"⚠️ Failed to load agents.yaml: {e}, using defaults")

    return defaults


def get_data_dir() -> Path:
    """
    Get the data directory path, respecting DEEPTUTOR_DATA_DIR environment variable.

    For containerized deployments, set DEEPTUTOR_DATA_DIR to a writable path.
    Otherwise, defaults to PROJECT_ROOT/data.

    Returns:
        Path to the data directory
    """
    data_dir_env = os.environ.get("DEEPTUTOR_DATA_DIR")
    if data_dir_env:
        return Path(data_dir_env)
    return PROJECT_ROOT / "data"


def get_user_dir() -> Path:
    """
    Get the user data directory path (for logs, sessions, outputs, etc.).

    Returns:
        Path to the user data directory
    """
    return get_data_dir() / "user"


def get_knowledge_base_dir() -> Path:
    """
    Get the knowledge base directory path.

    Returns:
        Path to the knowledge bases directory
    """
    return get_data_dir() / "knowledge_bases"


def get_log_dir() -> Path:
    """
    Get the log directory path, respecting DEEPTUTOR_LOG_DIR environment variable.

    For containerized deployments, set DEEPTUTOR_LOG_DIR to a writable path.
    Otherwise, defaults to DEEPTUTOR_DATA_DIR/user/logs.

    Returns:
        Path to the log directory
    """
    log_dir_env = os.environ.get("DEEPTUTOR_LOG_DIR")
    if log_dir_env:
        return Path(log_dir_env)
    return get_user_dir() / "logs"


__all__ = [
    "PROJECT_ROOT",
    "load_config_with_main",
    "parse_language",
    "get_agent_params",
    "get_data_dir",
    "get_user_dir",
    "get_knowledge_base_dir",
    "get_log_dir",
    "_deep_merge",
    "_get_config_dir",
]
