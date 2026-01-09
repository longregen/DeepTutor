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
  # Additional missing dependencies
  configparser,
  future,
  pyuca,
  xlsxwriter,
}:

buildPythonPackage rec {
  pname = "lightrag-hku";
  version = "1.3.8";
  pyproject = true;

  src = fetchPypi {
    pname = "lightrag_hku";
    inherit version;
    hash = "sha256-OB3bg5qxj3kl9HscJ1JbjW0QfAAm+/0sPT+g1x/sZ08=";
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
    # Additional dependencies
    configparser
    future
    pyuca
    xlsxwriter
  ];

  pythonImportsCheck = [ "lightrag" ];

  meta = with lib; {
    description = "LightRAG - Simple and Fast Retrieval-Augmented Generation";
    homepage = "https://github.com/HKUDS/LightRAG";
    license = licenses.mit;
    maintainers = [ ];
  };
}
