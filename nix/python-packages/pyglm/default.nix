{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage rec {
  pname = "PyGLM";
  version = "2.7.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [ "glm" ];

  meta = with lib; {
    description = "OpenGL Mathematics library for Python (GLM)";
    homepage = "https://github.com/Zuzu-Typ/PyGLM";
    license = licenses.zlib;
    maintainers = [ ];
  };
}
