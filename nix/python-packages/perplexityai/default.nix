{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonRelaxDepsHook,
  hatchling,
  hatch-fancy-pypi-readme,
  httpx,
  anyio,
  distro,
  pydantic,
  sniffio,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "perplexityai";
  version = "0.22.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-umv9EaTDjELQRC2sDKxs1ldun+A/so7IEV0nfpfAGPE=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'hatchling==1.26.3' 'hatchling'
  '';

  nativeBuildInputs = [
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [ "hatchling" ];

  build-system = [
    hatchling
    hatch-fancy-pypi-readme
  ];

  dependencies = [
    httpx
    anyio
    distro
    pydantic
    sniffio
    typing-extensions
  ];

  meta = with lib; {
    description = "Perplexity AI Python SDK";
    homepage = "https://github.com/perplexityai/perplexity-py";
    license = licenses.mit;
    maintainers = [ ];
  };
}
