#!/usr/bin/env python
"""
Kagi Search Service - Using httpx for async HTTP requests
"""

import asyncio
import httpx


class SearchError(Exception):
    """Custom exception for search-related errors"""

    pass


class RateLimitError(SearchError):
    """Custom exception for rate limit errors"""

    pass


class KagiSearch:
    """Kagi Search API client for privacy-focused web search"""

    BASE_URL = "https://kagi.com/api/v0/search"

    def __init__(self, api_key: str):
        """
        Initialize Kagi Search client

        Args:
            api_key: Kagi API Key (Bot token)
        """
        self.api_key = api_key
        self.headers = {
            "Authorization": f"Bot {api_key}",
        }

    @staticmethod
    def _validate_query(query: str) -> str:
        """
        Validate and sanitize search query

        Args:
            query: Search query to validate

        Returns:
            str: Sanitized query string

        Raises:
            SearchError: If query validation fails
        """
        # Strip leading/trailing whitespace
        sanitized_query = query.strip()

        # Check if query is empty or whitespace only
        if not sanitized_query:
            raise SearchError("Search query cannot be empty or whitespace only")

        # Check query length (max 2000 characters)
        max_length = 2000
        if len(sanitized_query) > max_length:
            raise SearchError(
                f"Search query is too long ({len(sanitized_query)} characters). "
                f"Maximum allowed length is {max_length} characters"
            )

        return sanitized_query

    async def search(
        self,
        query: str,
        limit: int | None = None,
        max_retries: int = 3,
    ) -> dict:
        """
        Perform search using Kagi Search API with retry logic for rate limits

        Args:
            query: Search query
            limit: Maximum number of results to return (optional)
            max_retries: Maximum number of retry attempts for rate limits (default: 3)

        Returns:
            dict: API response containing search results

        Raises:
            SearchError: If query validation fails or other API errors occur
            RateLimitError: If rate limit is exceeded after retries
        """
        # Validate and sanitize query
        sanitized_query = self._validate_query(query)

        params = {"q": sanitized_query}
        if limit is not None:
            params["limit"] = limit

        last_exception = None
        for attempt in range(max_retries):
            try:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.get(
                        self.BASE_URL,
                        headers=self.headers,
                        params=params,
                    )

                    # Handle rate limiting specifically (HTTP 429)
                    if response.status_code == 429:
                        retry_after = response.headers.get("Retry-After")
                        retry_after_msg = f" (Retry-After: {retry_after}s)" if retry_after else ""

                        error_msg = f"Kagi Search API rate limit exceeded (HTTP 429){retry_after_msg}"

                        # If we have more retries available, wait and retry
                        if attempt < max_retries - 1:
                            # Use exponential backoff: 2^attempt seconds
                            wait_time = 2 ** attempt
                            # If Retry-After header is present, use it instead
                            if retry_after:
                                try:
                                    wait_time = int(retry_after)
                                except ValueError:
                                    pass  # Fall back to exponential backoff

                            print(f"{error_msg}. Retrying in {wait_time}s... (attempt {attempt + 1}/{max_retries})")
                            await asyncio.sleep(wait_time)
                            continue
                        else:
                            # No more retries, raise the error
                            raise RateLimitError(f"{error_msg}. Max retries ({max_retries}) exceeded.")

                    # Handle other non-200 responses
                    if response.status_code != 200:
                        error_data = response.json() if response.text else {}
                        error_detail = error_data.get('error', [{}])[0].get('msg', response.text) if error_data else response.text
                        raise SearchError(
                            f"Kagi Search API error: {response.status_code} - {error_detail}"
                        )

                    # Success - return the response
                    return response.json()

            except (RateLimitError, SearchError):
                # Re-raise our custom errors immediately (unless it's a rate limit and we have retries)
                raise
            except Exception as e:
                last_exception = e
                # For other errors, raise immediately wrapped in SearchError (don't retry)
                raise SearchError(f"Kagi Search API error: {e!s}")

        # If we've exhausted all retries, raise the last exception
        if last_exception:
            raise last_exception
        raise SearchError("Kagi Search API error: Unknown error after retries")
