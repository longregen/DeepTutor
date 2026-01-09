{
  lib,
  buildPythonPackage,
  fetchPypi,
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
  version = "1.3.11";
  pyproject = true;

  src = fetchPypi {
    pname = "MinerU";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

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

  doCheck = false;

  pythonImportsCheck = [ "magic_pdf" ];

  meta = with lib; {
    description = "MinerU - High quality data extraction from PDFs";
    homepage = "https://github.com/opendatalab/MinerU";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
