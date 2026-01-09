{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  httpx,
  pydantic,
  packaging,
  wrapt,
  backoff,
}:

buildPythonPackage rec {
  pname = "langfuse";
  version = "3.8.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    httpx
    pydantic
    packaging
    wrapt
    backoff
  ];

  doCheck = false;

  pythonImportsCheck = [ "langfuse" ];

  meta = with lib; {
    description = "Open source LLM observability platform";
    homepage = "https://github.com/langfuse/langfuse-python";
    license = licenses.mit;
    maintainers = [ ];
  };
}
