{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  grpcio,
  grpcio-tools,
  httpx,
  numpy,
  portalocker,
  pydantic,
  urllib3,
}:

buildPythonPackage rec {
  pname = "qdrant-client";
  version = "1.12.1";
  pyproject = true;

  src = fetchPypi {
    pname = "qdrant_client";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    grpcio
    grpcio-tools
    httpx
    numpy
    portalocker
    pydantic
    urllib3
  ];

  doCheck = false;

  pythonImportsCheck = [ "qdrant_client" ];

  meta = with lib; {
    description = "Python client for Qdrant vector search engine";
    homepage = "https://github.com/qdrant/qdrant-client";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
