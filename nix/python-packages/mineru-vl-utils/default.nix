{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  httpx,
  aiofiles,
  pillow,
  pydantic,
  loguru,
}:
buildPythonPackage rec {
  pname = "mineru-vl-utils";
  version = "0.1.20";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/5e/6b/d0b400ab8d7496e63efa1608176d135dc5dd0f04f75922493dfedbc3c8a2/mineru_vl_utils-0.1.20-py3-none-any.whl";
    hash = "sha256-WwluqOD1ASNGy7LTZ75zw+OJZRsDSgHnG9Av8nOWg50=";
  };

  build-system = [setuptools];

  dependencies = [
    httpx
    aiofiles
    pillow
    pydantic
    loguru
  ];

  pythonImportsCheck = ["mineru_vl_utils"];

  meta = with lib; {
    description = "A lightweight wrapper that simplifies the process of sending requests and handling responses from the MinerU Vision-Language Model";
    homepage = "https://github.com/opendatalab/MinerU";
    license = licenses.asl20;
    maintainers = [];
  };
}
