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

import pytest

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from src.tools.web_search import KagiSearch, _search_with_kagi


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

    @patch("src.tools.web_search.requests.get")
    def test_successful_search(self, mock_get):
        """Test successful search with mocked response."""
        # Mock successful API response
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
                    "t": 0,  # Search result type
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
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")
        result = client.search(query="test query")

        # Verify request was made correctly
        mock_get.assert_called_once()
        call_args = mock_get.call_args
        assert call_args.kwargs["params"]["q"] == "test query"
        assert call_args.kwargs["headers"]["Authorization"] == "Bot test-key"
        assert call_args.kwargs["timeout"] == 60

        # Verify response
        assert result["meta"]["id"] == "test-request-id-123"
        assert result["meta"]["api_balance"] == 0.95
        assert len(result["data"]) == 2
        assert result["data"][0]["title"] == "Test Article 1"

    @patch("src.tools.web_search.requests.get")
    def test_search_with_limit(self, mock_get):
        """Test search with limit parameter."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "test-id", "api_balance": 0.95},
            "data": [],
        }
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")
        client.search(query="test query", limit=5)

        # Verify limit parameter was passed
        call_args = mock_get.call_args
        assert call_args.kwargs["params"]["limit"] == 5

    @patch("src.tools.web_search.requests.get")
    def test_empty_query_validation(self, mock_get):
        """Test that empty query is handled (API will validate)."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"meta": {}, "data": []}
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")
        # Empty query should still make the request (API validates)
        result = client.search(query="")

        call_args = mock_get.call_args
        assert call_args.kwargs["params"]["q"] == ""

    @patch("src.tools.web_search.requests.get")
    def test_api_error_non_200_response(self, mock_get):
        """Test handling of non-200 API response."""
        mock_response = MagicMock()
        mock_response.status_code = 400
        mock_response.text = '{"error": [{"code": 400, "msg": "Invalid query"}]}'
        mock_response.json.return_value = {
            "error": [{"code": 400, "msg": "Invalid query"}]
        }
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")

        with pytest.raises(Exception) as exc_info:
            client.search(query="test")

        assert "Kagi Search API error: 400" in str(exc_info.value)
        assert "Invalid query" in str(exc_info.value)

    @patch("src.tools.web_search.requests.get")
    def test_rate_limit_429_handling(self, mock_get):
        """Test handling of rate limit (429) response."""
        mock_response = MagicMock()
        mock_response.status_code = 429
        mock_response.text = '{"error": [{"code": 429, "msg": "Rate limit exceeded"}]}'
        mock_response.json.return_value = {
            "error": [{"code": 429, "msg": "Rate limit exceeded"}]
        }
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")

        with pytest.raises(Exception) as exc_info:
            client.search(query="test")

        assert "Kagi Search API error: 429" in str(exc_info.value)
        assert "Rate limit exceeded" in str(exc_info.value)

    @patch("src.tools.web_search.requests.get")
    def test_unauthorized_401_handling(self, mock_get):
        """Test handling of unauthorized (401) response for invalid API key."""
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_response.text = '{"error": [{"code": 401, "msg": "Unauthorized"}]}'
        mock_response.json.return_value = {
            "error": [{"code": 401, "msg": "Unauthorized"}]
        }
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="invalid-key")

        with pytest.raises(Exception) as exc_info:
            client.search(query="test")

        assert "Kagi Search API error: 401" in str(exc_info.value)
        assert "Unauthorized" in str(exc_info.value)

    @patch("src.tools.web_search.requests.get")
    def test_error_response_without_json(self, mock_get):
        """Test handling of error response without valid JSON."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        mock_response.json.side_effect = ValueError("No JSON")
        mock_get.return_value = mock_response

        client = KagiSearch(api_key="test-key")

        with pytest.raises(Exception) as exc_info:
            client.search(query="test")

        assert "Kagi Search API error: 500" in str(exc_info.value)
        assert "Internal Server Error" in str(exc_info.value)


class TestSearchWithKagi:
    """Test cases for _search_with_kagi wrapper function."""

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key-12345"})
    @patch("src.tools.web_search.requests.get")
    def test_successful_search_with_results(self, mock_get):
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
                    "t": 1,  # Related searches type
                    "list": ["related query 1", "related query 2"],
                },
            ],
        }
        mock_get.return_value = mock_response

        result = _search_with_kagi(query="test query", verbose=False)

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
        assert result["search_results"][0]["url"] == "https://example.com/page1"
        assert result["search_results"][0]["snippet"] == "This is the first example page."

        # Verify citations
        assert len(result["citations"]) == 2
        assert result["citations"][0]["id"] == 1
        assert result["citations"][0]["reference"] == "[1]"
        assert result["citations"][0]["url"] == "https://example.com/page1"
        assert result["citations"][0]["thumbnail"] == "https://example.com/thumb1.jpg"

        # Verify related searches
        assert "related_searches" in result
        assert result["related_searches"] == ["related query 1", "related query 2"]

        # Verify answer is constructed from snippets
        assert "first example page" in result["answer"]
        assert result["response"]["content"] == result["answer"]
        assert result["response"]["role"] == "assistant"
        assert result["response"]["finish_reason"] == "complete"

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_search_with_no_results(self, mock_get):
        """Test search with no results returns empty standardized format."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "req-456", "api_balance": 0.97},
            "data": [],
        }
        mock_get.return_value = mock_response

        result = _search_with_kagi(query="obscure query")

        assert result["search_results"] == []
        assert result["citations"] == []
        assert result["answer"] == ""
        assert "related_searches" not in result

    @patch.dict(os.environ, {}, clear=True)
    def test_missing_api_key_error(self):
        """Test that missing API key raises ValueError with helpful message."""
        # Ensure KAGI_API_KEY is not set
        os.environ.pop("KAGI_API_KEY", None)

        with pytest.raises(ValueError) as exc_info:
            _search_with_kagi(query="test")

        assert "KAGI_API_KEY environment variable is not set" in str(exc_info.value)
        assert "https://kagi.com/settings?p=api" in str(exc_info.value)

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_search_with_limit_parameter(self, mock_get):
        """Test that limit parameter is passed correctly."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"meta": {}, "data": []}
        mock_get.return_value = mock_response

        _search_with_kagi(query="test", limit=10)

        call_args = mock_get.call_args
        assert call_args.kwargs["params"]["limit"] == 10

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_search_with_verbose_output(self, mock_get, capsys):
        """Test verbose output prints expected information."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "req-789", "api_balance": 0.95, "ms": 200},
            "data": [
                {
                    "t": 0,
                    "url": "https://example.com",
                    "title": "Test",
                    "snippet": "Snippet",
                }
            ],
        }
        mock_get.return_value = mock_response

        _search_with_kagi(query="test query", verbose=True)

        captured = capsys.readouterr()
        assert "[Kagi Search] Query: test query" in captured.out
        assert "[Kagi Search] Results count: 1" in captured.out
        assert "[Kagi Search] API Balance: $0.95" in captured.out

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_timestamp_field_present(self, mock_get):
        """Test that timestamp field is present in result."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"meta": {}, "data": []}
        mock_get.return_value = mock_response

        result = _search_with_kagi(query="test")

        assert "timestamp" in result
        # Timestamp should be ISO format
        assert "T" in result["timestamp"]

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_network_timeout_handling(self, mock_get):
        """Test handling of network timeout."""
        import requests

        mock_get.side_effect = requests.Timeout("Connection timeout")

        with pytest.raises(requests.Timeout):
            _search_with_kagi(query="test")

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_connection_error_handling(self, mock_get):
        """Test handling of connection error."""
        import requests

        mock_get.side_effect = requests.ConnectionError("Network unreachable")

        with pytest.raises(requests.ConnectionError):
            _search_with_kagi(query="test")


class TestKagiSearchResultTypes:
    """Test handling of different Kagi result types."""

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_mixed_result_types(self, mock_get):
        """Test handling of mixed result types (t=0 and t=1)."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {"id": "test"},
            "data": [
                {
                    "t": 0,  # Search result
                    "url": "https://example.com/1",
                    "title": "Result 1",
                    "snippet": "Snippet 1",
                },
                {
                    "t": 1,  # Related searches
                    "list": ["query a", "query b"],
                },
                {
                    "t": 0,  # Another search result
                    "url": "https://example.com/2",
                    "title": "Result 2",
                    "snippet": "Snippet 2",
                },
            ],
        }
        mock_get.return_value = mock_response

        result = _search_with_kagi(query="test")

        # Should have 2 search results
        assert len(result["search_results"]) == 2
        # Should have related searches
        assert result["related_searches"] == ["query a", "query b"]

    @patch.dict(os.environ, {"KAGI_API_KEY": "test-key"})
    @patch("src.tools.web_search.requests.get")
    def test_result_without_optional_fields(self, mock_get):
        """Test handling of results missing optional fields."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "meta": {},
            "data": [
                {
                    "t": 0,
                    "url": "https://example.com",
                    # Missing: title, snippet, published, thumbnail
                }
            ],
        }
        mock_get.return_value = mock_response

        result = _search_with_kagi(query="test")

        # Should handle missing fields gracefully
        assert len(result["search_results"]) == 1
        assert result["search_results"][0]["title"] == ""
        assert result["search_results"][0]["snippet"] == ""
        assert result["search_results"][0]["date"] == ""
        assert "thumbnail" not in result["citations"][0]


# Integration tests (skipped unless KAGI_API_KEY is set)
@pytest.mark.skipif(
    not os.getenv("KAGI_API_KEY"),
    reason="KAGI_API_KEY environment variable not set - skipping integration tests",
)
class TestKagiSearchIntegration:
    """Integration tests with real Kagi API (requires API key)."""

    def test_real_api_search(self):
        """Test actual API call with real credentials."""
        result = _search_with_kagi(
            query="Python programming language",
            limit=3,
            verbose=False,
        )

        # Verify response structure
        assert result["provider"] == "kagi"
        assert result["query"] == "Python programming language"
        assert "timestamp" in result
        assert "search_results" in result
        assert "citations" in result

        # Should have some results
        if result["search_results"]:
            assert len(result["search_results"]) > 0
            first_result = result["search_results"][0]
            assert "url" in first_result
            assert "title" in first_result

    def test_real_api_balance_check(self):
        """Test that API balance is returned."""
        result = _search_with_kagi(query="test", limit=1)

        assert "usage" in result
        assert "api_balance" in result["usage"]
        # API balance should be a positive number
        assert result["usage"]["api_balance"] >= 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
