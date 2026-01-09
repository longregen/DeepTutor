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
}:

buildPythonPackage rec {
  pname = "pymilvus";
  version = "2.6.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    grpcio
    protobuf
    pandas
    numpy
    ujson
  ];

  doCheck = false;

  pythonImportsCheck = [ "pymilvus" ];

  meta = with lib; {
    description = "Python SDK for Milvus vector database";
    homepage = "https://github.com/milvus-io/pymilvus";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
