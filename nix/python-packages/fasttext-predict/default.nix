{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pybind11,
}:

buildPythonPackage rec {
  pname = "fasttext-predict";
  version = "0.9.2.4";
  pyproject = true;

  src = fetchPypi {
    pname = "fasttext_predict";
    inherit version;
    hash = "sha256-GKb7DXTH35KA2x+Wy3XZkL/QBPqdZpST6j3T1U+E28c=";
  };

  build-system = [ setuptools pybind11 ];

  dependencies = [ ];

  pythonImportsCheck = [ "fasttext" ];

  meta = with lib; {
    description = "A lightweight Python package providing only the predict method from fastText";
    homepage = "https://github.com/searxng/fasttext-predict";
    license = licenses.mit;
    maintainers = [ ];
  };
}
