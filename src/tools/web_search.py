#!/usr/bin/env python
"""
Web Search Tool - Network search using Perplexity API, Baidu AI Search API, or Kagi Search API
"""

from datetime import datetime
from enum import Enum
import json
import os
import time

from src.services.search import BaiduAISearch, KagiSearch, RateLimitError, SearchError

try:
    from perplexity import Perplexity

    PERPLEXITY_AVAILABLE = True
except ImportError:
    PERPLEXITY_AVAILABLE = False
    Perplexity = None


class SearchProvider(str, Enum):
    """Supported search providers"""

    PERPLEXITY = "perplexity"
    BAIDU = "baidu"
    KAGI = "kagi"


async def _search_with_baidu(
    query: str,
    model: str = "ernie-4.5-turbo-32k",
    enable_deep_search: bool = False,
    search_recency_filter: str | None = None,
    verbose: bool = False,
) -> dict:
    """
    Perform search using Baidu AI Search API

    Args:
        query: Search query
        model: Model to use for generation
        enable_deep_search: Enable deep search
        search_recency_filter: Filter by recency
        verbose: Whether to print detailed information

    Returns:
        dict: Standardized search result
    """
    api_key = os.environ.get("BAIDU_API_KEY")
    if not api_key:
        raise ValueError(
            "BAIDU_API_KEY environment variable is not set. "
            "Please get your API key from https://console.bce.baidu.com/ai_apaas/resource"
        )

    client = BaiduAISearch(api_key=api_key)

    response = await client.search(
        query=query,
        model=model,
        enable_deep_search=enable_deep_search,
        search_recency_filter=search_recency_filter,
    )

    answer = ""
    if response.get("choices"):
        choice = response["choices"][0]
        if choice.get("message"):
            answer = choice["message"].get("content", "")

    result = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "model": model,
        "provider": "baidu",
        "answer": answer,
        "response": {
            "content": answer,
            "role": "assistant",
            "finish_reason": response.get("choices", [{}])[0].get("finish_reason", ""),
        },
        "usage": {},
        "citations": [],
        "search_results": [],
        "is_safe": response.get("is_safe", True),
        "request_id": response.get("request_id", ""),
    }

    if response.get("usage"):
        usage = response["usage"]
        result["usage"] = {
            "prompt_tokens": usage.get("prompt_tokens", 0),
            "completion_tokens": usage.get("completion_tokens", 0),
            "total_tokens": usage.get("total_tokens", 0),
        }

    if response.get("references"):
        for i, ref in enumerate(response["references"], 1):
            citation_data = {
                "id": ref.get("id", i),
                "reference": f"[{ref.get('id', i)}]",
                "url": ref.get("url", ""),
                "title": ref.get("title", ""),
                "snippet": ref.get("content", ""),
                "date": ref.get("date", ""),
                "type": ref.get("type", "web"),
                "icon": ref.get("icon", ""),
                "website": ref.get("website", ""),
                "web_anchor": ref.get("web_anchor", ""),
            }
            result["citations"].append(citation_data)

            # Also add to search_results for compatibility
            search_result = {
                "title": ref.get("title", ""),
                "url": ref.get("url", ""),
                "date": ref.get("date", ""),
                "snippet": ref.get("content", ""),
                "source": ref.get("web_anchor", ""),
            }
            result["search_results"].append(search_result)

    if response.get("followup_queries"):
        result["followup_queries"] = response["followup_queries"]

    if verbose:
        print(f"[Baidu AI Search] Query: {query}")
        print(f"[Baidu AI Search] Model: {model}")
        print(f"[Baidu AI Search] References count: {len(result['citations'])}")

    return result


async def _search_with_kagi(
    query: str,
    limit: int | None = None,
    verbose: bool = False,
) -> dict:
    """
    Perform search using Kagi Search API

    Args:
        query: Search query
        limit: Maximum number of results to return (optional)
        verbose: Whether to print detailed information

    Returns:
        dict: Standardized search result
    """
    api_key = os.environ.get("KAGI_API_KEY")
    if not api_key:
        raise ValueError(
            "KAGI_API_KEY environment variable is not set. "
            "Please get your API key from https://kagi.com/settings?p=api"
        )

    client = KagiSearch(api_key=api_key)

    response = await client.search(query=query, limit=limit)

    # Build standardized result
    result = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "model": "kagi-search",
        "provider": "kagi",
        "answer": "",
        "response": {
            "content": "",
            "role": "assistant",
            "finish_reason": "complete",
        },
        "usage": {},
        "citations": [],
        "search_results": [],
        "request_id": response.get("meta", {}).get("id", ""),
    }

    meta = response.get("meta", {})
    if meta:
        result["usage"] = {
            "api_balance": meta.get("api_balance", 0),
            "response_time_ms": meta.get("ms", 0),
        }

    data = response.get("data", [])
    related_searches = []

    for item in data:
        item_type = item.get("t", -1)

        if item_type == 0:
            # Type 0: Search result
            search_result = {
                "title": item.get("title", ""),
                "url": item.get("url", ""),
                "snippet": item.get("snippet", ""),
                "date": item.get("published", ""),
            }
            result["search_results"].append(search_result)

            # Also add to citations for compatibility
            citation_data = {
                "id": len(result["citations"]) + 1,
                "reference": f"[{len(result['citations']) + 1}]",
                "url": item.get("url", ""),
                "title": item.get("title", ""),
                "snippet": item.get("snippet", ""),
                "date": item.get("published", ""),
            }
            if item.get("thumbnail"):
                citation_data["thumbnail"] = item.get("thumbnail")
            result["citations"].append(citation_data)

        elif item_type == 1:
            # Type 1: Related searches
            related_searches.extend(item.get("list", []))

    # Add related searches if available
    if related_searches:
        result["related_searches"] = related_searches

    # Build answer from snippets (Kagi doesn't provide AI summary in search API)
    if result["search_results"]:
        snippets = [r["snippet"] for r in result["search_results"][:3] if r.get("snippet")]
        result["answer"] = " ".join(snippets)
        result["response"]["content"] = result["answer"]

    if verbose:
        print(f"[Kagi Search] Query: {query}")
        print(f"[Kagi Search] Results count: {len(result['search_results'])}")
        if meta.get("api_balance"):
            print(f"[Kagi Search] API Balance: ${meta.get('api_balance', 0):.2f}")

    return result


def _search_with_perplexity(query: str, verbose: bool = False) -> dict:
    """
    Perform search using Perplexity API

    Args:
        query: Search query
        verbose: Whether to print detailed information

    Returns:
        dict: Standardized search result
    """
    if not PERPLEXITY_AVAILABLE:
        raise ImportError(
            "perplexity module is not installed. To use Perplexity search, please install: "
            "pip install perplexity"
        )

    api_key = os.environ.get("PERPLEXITY_API_KEY")
    if not api_key:
        raise ValueError("PERPLEXITY_API_KEY environment variable is not set")

    if Perplexity is None:
        raise ImportError("Perplexity module is not available")

    client = Perplexity(api_key=api_key)

    completion = client.chat.completions.create(
        model="sonar",
        messages=[
            {
                "role": "system",
                "content": "You are a helpful AI assistant. Provide detailed and accurate answers based on web search results.",
            },
            {"role": "user", "content": query},
        ],
    )

    answer = completion.choices[0].message.content

    # Build usage info with safe attribute access
    usage_info: dict = {}
    if hasattr(completion, "usage") and completion.usage is not None:
        usage = completion.usage
        usage_info = {
            "prompt_tokens": getattr(usage, "prompt_tokens", 0),
            "completion_tokens": getattr(usage, "completion_tokens", 0),
            "total_tokens": getattr(usage, "total_tokens", 0),
        }
        if hasattr(usage, "cost") and usage.cost is not None:
            cost = usage.cost
            usage_info["cost"] = {
                "total_cost": getattr(cost, "total_cost", 0),
                "input_tokens_cost": getattr(cost, "input_tokens_cost", 0),
                "output_tokens_cost": getattr(cost, "output_tokens_cost", 0),
            }

    result = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "model": completion.model,
        "provider": "perplexity",
        "answer": answer,
        "response": {
            "content": answer,
            "role": completion.choices[0].message.role,
            "finish_reason": completion.choices[0].finish_reason,
        },
        "usage": usage_info,
        "citations": [],
        "search_results": [],
    }

    if hasattr(completion, "citations") and completion.citations:
        for i, citation_url in enumerate(completion.citations, 1):
            citation_data = {
                "id": i,
                "reference": f"[{i}]",
                "url": citation_url,
                "title": "",
                "snippet": "",
            }

            for search_item in result.get("search_results", []):
                if search_item.get("url") == citation_url:
                    citation_data["title"] = search_item.get("title", "")
                    citation_data["snippet"] = search_item.get("snippet", "")
                    break

            result["citations"].append(citation_data)

    # Extract search result details
    if hasattr(completion, "search_results") and completion.search_results:
        for search_item in completion.search_results:
            search_result = {
                "title": search_item.title,
                "url": search_item.url,
                "date": search_item.date,
                "last_updated": search_item.last_updated,
                "snippet": search_item.snippet,
                "source": search_item.source,
            }
            result["search_results"].append(search_result)

    if verbose:
        print(f"[Perplexity] Query: {query}")
        print(f"[Perplexity] Model: {completion.model}")

    return result


async def web_search(
    query: str,
    output_dir: str | None = None,
    verbose: bool = False,
    # Baidu-specific options
    baidu_model: str = "ernie-4.5-turbo-32k",
    baidu_enable_deep_search: bool = False,
    baidu_search_recency_filter: str = "week",
    # Kagi-specific options
    kagi_limit: int | None = None,
) -> dict:
    """
    Perform network search using specified search provider and return results

    Args:
        query: Search query
        output_dir: Output directory (optional, if provided will save results)
        verbose: Whether to print detailed information
        baidu_model: Model to use for Baidu AI Search (default: ernie-4.5-turbo-32k)
        baidu_enable_deep_search: Enable deep search for Baidu (more comprehensive results)
        baidu_search_recency_filter: Filter by recency for Baidu (week, month, semiyear, year)
        kagi_limit: Maximum number of results for Kagi search (optional)

    Returns:
        dict: Dictionary containing search results
            {
                "query": str,
                "answer": str,
                "provider": str,
                "result_file": str (if file was saved)
            }

    Raises:
        ImportError: If required module is not installed
        ValueError: If required environment variable is not set
        Exception: If API call fails
    """
    # Get search provider from environment variable
    provider = os.environ.get("SEARCH_PROVIDER", "perplexity").lower()

    try:
        if provider == "baidu":
            result = await _search_with_baidu(
                query=query,
                model=baidu_model,
                enable_deep_search=baidu_enable_deep_search,
                search_recency_filter=baidu_search_recency_filter,
                verbose=verbose,
            )
        elif provider == "perplexity":
            result = _search_with_perplexity(query=query, verbose=verbose)
        elif provider == "kagi":
            result = await _search_with_kagi(
                query=query,
                limit=kagi_limit,
                verbose=verbose,
            )
        else:
            raise ValueError(
                f"Unsupported search provider: {provider}. Use 'perplexity', 'baidu', or 'kagi'."
            )

        # If output directory provided, save results
        result_file = None
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_filename = f"search_{provider}_{timestamp}.json"
            output_path = os.path.join(output_dir, output_filename)

            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)

            result_file = output_path

            if verbose:
                print(f"Search results saved to: {output_path}")

        # Add file path to result
        if result_file:
            result["result_file"] = result_file

        if verbose:
            answer = result.get("answer", "")
            print(f"Query: {query}")
            if answer:
                print(f"Answer: {answer[:200]}..." if len(answer) > 200 else f"Answer: {answer}")

        return result

    except Exception as e:
        raise Exception(f"{provider.capitalize()} API call failed: {e!s}")


if __name__ == "__main__":
    import asyncio
    import sys

    if sys.platform == "win32":
        import io

        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

    async def main():
        # Test with different providers
        # Default: Perplexity
        # result = await web_search("What is a diffusion model?", output_dir="./test_output", verbose=True)

        # Test with Baidu AI Search
        result = await web_search(
            "What is a diffusion model?",
            output_dir="./test_output",
            verbose=True,
        )
        print("\nSearch completed!")
        print(f"Provider: {result.get('provider', 'unknown')}")
        print(f"Query: {result['query']}")
        answer = result.get("answer", "")
        print(f"Answer: {answer[:300]}..." if len(answer) > 300 else f"Answer: {answer}")

    asyncio.run(main())
