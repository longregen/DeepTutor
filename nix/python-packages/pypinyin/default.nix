{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pypinyin";
  version = "0.53.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "pypinyin" ];

  meta = with lib; {
    description = "Convert Chinese characters to pinyin";
    homepage = "https://github.com/mozillazg/python-pinyin";
    license = licenses.mit;
    maintainers = [ ];
  };
}
