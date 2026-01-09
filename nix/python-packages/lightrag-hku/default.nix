{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  # Core dependencies
  aiohttp,
  networkx,
  numpy,
  pandas,
  pydantic,
  tiktoken,
  tenacity,
  python-dotenv,
  # Custom packages (from overlay)
  nano-vectordb,
  pipmaster,
  json-repair,
  pypinyin,
  # API/Web
  fastapi,
  uvicorn,
  httpx,
  openai,
  # Optional storage backends
  asyncpg,
  neo4j,
  pymongo,
  redis,
}:

buildPythonPackage rec {
  pname = "lightrag-hku";
  version = "1.3.8";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    # Core
    aiohttp
    networkx
    numpy
    pandas
    pydantic
    tiktoken
    tenacity
    python-dotenv
    nano-vectordb
    pipmaster
    json-repair
    pypinyin
    # API/Web
    fastapi
    uvicorn
    httpx
    openai
    # Storage (optional but commonly used)
    asyncpg
    neo4j
    pymongo
    redis
  ];

  doCheck = false;

  pythonImportsCheck = [ "lightrag" ];

  meta = with lib; {
    description = "LightRAG - Simple and Fast Retrieval-Augmented Generation";
    homepage = "https://github.com/HKUDS/LightRAG";
    license = licenses.mit;
    maintainers = [ ];
  };
}
