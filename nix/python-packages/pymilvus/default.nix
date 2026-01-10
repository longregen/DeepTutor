{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  grpcio,
  protobuf,
  pandas,
  numpy,
  ujson,
  setuptools-scm,
  gitpython,
  python-dotenv,
}:

buildPythonPackage rec {
  pname = "pymilvus";
  version = "2.6.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-tIAsyVTejy1Hv41iMOkhllFNy4o3JrpgmNwnkJ1LyOM=";
  };

  build-system = [
    setuptools
    setuptools-scm
    gitpython
  ];

  dependencies = [
    grpcio
    protobuf
    pandas
    numpy
    ujson
    python-dotenv
  ];

  pythonImportsCheck = [ "pymilvus" ];

  meta = with lib; {
    description = "Python SDK for Milvus vector database";
    homepage = "https://github.com/milvus-io/pymilvus";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
