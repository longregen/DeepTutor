{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  cmake,
  ninja,
  numpy,
  pybind11,
  nanobind,
  glfw,
  pkg-config,
  libGL,
  libGLU,
  xorg,
  scikit-build-core,
  git,
  freetype,
  opencv4,
  cudaPackages,
  # Python runtime dependencies
  glfw-py ? null, # Python glfw bindings (passed as glfw from python packages)
  pyopengl,
  pillow,
  pydantic,
  munch,
}:

buildPythonPackage rec {
  pname = "imgui-bundle";
  version = "1.6.2";
  pyproject = true;

  src = fetchPypi {
    pname = "imgui_bundle";
    inherit version;
    hash = "sha256-F7IBmg1Ou2a8KbI0wIbqWjzMx8DFQFF/5WnYQ3IxaXA=";
  };

  build-system = [
    setuptools
    cmake
    ninja
    pybind11
    nanobind
    scikit-build-core
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    git
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    glfw
    libGL
    libGLU
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    freetype
    opencv4
  ];

  dependencies = [
    numpy
    pyopengl
    pillow
    pydantic
    munch
  ] ++ lib.optionals (glfw-py != null) [ glfw-py ];

  # Fix OpenCV 4.12.0 API incompatibility with imgui-bundle 1.6.2
  # The contains() method now requires explicit cv::Point construction
  postPatch = ''
    substituteInPlace external/immvision/immvision/src/immvision/internal/drawing/image_drawing.cpp \
      --replace-fail '.contains({(int)position.x, (int)position.y})' \
        '.contains(cv::Point((int)position.x, (int)position.y))'
  '';

  dontUseCmakeConfigure = true;

  # Set environment variables to help find system libraries
  env = {
    FREETYPE_DIR = "${freetype.dev}";
    CMAKE_PREFIX_PATH = lib.makeSearchPath "lib/cmake" [ freetype.dev opencv4 ];
    CUDAToolkit_ROOT = "${cudaPackages.cudatoolkit}";
  };

  # Pass CMake flags via pypaBuildFlags for scikit-build-core
  # Key flags to ensure hermetic build:
  # - IMGUI_BUNDLE_PYTHON_USE_SYSTEM_LIBS=ON: Use system libraries instead of fetching
  # - HELLOIMGUI_USE_FREETYPE=ON: Enable freetype support
  # - HELLOIMGUI_USE_FREETYPE_PLUTOSVG=OFF: Disable SVG support (would require fetching plutovg/plutosvg)
  # - HELLOIMGUI_DOWNLOAD_FREETYPE_IF_NEEDED=OFF: Don't try to download freetype
  # - HELLOIMGUI_FREETYPE_STATIC=OFF: Don't force static freetype build (which triggers download)
  # - IMMVISION_FETCH_OPENCV=OFF: Don't fetch OpenCV, use system version
  pypaBuildFlags = [
    "-Ccmake.args=-DIMGUI_BUNDLE_PYTHON_USE_SYSTEM_LIBS=ON"
    "-Ccmake.args=-DHELLOIMGUI_USE_FREETYPE=ON"
    "-Ccmake.args=-DHELLOIMGUI_USE_FREETYPE_PLUTOSVG=OFF"
    "-Ccmake.args=-DHELLOIMGUI_DOWNLOAD_FREETYPE_IF_NEEDED=OFF"
    "-Ccmake.args=-DHELLOIMGUI_FREETYPE_STATIC=OFF"
    "-Ccmake.args=-DIMMVISION_FETCH_OPENCV=OFF"
    "-Ccmake.args=-DCMAKE_PREFIX_PATH=${lib.makeSearchPath "lib/cmake" [ freetype.dev opencv4 ]}"
  ];

  meta = with lib; {
    description = "Dear ImGui Bundle - Python bindings for Dear ImGui";
    homepage = "https://github.com/pthom/imgui_bundle";
    license = licenses.mit;
    maintainers = [ ];
  };
}
