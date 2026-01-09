{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  datasets,
  numpy,
  pandas,
  pydantic,
  openai,
  tiktoken,
  langchain,
  langchain-core,
  langchain-community,
  langchain-openai,
}:

buildPythonPackage rec {
  pname = "ragas";
  version = "0.3.7";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    datasets
    numpy
    pandas
    pydantic
    openai
    tiktoken
    langchain
    langchain-core
    langchain-community
    langchain-openai
  ];

  doCheck = false;

  pythonImportsCheck = [ "ragas" ];

  meta = with lib; {
    description = "Evaluation framework for Retrieval Augmented Generation pipelines";
    homepage = "https://github.com/explodinggradients/ragas";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
