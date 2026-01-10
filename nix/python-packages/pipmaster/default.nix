{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pip,
  ascii-colors,
}:
buildPythonPackage rec {
  pname = "pipmaster";
  version = "0.5.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-WcrFYyzqJis2uAWAlTRekFUs0seueO+RuG3e6FrNBkg=";
  };

  build-system = [setuptools];

  dependencies = [
    pip
    setuptools
    ascii-colors
  ];

  postPatch = ''
    touch requirements.txt
  '';

  pythonImportsCheck = ["pipmaster"];

  meta = with lib; {
    description = "A Python package manager helper";
    homepage = "https://github.com/ParisNeo/pipmaster";
    license = licenses.asl20;
    maintainers = [];
  };
}
