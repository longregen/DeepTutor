"""
Integration tests for free Llama model access via Groq API.

Groq provides free access to Llama models with generous rate limits.
These tests verify that DeepTutor can work with free Llama model providers.

To run these tests:
  1. Get a free API key from https://console.groq.com/
  2. Set the GROQ_API_KEY environment variable
  3. Run: pytest tests/integration/test_llama_integration.py -v

For CI, the GROQ_API_KEY should be set as a GitHub secret.
"""

import os
import sys
from unittest.mock import patch

import pytest

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


@pytest.mark.skipif(
    not os.environ.get("GROQ_API_KEY"),
    reason="GROQ_API_KEY not set - skipping Groq integration tests",
)
@pytest.mark.integration
class TestGroqLlamaIntegration:
    """Test integration with Groq's free Llama API."""

    GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
    GROQ_BASE_URL = "https://api.groq.com/openai/v1"
    # Groq offers several free Llama models
    LLAMA_MODEL = "llama-3.3-70b-versatile"

    @pytest.fixture
    def groq_config(self):
        """Return Groq configuration for testing."""
        return {
            "binding": "openai",  # Groq is OpenAI-compatible
            "model": self.LLAMA_MODEL,
            "host": self.GROQ_BASE_URL,
            "api_key": self.GROQ_API_KEY,
        }

    @pytest.mark.asyncio
    async def test_groq_llama_basic_completion(self, groq_config):
        """Test basic LLM completion using Groq's free Llama model."""
        from src.core.llm_factory import llm_complete

        response = await llm_complete(
            model=groq_config["model"],
            prompt="What is 2 + 2? Reply with just the number.",
            system_prompt="You are a helpful math assistant. Give brief answers.",
            binding=groq_config["binding"],
            api_key=groq_config["api_key"],
            base_url=groq_config["host"],
            temperature=0.1,
            max_tokens=50,
        )

        assert response is not None
        assert len(response) > 0
        # The response should contain "4" somewhere
        assert "4" in response

    @pytest.mark.asyncio
    async def test_groq_llama_longer_response(self, groq_config):
        """Test that Llama can generate longer, coherent responses."""
        from src.core.llm_factory import llm_complete

        response = await llm_complete(
            model=groq_config["model"],
            prompt="Explain the concept of recursion in programming in 2-3 sentences.",
            system_prompt="You are a computer science teacher.",
            binding=groq_config["binding"],
            api_key=groq_config["api_key"],
            base_url=groq_config["host"],
            temperature=0.3,
            max_tokens=200,
        )

        assert response is not None
        assert len(response) > 50  # Should be a meaningful response
        # Check for key terms that should appear in an explanation of recursion
        response_lower = response.lower()
        assert any(
            word in response_lower for word in ["function", "call", "itself", "base", "recursive"]
        )

    @pytest.mark.asyncio
    async def test_groq_fetch_models(self, groq_config):
        """Test fetching available models from Groq."""
        from src.core.llm_factory import llm_fetch_models

        models = await llm_fetch_models(
            binding=groq_config["binding"],
            base_url=groq_config["host"],
            api_key=groq_config["api_key"],
        )

        assert isinstance(models, list)
        # Groq should have some models available
        assert len(models) > 0
        # Check that at least one llama model is available
        llama_models = [m for m in models if "llama" in m.lower()]
        assert len(llama_models) > 0, f"Expected Llama models, got: {models}"


class TestLlamaIntegrationMocked:
    """
    Mocked tests for Llama integration that don't require an API key.
    These tests verify the integration logic without hitting external APIs.
    """

    @pytest.mark.asyncio
    async def test_llm_complete_with_mock(self):
        """Test llm_complete function with mocked response."""
        from src.core.llm_factory import llm_complete

        mock_response_content = "The answer is 4."

        # Mock the openai_complete_if_cache function to return directly
        with patch("src.core.llm_factory.openai_complete_if_cache") as mock_fn:
            mock_fn.return_value = mock_response_content

            response = await llm_complete(
                model="llama-3.3-70b-versatile",
                prompt="What is 2 + 2?",
                system_prompt="You are a helpful assistant.",
                binding="openai",
                api_key="test-key",
                base_url="https://api.groq.com/openai/v1",
                temperature=0.1,
                max_tokens=50,
            )

            assert response == mock_response_content
            # Verify the mock was called with expected arguments
            mock_fn.assert_called_once()
            call_kwargs = mock_fn.call_args.kwargs
            assert call_kwargs["model"] == "llama-3.3-70b-versatile"
            assert "2 + 2" in call_kwargs["prompt"]

    @pytest.mark.asyncio
    async def test_llm_factory_binding_selection(self):
        """Test that LLMFactory selects correct completion function for different bindings."""
        from lightrag.llm.openai import openai_complete_if_cache

        from src.core.llm_factory import LLMFactory

        # OpenAI-compatible bindings should use openai_complete_if_cache
        for binding in ["openai", "ollama", "groq", "openrouter", "deepseek"]:
            fn = LLMFactory.get_completion_function(binding)
            assert fn == openai_complete_if_cache, (
                f"Binding {binding} should use openai_complete_if_cache"
            )

        # Anthropic should use anthropic_complete
        fn = LLMFactory.get_completion_function("anthropic")
        assert fn == LLMFactory.anthropic_complete

        fn = LLMFactory.get_completion_function("claude")
        assert fn == LLMFactory.anthropic_complete

    def test_sanitize_url(self):
        """Test URL sanitization for different providers."""
        from src.core.llm_factory import sanitize_url

        # Test basic URL cleanup
        assert sanitize_url("https://api.openai.com/v1/") == "https://api.openai.com/v1"
        assert (
            sanitize_url("https://api.openai.com/v1/chat/completions")
            == "https://api.openai.com/v1"
        )

        # Test Ollama local URL handling
        assert sanitize_url("http://localhost:11434") == "http://localhost:11434/v1"
        assert sanitize_url("http://localhost:11434/v1") == "http://localhost:11434/v1"

        # Test Groq URL (should not add /v1)
        assert sanitize_url("https://api.groq.com/openai/v1") == "https://api.groq.com/openai/v1"

        # Test adding protocol
        assert sanitize_url("localhost:11434") == "http://localhost:11434/v1"


class TestDeepTutorLlamaConfiguration:
    """Test DeepTutor configuration for Llama models."""

    def test_settings_accept_groq_binding(self):
        """Test that settings can be configured for Groq."""
        from settings import LLMSettings

        # Create settings with Groq configuration
        settings = LLMSettings(
            binding="openai",  # Groq uses OpenAI-compatible API
            model="llama-3.3-70b-versatile",
            host="https://api.groq.com/openai/v1",
            api_key="test-api-key",
        )

        assert settings.binding == "openai"
        assert settings.model == "llama-3.3-70b-versatile"
        assert settings.host == "https://api.groq.com/openai/v1"
        assert settings.api_key == "test-api-key"

    def test_settings_from_env(self, monkeypatch):
        """Test loading settings from environment variables."""
        monkeypatch.setenv("LLM_BINDING", "openai")
        monkeypatch.setenv("LLM_MODEL", "llama-3.3-70b-versatile")
        monkeypatch.setenv("LLM_HOST", "https://api.groq.com/openai/v1")
        monkeypatch.setenv("LLM_API_KEY", "groq-test-key")

        # Need to reimport to pick up new env vars
        from settings import LLMSettings

        # Create a new instance to pick up env vars
        settings = LLMSettings()

        assert settings.binding == "openai"
        assert settings.model == "llama-3.3-70b-versatile"
        assert "groq" in settings.host.lower()


# Pytest configuration
def pytest_configure(config):
    """Configure pytest markers."""
    config.addinivalue_line(
        "markers", "integration: mark test as integration test requiring external API"
    )
