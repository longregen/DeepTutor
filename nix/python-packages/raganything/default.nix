{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  # Core dependencies
  huggingface-hub,
  tqdm,
  pillow,
  # Custom packages (from overlay)
  lightrag-hku,
  mineru,
  # Optional
  openai,
  python-dotenv,
  reportlab,
  markdown,
  weasyprint,
  pygments,
}:

buildPythonPackage rec {
  pname = "raganything";
  version = "0.1.5";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    huggingface-hub
    tqdm
    pillow
    lightrag-hku
    mineru
    openai
    python-dotenv
    reportlab
    markdown
    weasyprint
    pygments
  ];

  doCheck = false;

  pythonImportsCheck = [ "raganything" ];

  meta = with lib; {
    description = "RAG-Anything - Multimodal RAG System";
    homepage = "https://github.com/HKUDS/RAG-Anything";
    license = licenses.mit;
    maintainers = [ ];
  };
}
