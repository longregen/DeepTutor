"""
Pytest configuration and fixtures for DeepTutor tests.
"""

import os
from pathlib import Path
import sys

import pytest

# Add project root to path for imports
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


def pytest_configure(config):
    """Configure custom pytest markers."""
    config.addinivalue_line(
        "markers", "integration: mark test as integration test requiring external APIs"
    )
    config.addinivalue_line("markers", "llama: mark test as requiring Llama model access")
    config.addinivalue_line("markers", "slow: mark test as slow running")


@pytest.fixture(scope="session")
def project_root():
    """Return the project root directory."""
    return PROJECT_ROOT


@pytest.fixture
def groq_api_key():
    """Return Groq API key from environment, or skip if not available."""
    key = os.environ.get("GROQ_API_KEY")
    if not key:
        pytest.skip("GROQ_API_KEY not set")
    return key


@pytest.fixture
def llm_config():
    """Return default LLM configuration for testing."""
    return {
        "binding": "openai",
        "model": "llama-3.3-70b-versatile",
        "host": "https://api.groq.com/openai/v1",
        "api_key": os.environ.get("GROQ_API_KEY", "test-key"),
    }


@pytest.fixture(autouse=True)
def setup_pythonpath():
    """Ensure PYTHONPATH is set correctly for all tests."""
    if str(PROJECT_ROOT) not in sys.path:
        sys.path.insert(0, str(PROJECT_ROOT))
