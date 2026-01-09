{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  numpy,
}:

buildPythonPackage rec {
  pname = "pgvector";
  version = "0.4.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-MiysDB3F1Byez3gr2ZkbeWZoXe46ALyHNjE5HtlJUTo=";
  };

  build-system = [ setuptools ];

  dependencies = [ numpy ];

  pythonImportsCheck = [ "pgvector" ];

  meta = with lib; {
    description = "pgvector support for Python";
    homepage = "https://github.com/pgvector/pgvector-python";
    license = licenses.mit;
    maintainers = [ ];
  };
}
