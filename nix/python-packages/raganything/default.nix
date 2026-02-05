{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  huggingface-hub,
  tqdm,
  pillow,
  lightrag-hku,
  mineru,
  openai,
  python-dotenv,
  reportlab,
  markdown,
  weasyprint,
  pygments,
}:
buildPythonPackage rec {
  pname = "raganything";
  version = "1.2.8";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-PoF4bYlLwSPtBrQ28LTMWY1CwgaWJaRA9T0GIOtibAI=";
  };

  build-system = [setuptools];

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

  meta = with lib; {
    description = "RAG-Anything - Multimodal RAG System";
    homepage = "https://github.com/HKUDS/RAG-Anything";
    license = licenses.mit;
    maintainers = [];
  };
}
