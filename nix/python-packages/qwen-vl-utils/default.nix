{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  av,
  packaging,
  pillow,
  requests,
}:

buildPythonPackage rec {
  pname = "qwen-vl-utils";
  version = "0.0.14";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/c4/43/80f67e0336cb2fc725f8e06f7fe35c1d0fe946f4d2b8b2175e797e07349e/qwen_vl_utils-0.0.14-py3-none-any.whl";
    hash = "sha256-Xihle/0DHla9RHxZAbWN38ODUoXtEA9MVlgOCt4FTpY=";
  };

  build-system = [setuptools];

  dependencies = [
    av
    packaging
    pillow
    requests
  ];

  # Disable import check because the module imports torch/torchvision at import time
  # even though they are not declared dependencies (they are provided by the consumer)
  doCheck = false;

  meta = with lib; {
    description = "Helper functions for processing and integrating visual language information with Qwen-VL Series Model";
    homepage = "https://github.com/QwenLM/Qwen2-VL/tree/main/qwen-vl-utils";
    license = licenses.asl20;
    maintainers = [];
  };
}
