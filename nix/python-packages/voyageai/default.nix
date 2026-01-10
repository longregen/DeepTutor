{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  httpx,
  pydantic,
  requests,
  tenacity,
  tokenizers,
  aiohttp,
  aiolimiter,
  numpy,
  pillow,
}:

buildPythonPackage rec {
  pname = "voyageai";
  version = "0.3.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vRtS0mF52RhTy9Kg5S3JXLDVJnYMbIMJWeAetf+eqhI=";
  };

  build-system = [ poetry-core ];

  dependencies = [
    httpx
    pydantic
    requests
    tenacity
    tokenizers
    aiohttp
    aiolimiter
    numpy
    pillow
  ];

  pythonImportsCheck = [ "voyageai" ];

  meta = with lib; {
    description = "Voyage AI Python SDK for embeddings";
    homepage = "https://github.com/voyage-ai/voyageai-python";
    license = licenses.mit;
    maintainers = [ ];
  };
}
