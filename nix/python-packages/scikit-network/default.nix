{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  cython,
  numpy,
  scipy,
}:

buildPythonPackage rec {
  pname = "scikit-network";
  version = "0.33.5";
  pyproject = true;

  src = fetchPypi {
    pname = "scikit_network";
    inherit version;
    hash = "sha256-riFJ2aKA/cS7rdX4p7F8ivYcBUvD+DR5K8YUg+Z4PBI=";
  };

  build-system = [
    setuptools
    cython
  ];

  # Remove strict version constraints not needed for Nix build
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-quiet '"pytest-runner",' "" \
      --replace-quiet '"cython <= 3.0.12",' '"cython",'
  '';

  dependencies = [
    numpy
    scipy
  ];

  pythonImportsCheck = [ "sknetwork" ];

  meta = with lib; {
    description = "Graph algorithms for Python";
    homepage = "https://github.com/sknetwork-team/scikit-network";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}
