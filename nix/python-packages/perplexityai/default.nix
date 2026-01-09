{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  requests,
  openai,
}:

buildPythonPackage rec {
  pname = "perplexityai";
  version = "0.1.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    requests
    openai
  ];

  doCheck = false;

  pythonImportsCheck = [ "perplexityai" ];

  meta = with lib; {
    description = "Perplexity AI Python SDK";
    homepage = "https://github.com/perplexityai/perplexity-py";
    license = licenses.mit;
    maintainers = [ ];
  };
}
