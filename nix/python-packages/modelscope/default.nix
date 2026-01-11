{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  filelock,
  requests,
  tqdm,
  urllib3,
}:

buildPythonPackage rec {
  pname = "modelscope";
  version = "1.33.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/86/05/63f01821681b2be5d1739b4aad7b186c28d4ead2c5c99a9fc4aa53c13c19/modelscope-1.33.0-py3-none-any.whl";
    hash = "sha256-2b3VZjA/gT12LhM0EAB+rxt48GXIcSKKs4ZAkZtwdIk=";
  };

  build-system = [setuptools];

  dependencies = [
    filelock
    requests
    tqdm
    urllib3
  ];

  pythonImportsCheck = ["modelscope"];

  meta = with lib; {
    description = "ModelScope is built upon the concept of Model-as-a-Service (MaaS). It seeks to bring together most advanced machine learning models from AI community, and to streamline the process of leveraging AI models in real-world applications";
    homepage = "https://github.com/modelscope/modelscope";
    license = licenses.asl20;
    maintainers = [];
  };
}
