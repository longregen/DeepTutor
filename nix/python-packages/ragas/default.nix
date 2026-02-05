{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  # Core dependencies
  appdirs,
  datasets,
  diskcache,
  gitpython,
  instructor,
  nest-asyncio,
  networkx,
  numpy,
  openai,
  pillow,
  pydantic,
  rich,
  scikit-network,
  tiktoken,
  tqdm,
  typer,
  # LangChain dependencies
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
    hash = "sha256-jbDU+hpfx4QIfMHlhPcw6WRrDfu9/yHWb4FsD7cO0ag=";
  };

  build-system = [ setuptools setuptools-scm ];

  dependencies = [
    # Core dependencies
    appdirs
    datasets
    diskcache
    gitpython
    instructor
    nest-asyncio
    networkx
    numpy
    openai
    pillow
    pydantic
    rich
    scikit-network
    tiktoken
    tqdm
    typer
    # LangChain dependencies
    langchain
    langchain-core
    langchain-community
    langchain-openai
  ];

  pythonImportsCheck = [ "ragas" ];

  meta = with lib; {
    description = "Evaluation framework for Retrieval Augmented Generation pipelines";
    homepage = "https://github.com/explodinggradients/ragas";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
