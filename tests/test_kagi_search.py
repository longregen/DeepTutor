#!/usr/bin/env python
"""
Unit tests for Kagi Search functionality.

These tests verify the Kagi Search API integration with proper error handling,
validation, and response parsing. Uses mocked responses for unit tests.
"""

import os
from pathlib import Path
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.services.search import KagiSearch, RateLimitError, SearchError
from src.tools.web_search import _search_with_kagi


class TestKagiSearchClient:
    """Test cases for KagiSearch client class."""

    def test_initialization(self):
        """Test KagiSearch client initialization."""
        api_key = "test-api-key-12345"
        client = KagiSearch(api_key=api_key)

        assert client.api_key == api_key
        assert client.headers["Authorization"] == f"Bot {api_key}"

    def test_base_url(self):
        """Test that BASE_URL is correctly set."""
        assert KagiSearch.BASE_URL == "https://kagi.com/api/v0/search"

    @pytest.mark.asyncio
    async def test_successful_search(self):
        """Test successful search with mocked response."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {
                "id": "test-request-id-123",
                "node": "us-central",
                "ms": 142,
                "api_balance": 0.95,
            },
            "data": [
                {
                    "t": 0,
                    "rank": 1,
                    "url": "https://example.com/article1",
                    "title": "Test Article 1",
                    "snippet": "This is a test snippet for article 1.",
                    "published": "2024-01-15",
                },
                {
                    "t": 0,
                    "rank": 2,
                    "url": "https://example.com/article2",
                    "title": "Test Article 2",
                    "snippet": "This is a test snippet for article 2.",
                    "published": "2024-01-10",
                },
            ],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            client = KagiSearch(api_key="test-key")
            result = await client.search(query="test query")

            # Verify response
            assert result["meta"]["id"] == "test-request-id-123"
            assert result["meta"]["api_balance"] == 0.95
            assert len(result["data"]) == 2
            assert result["data"][0]["title"] == "Test Article 1"

    @pytest.mark.asyncio
    async def test_search_with_limit(self):
        """Test search with limit parameter."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "test-id", "api_balance": 0.95},
            "data": [],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            client = KagiSearch(api_key="test-key")
            await client.search(query="test query", limit=5)

            # Verify limit parameter was passed
            call_args = mock_client.get.call_args
            assert call_args.kwargs["params"]["limit"] == 5

    @pytest.mark.asyncio
    async def test_empty_query_validation(self):
        """Test that empty query raises SearchError."""
        client = KagiSearch(api_key="test-key")

        with pytest.raises(SearchError) as exc_info:
            await client.search(query="")

        assert "empty" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_api_error_non_200_response(self):
        """Test handling of non-200 API response."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = '{"error": [{"code": 400, "msg": "Invalid query"}]}'
        mock_response.json.return_value = {
            "error": [{"code": 400, "msg": "Invalid query"}]
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            client = KagiSearch(api_key="test-key")

            with pytest.raises(SearchError) as exc_info:
                await client.search(query="test")

            assert "400" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_rate_limit_429_handling(self):
        """Test handling of rate limit (429) response."""
        mock_response = MagicMock()
        mock_response.status_code = 429
        mock_response.headers = {}
        mock_response.text = '{"error": [{"code": 429, "msg": "Rate limit exceeded"}]}'

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            client = KagiSearch(api_key="test-key")

            with pytest.raises(RateLimitError) as exc_info:
                await client.search(query="test", max_retries=1)

            assert "429" in str(exc_info.value) or "rate limit" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_unauthorized_401_handling(self):
        """Test handling of unauthorized (401) response for invalid API key."""
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_response.text = '{"error": [{"code": 401, "msg": "Unauthorized"}]}'
        mock_response.json.return_value = {
            "error": [{"code": 401, "msg": "Unauthorized"}]
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            client = KagiSearch(api_key="invalid-key")

            with pytest.raises(SearchError) as exc_info:
                await client.search(query="test")

            assert "401" in str(exc_info.value)


class TestSearchWithKagi:
    """Test cases for _search_with_kagi wrapper function."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key-12345"})
    async def test_successful_search_with_results(self):
        """Test successful search returns standardized result format."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {
                "id": "req-123",
                "node": "us-central",
                "ms": 150,
                "api_balance": 0.98,
            },
            "data": [
                {
                    "t": 0,
                    "rank": 1,
                    "url": "https://example.com/page1",
                    "title": "Example Page 1",
                    "snippet": "This is the first example page.",
                    "published": "2024-01-15",
                    "thumbnail": "https://example.com/thumb1.jpg",
                },
                {
                    "t": 0,
                    "rank": 2,
                    "url": "https://example.com/page2",
                    "title": "Example Page 2",
                    "snippet": "This is the second example page.",
                    "published": "2024-01-10",
                },
                {
                    "t": 1,
                    "list": ["related query 1", "related query 2"],
                },
            ],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            result = await _search_with_kagi(query="test query", verbose=False)

            # Verify standardized format
            assert result["query"] == "test query"
            assert result["provider"] == "kagi"
            assert result["model"] == "kagi-search"
            assert result["request_id"] == "req-123"

            # Verify usage info
            assert result["usage"]["api_balance"] == 0.98
            assert result["usage"]["response_time_ms"] == 150

            # Verify search results
            assert len(result["search_results"]) == 2
            assert result["search_results"][0]["title"] == "Example Page 1"

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_search_with_no_results(self):
        """Test search with no results returns empty standardized format."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "req-456", "api_balance": 0.97},
            "data": [],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            result = await _search_with_kagi(query="obscure query")

            assert result["search_results"] == []
            assert result["citations"] == []
            assert result["answer"] == ""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {}, clear=True)
    async def test_missing_api_key_error(self):
        """Test that missing API key raises ValueError with helpful message."""
        os.environ.pop("KAGI_API_KEY", None)

        with pytest.raises(ValueError) as exc_info:
            await _search_with_kagi(query="test")

        assert "KAGI_API_KEY" in str(exc_info.value)

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_timestamp_field_present(self):
        """Test that timestamp field is present in result."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"meta": {}, "data": []}

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            result = await _search_with_kagi(query="test")

            assert "timestamp" in result
            assert "T" in result["timestamp"]

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_network_timeout_handling(self):
        """Test handling of network timeout."""
        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(side_effect=httpx.TimeoutException("Connection timeout"))
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            with pytest.raises(SearchError) as exc_info:
                await _search_with_kagi(query="test")
            assert "timeout" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_connection_error_handling(self):
        """Test handling of connection error."""
        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(side_effect=httpx.ConnectError("Network unreachable"))
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            with pytest.raises(SearchError) as exc_info:
                await _search_with_kagi(query="test")
            assert "network unreachable" in str(exc_info.value).lower()


class TestKagiSearchResultTypes:
    """Test handling of different Kagi result types."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_mixed_result_types(self):
        """Test handling of mixed result types (t=0 and t=1)."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "test"},
            "data": [
                {
                    "t": 0,
                    "url": "https://example.com/1",
                    "title": "Result 1",
                    "snippet": "Snippet 1",
                },
                {
                    "t": 1,
                    "list": ["query a", "query b"],
                },
                {
                    "t": 0,
                    "url": "https://example.com/2",
                    "title": "Result 2",
                    "snippet": "Snippet 2",
                },
            ],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            result = await _search_with_kagi(query="test")

            assert len(result["search_results"]) == 2
            assert result["related_searches"] == ["query a", "query b"]

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    async def test_result_without_optional_fields(self):
        """Test handling of results missing optional fields."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {},
            "data": [
                {
                    "t": 0,
                    "url": "https://example.com",
                }
            ],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get = AsyncMock(return_value=mock_response)
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=None)
            mock_client_class.return_value = mock_client

            result = await _search_with_kagi(query="test")

            assert len(result["search_results"]) == 1
            assert result["search_results"][0]["title"] == ""
            assert result["search_results"][0]["snippet"] == ""


# Integration tests (skipped unless KAGI_API_KEY is set)
@pytest.mark.skipif(
    not os.getenv("KAGI_API_KEY"),
    reason="KAGI_API_KEY environment variable not set - skipping integration tests",
)
class TestKagiSearchIntegration:
    """Integration tests with real Kagi API (requires API key)."""

    @pytest.mark.asyncio
    async def test_real_api_search(self):
        """Test actual API call with real credentials."""
        result = await _search_with_kagi(
            query="Python programming language",
            limit=3,
            verbose=False,
        )

        assert result["provider"] == "kagi"
        assert result["query"] == "Python programming language"
        assert "timestamp" in result
        assert "search_results" in result

    @pytest.mark.asyncio
    async def test_real_api_balance_check(self):
        """Test that API balance is returned."""
        result = await _search_with_kagi(query="test", limit=1)

        assert "usage" in result
        assert "api_balance" in result["usage"]
        assert result["usage"]["api_balance"] >= 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
