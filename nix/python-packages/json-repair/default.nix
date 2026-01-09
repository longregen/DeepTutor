{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage rec {
  pname = "json-repair";
  version = "0.30.0";
  pyproject = true;

  src = fetchPypi {
    pname = "json_repair";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "json_repair" ];

  meta = with lib; {
    description = "Repair invalid JSON documents";
    homepage = "https://github.com/mangiucugna/json_repair";
    license = licenses.mit;
    maintainers = [ ];
  };
}
