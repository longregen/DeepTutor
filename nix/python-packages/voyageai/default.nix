{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  httpx,
  pydantic,
  tenacity,
  tokenizers,
}:

buildPythonPackage rec {
  pname = "voyageai";
  version = "0.3.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    httpx
    pydantic
    tenacity
    tokenizers
  ];

  doCheck = false;

  pythonImportsCheck = [ "voyageai" ];

  meta = with lib; {
    description = "Voyage AI Python SDK for embeddings";
    homepage = "https://github.com/voyage-ai/voyageai-python";
    license = licenses.mit;
    maintainers = [ ];
  };
}
