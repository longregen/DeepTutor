{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  requests,
  robust-downloader,
  fasttext-predict,
}:
buildPythonPackage rec {
  pname = "fast-langdetect";
  version = "1.0.0";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/f6/71/0db1ac89f8661048ebc22d62f503a2e147cb6872c5f2aeb659c1f02c1694/fast_langdetect-1.0.0-py3-none-any.whl";
    hash = "sha256-qrnjQ1zGZ6yLqLGjiHL3VJL2W3CHkB0POgKojUNs0io=";
  };

  build-system = [setuptools];

  dependencies = [
    requests
    robust-downloader
    fasttext-predict
  ];

  pythonImportsCheck = ["fast_langdetect"];

  meta = with lib; {
    description = "Ultra-fast language detection library built on FastText, achieving speeds ~80x faster than conventional approaches";
    homepage = "https://github.com/sudoskys/fast-langdetect";
    license = licenses.mit;
    maintainers = [];
  };
}
