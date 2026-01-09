{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  numpy,
}:

buildPythonPackage rec {
  pname = "nano-vectordb";
  version = "0.0.6";
  pyproject = true;

  src = fetchPypi {
    pname = "nano_vectordb";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [ numpy ];

  doCheck = false;

  pythonImportsCheck = [ "nano_vectordb" ];

  meta = with lib; {
    description = "A simple, easy-to-hack vector database";
    homepage = "https://github.com/gusye1234/nano-vectordb";
    license = licenses.mit;
    maintainers = [ ];
  };
}
