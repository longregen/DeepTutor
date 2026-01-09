{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  httpx,
  pydantic,
  cachetools,
  pyjwt,
}:

buildPythonPackage rec {
  pname = "zhipuai";
  version = "2.1.5";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    httpx
    pydantic
    cachetools
    pyjwt
  ];

  doCheck = false;

  pythonImportsCheck = [ "zhipuai" ];

  meta = with lib; {
    description = "ZhipuAI Python SDK for GLM models";
    homepage = "https://github.com/MetaGLM/zhipuai-sdk-python-v4";
    license = licenses.mit;
    maintainers = [ ];
  };
}
