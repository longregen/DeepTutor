{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  numpy,
}:

buildPythonPackage rec {
  pname = "nano-vectordb";
  version = "0.0.4.3";
  pyproject = true;

  src = fetchPypi {
    pname = "nano_vectordb";
    inherit version;
    hash = "sha256-PRMHRHbytznlEmGXTtRKpGdyVXmWYhlzTANQLJKe07U=";
  };

  postPatch = ''
    # Create missing requirements.txt that setup.py expects
    echo "numpy" > requirements.txt
  '';

  build-system = [ setuptools ];

  dependencies = [ numpy ];

  pythonImportsCheck = [ "nano_vectordb" ];

  meta = with lib; {
    description = "A simple, easy-to-hack vector database";
    homepage = "https://github.com/gusye1234/nano-vectordb";
    license = licenses.mit;
    maintainers = [ ];
  };
}
