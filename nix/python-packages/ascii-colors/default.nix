{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wcwidth,
}:

buildPythonPackage rec {
  pname = "ascii_colors";
  version = "0.11.6";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-QJGklgfuDFDGMZanbHt35eIwsRGPoUWHxgPiF16Hvuw=";
  };

  build-system = [ setuptools ];

  dependencies = [ wcwidth ];

  pythonImportsCheck = [ "ascii_colors" ];

  meta = with lib; {
    description = "Rich Logging, Colors, Progress Bars & Menus - All In One";
    homepage = "https://github.com/ParisNeo/ascii_colors";
    license = licenses.mit;
    maintainers = [ ];
  };
}
