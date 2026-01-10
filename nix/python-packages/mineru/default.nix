{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  pydantic,
  pillow,
  numpy,
  pypdf,
  pyyaml,
  tqdm,
  requests,
  beautifulsoup4,
  torch,
  torchvision,
  transformers,
  huggingface-hub,
}:
buildPythonPackage rec {
  pname = "mineru";
  version = "2.7.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/36/fd/d94ab07cbcfabae65a306a6d704214ec6024f443d8119e24234f1b3fa3ba/mineru-2.7.1-py3-none-any.whl";
    hash = "sha256-PBRBSfJ0mnm+JAgzw5Ihbd1pwVFt4WKynbrdvAzjj3M=";
  };

  build-system = [setuptools];

  # Disable ninja build hook - the Python ninja package from dependencies
  # activates a build hook that we need to skip for this wheel package.
  dontUseNinjaBuild = true;
  dontUseNinjaCheck = true;

  dependencies = [
    pydantic
    pillow
    numpy
    pypdf
    pyyaml
    tqdm
    requests
    beautifulsoup4
    torch
    torchvision
    transformers
    huggingface-hub
  ];

  pythonImportsCheck = ["mineru"];

  meta = with lib; {
    description = "MinerU - High quality data extraction from PDFs";
    homepage = "https://github.com/opendatalab/MinerU";
    license = licenses.asl20;
    maintainers = [];
  };
}
