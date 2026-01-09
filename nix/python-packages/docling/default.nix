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
  requests,
  filetype,
  beautifulsoup4,
  lxml,
  python-docx,
  openpyxl,
  python-pptx,
}:

buildPythonPackage rec {
  pname = "docling";
  version = "2.31.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    pydantic
    pillow
    numpy
    pypdf
    pyyaml
    requests
    filetype
    beautifulsoup4
    lxml
    python-docx
    openpyxl
    python-pptx
  ];

  doCheck = false;

  pythonImportsCheck = [ "docling" ];

  meta = with lib; {
    description = "Document understanding and conversion library by IBM";
    homepage = "https://github.com/docling-project/docling";
    license = licenses.mit;
    maintainers = [ ];
  };
}
