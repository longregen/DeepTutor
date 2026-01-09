{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  networkx,
  numpy,
}:

buildPythonPackage rec {
  pname = "python-louvain";
  version = "0.16";
  pyproject = true;

  src = fetchPypi {
    pname = "python_louvain";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    networkx
    numpy
  ];

  doCheck = false;

  pythonImportsCheck = [ "community" ];

  meta = with lib; {
    description = "Louvain Community Detection algorithm";
    homepage = "https://github.com/taynaud/python-louvain";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
