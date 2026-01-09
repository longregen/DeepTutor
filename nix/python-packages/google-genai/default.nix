{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  google-auth,
  httpx,
  pydantic,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "google-genai";
  version = "1.0.0";
  pyproject = true;

  src = fetchPypi {
    pname = "google_genai";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    google-auth
    httpx
    pydantic
    typing-extensions
  ];

  doCheck = false;

  pythonImportsCheck = [ "google.genai" ];

  meta = with lib; {
    description = "Google Generative AI Python SDK";
    homepage = "https://github.com/googleapis/python-genai";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
