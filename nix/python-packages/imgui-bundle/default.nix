{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  cmake,
  numpy,
  pybind11,
  glfw,
  pkg-config,
  libGL,
  libGLU,
}:

buildPythonPackage rec {
  pname = "imgui-bundle";
  version = "1.6.2";
  pyproject = true;

  src = fetchPypi {
    pname = "imgui_bundle";
    inherit version;
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  build-system = [
    setuptools
    cmake
    pybind11
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    glfw
    libGL
    libGLU
  ];

  dependencies = [ numpy ];

  dontUseCmakeConfigure = true;

  doCheck = false;

  pythonImportsCheck = [ "imgui_bundle" ];

  meta = with lib; {
    description = "Dear ImGui Bundle - Python bindings for Dear ImGui";
    homepage = "https://github.com/pthom/imgui_bundle";
    license = licenses.mit;
    maintainers = [ ];
  };
}
