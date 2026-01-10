{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  httpx,
  pydantic,
  cachetools,
  pyjwt,
}:
buildPythonPackage rec {
  pname = "zhipuai";
  version = "2.1.5.20250825";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-UPw5glZe5jG9ZAsRZqHSI94ieVgCanSh3Q4m29WNcpw=";
  };

  postPatch = ''
    # Remove poetry-plugin-pypi-mirror from build requirements - only needed for PyPI mirroring
    sed -i 's/, "poetry-plugin-pypi-mirror[^"]*"//g; s/"poetry-plugin-pypi-mirror[^"]*", //g' pyproject.toml
    # Relax pyjwt version constraint (nixpkgs has 2.10.1, package wants <2.9.0)
    sed -i 's/pyjwt = "[^"]*"/pyjwt = ">=2.8.0"/' pyproject.toml
  '';

  build-system = [poetry-core];

  dependencies = [
    httpx
    pydantic
    cachetools
    pyjwt
  ];

  pythonImportsCheck = ["zhipuai"];

  meta = with lib; {
    description = "ZhipuAI Python SDK for GLM models";
    homepage = "https://github.com/MetaGLM/zhipuai-sdk-python-v4";
    license = licenses.mit;
    maintainers = [];
  };
}
