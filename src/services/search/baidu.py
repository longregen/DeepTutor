#!/usr/bin/env python
"""
Baidu AI Search Service - Using httpx for async HTTP requests
"""

import httpx


class BaiduAISearch:
    """Baidu AI Search client for intelligent search and generation"""

    BASE_URL = "https://qianfan.baidubce.com/v2/ai_search/chat/completions"

    def __init__(self, api_key: str):
        """
        Initialize Baidu AI Search client

        Args:
            api_key: Baidu Qianfan API Key (format: bce-v3/xxx or Bearer token)
        """
        self.api_key = api_key
        self.headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}" if not api_key.startswith("Bearer ") else api_key,
        }

    async def search(
        self,
        query: str,
        model: str = "ernie-4.5-turbo-32k",
        search_source: str = "baidu_search_v2",
        stream: bool = False,
        enable_deep_search: bool = False,
        enable_corner_markers: bool = True,
        enable_followup_queries: bool = False,
        temperature: float = 0.11,
        top_p: float = 0.55,
        search_mode: str = "auto",
        search_recency_filter: str | None = None,
        instruction: str = "",
    ) -> dict:
        """
        Perform intelligent search using Baidu AI Search API

        Args:
            query: Search query
            model: Model to use for generation (default: ernie-4.5-turbo-32k)
            search_source: Search engine version (baidu_search_v1 or baidu_search_v2)
            stream: Whether to use streaming response
            enable_deep_search: Enable deep search for more comprehensive results
            enable_corner_markers: Enable corner markers for reference citations
            enable_followup_queries: Enable follow-up query suggestions
            temperature: Model sampling temperature (0, 1]
            top_p: Model sampling top_p (0, 1]
            search_mode: Search mode (auto, required, disabled)
            search_recency_filter: Filter by recency (week, month, semiyear, year)
            instruction: System instruction for response style

        Returns:
            dict: API response containing search results and generated answer
        """
        payload = {
            "messages": [{"role": "user", "content": query}],
            "model": model,
            "search_source": search_source,
            "stream": stream,
            "enable_deep_search": enable_deep_search,
            "enable_corner_markers": enable_corner_markers,
            "enable_followup_queries": enable_followup_queries,
            "temperature": temperature,
            "top_p": top_p,
            "search_mode": search_mode,
        }

        if search_recency_filter:
            payload["search_recency_filter"] = search_recency_filter

        if instruction:
            payload["instruction"] = instruction

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(self.BASE_URL, headers=self.headers, json=payload)

            if response.status_code != 200:
                error_data = response.json() if response.text else {}
                raise Exception(
                    f"Baidu AI Search API error: {response.status_code} - "
                    f"{error_data.get('message', response.text)}"
                )

            return response.json()
