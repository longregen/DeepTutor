{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pip,
}:

buildPythonPackage rec {
  pname = "pipmaster";
  version = "0.5.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [ pip ];

  doCheck = false;

  pythonImportsCheck = [ "pipmaster" ];

  meta = with lib; {
    description = "A Python package manager helper";
    homepage = "https://github.com/ParisNeo/pipmaster";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
