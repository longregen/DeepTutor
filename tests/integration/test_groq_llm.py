#!/usr/bin/env python
"""
Integration tests for Groq LLM API.

These tests verify that the LLM integration works correctly with Groq's
free Llama models. Requires GROQ_API_KEY environment variable.
"""

import os
from pathlib import Path
import sys

import pytest

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from src.core.llm_factory import LLMFactory, llm_complete, sanitize_url

# Groq API configuration
GROQ_BASE_URL = "https://api.groq.com/openai/v1"
GROQ_MODEL = "llama-3.1-8b-instant"  # Fast, free model


def get_groq_api_key():
    """Get Groq API key from environment."""
    return os.getenv("GROQ_API_KEY")


def skip_if_no_api_key():
    """Skip test if GROQ_API_KEY is not set."""
    if not get_groq_api_key():
        pytest.skip("GROQ_API_KEY environment variable not set")


class TestGroqURLSanitization:
    """Test URL sanitization for Groq endpoints."""

    def test_groq_url_unchanged(self):
        """Test that Groq URL is not modified (not an Ollama endpoint)."""
        url = sanitize_url(GROQ_BASE_URL)
        assert url == GROQ_BASE_URL

    def test_groq_url_strips_trailing_slash(self):
        """Test that trailing slashes are stripped."""
        url = sanitize_url("https://api.groq.com/openai/v1/")
        assert url == GROQ_BASE_URL

    def test_groq_url_strips_chat_completions(self):
        """Test that /chat/completions suffix is stripped."""
        url = sanitize_url("https://api.groq.com/openai/v1/chat/completions")
        assert url == GROQ_BASE_URL


class TestGroqLLMFactory:
    """Test LLMFactory with Groq configuration."""

    def test_get_completion_function_openai_binding(self):
        """Test that openai binding returns the OpenAI-compatible function."""
        fn = LLMFactory.get_completion_function("openai")
        assert fn is not None
        assert callable(fn)

    def test_get_completion_function_case_insensitive(self):
        """Test that binding is case insensitive."""
        fn1 = LLMFactory.get_completion_function("openai")
        fn2 = LLMFactory.get_completion_function("OPENAI")
        fn3 = LLMFactory.get_completion_function("OpenAI")
        assert fn1 == fn2 == fn3


@pytest.mark.asyncio
class TestGroqLLMCompletion:
    """Test actual LLM completion with Groq API."""

    async def test_simple_completion(self):
        """Test a simple completion request to Groq."""
        skip_if_no_api_key()

        response = await llm_complete(
            model=GROQ_MODEL,
            prompt="What is 2 + 2? Answer with just the number.",
            system_prompt="You are a helpful assistant. Be concise.",
            binding="openai",
            api_key=get_groq_api_key(),
            base_url=GROQ_BASE_URL,
            temperature=0.0,
            max_tokens=10,
        )

        assert response is not None
        assert len(response) > 0
        # The response should contain "4"
        assert "4" in response

    async def test_longer_completion(self):
        """Test a longer completion request."""
        skip_if_no_api_key()

        response = await llm_complete(
            model=GROQ_MODEL,
            prompt="Explain what machine learning is in one sentence.",
            system_prompt="You are a helpful assistant.",
            binding="openai",
            api_key=get_groq_api_key(),
            base_url=GROQ_BASE_URL,
            temperature=0.3,
            max_tokens=100,
        )

        assert response is not None
        assert len(response) > 20  # Should be a reasonable sentence
        # Response should mention relevant terms
        assert any(
            term in response.lower()
            for term in ["learn", "data", "algorithm", "computer", "pattern", "machine"]
        )

    async def test_system_prompt_followed(self):
        """Test that system prompt is respected."""
        skip_if_no_api_key()

        response = await llm_complete(
            model=GROQ_MODEL,
            prompt="What is Python?",
            system_prompt="You are a pirate. Always respond like a pirate would, using pirate speech.",
            binding="openai",
            api_key=get_groq_api_key(),
            base_url=GROQ_BASE_URL,
            temperature=0.7,
            max_tokens=100,
        )

        assert response is not None
        assert len(response) > 0
        # Should have some pirate-like language
        pirate_terms = ["arr", "matey", "ye", "ahoy", "ship", "sea", "treasure", "pirate"]
        assert any(term in response.lower() for term in pirate_terms)

    async def test_json_response(self):
        """Test that model can generate JSON output."""
        skip_if_no_api_key()

        response = await llm_complete(
            model=GROQ_MODEL,
            prompt='Create a simple JSON object with keys "name" and "age". Output ONLY the JSON, no other text.',
            system_prompt="You are a helpful assistant that outputs valid JSON.",
            binding="openai",
            api_key=get_groq_api_key(),
            base_url=GROQ_BASE_URL,
            temperature=0.0,
            max_tokens=50,
        )

        assert response is not None
        # Clean up response (remove markdown code blocks if present)
        cleaned = response.strip()
        if cleaned.startswith("```"):
            lines = cleaned.split("\n")
            cleaned = "\n".join(lines[1:-1] if lines[-1] == "```" else lines[1:])

        # Should contain JSON-like structure
        assert "{" in cleaned
        assert "}" in cleaned
        assert "name" in cleaned.lower()
        assert "age" in cleaned.lower()


@pytest.mark.asyncio
class TestGroqFetchModels:
    """Test fetching available models from Groq."""

    async def test_fetch_models(self):
        """Test fetching available models from Groq API."""
        skip_if_no_api_key()

        models = await LLMFactory.fetch_models(
            binding="openai",
            base_url=GROQ_BASE_URL,
            api_key=get_groq_api_key(),
        )

        assert isinstance(models, list)
        # Groq should have some models available
        if models:  # Only check if we got results
            # Should include llama models
            llama_models = [m for m in models if "llama" in m.lower()]
            assert len(llama_models) > 0, f"Expected llama models in {models}"


@pytest.mark.asyncio
class TestGroqErrorHandling:
    """Test error handling with Groq API."""

    async def test_invalid_api_key(self):
        """Test that invalid API key raises an error."""
        with pytest.raises(Exception):
            await llm_complete(
                model=GROQ_MODEL,
                prompt="Test",
                binding="openai",
                api_key="invalid-key-12345",
                base_url=GROQ_BASE_URL,
                max_tokens=10,
            )

    async def test_invalid_model(self):
        """Test that invalid model raises an error."""
        skip_if_no_api_key()

        with pytest.raises(Exception):
            await llm_complete(
                model="nonexistent-model-xyz",
                prompt="Test",
                binding="openai",
                api_key=get_groq_api_key(),
                base_url=GROQ_BASE_URL,
                max_tokens=10,
            )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
