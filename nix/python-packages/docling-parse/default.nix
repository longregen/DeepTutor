{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonRelaxDepsHook,
  system-cmake,
  pkg-config,
  setuptools,
  cmake,
  pybind11,
  zlib,
  nlohmann_json,
  utf8cpp,
  libjpeg,
  qpdf,
  loguru-cpp,
  tabulate,
  pillow,
  pydantic,
  docling-core,
  pytestCheckHook,
}: let
  # Use qpdf 11.9.1 instead of 12.x for PointerHolder API compatibility
  # docling-parse v1 parser uses PointerHolder which was removed in qpdf 12.0.0
  qpdf_11 = qpdf.overrideAttrs (old: {
    version = "11.9.1";
    src = fetchFromGitHub {
      owner = "qpdf";
      repo = "qpdf";
      rev = "v11.9.1";
      hash = "sha256-DhrOKjUPgNo61db8av0OTfM8mCNebQocQWtTWdt002s=";
    };
  });
in
  buildPythonPackage rec {
    pname = "docling-parse";
    version = "4.7.2";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "docling-project";
      repo = "docling-parse";
      tag = "v${version}";
      hash = "sha256-XzAcGhtFQ8AY05FU860mGAFxmVr7336pkHToGfA16Fc=";
    };

    patches = [
      ./patches/bool-conversion-fix.patch
    ];

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail \
          '"cmake>=3.27.0,<4.0.0"' \
          '"cmake>=3.27.0"'

      # Create externals directory structure for CMake
      mkdir -p externals/include externals/lib externals/bin externals/resources

      # Force C++17 standard in CMakeLists.txt
      sed -i 's/CMAKE_CXX_STANDARD[[:space:]]*20/CMAKE_CXX_STANDARD 17/g' CMakeLists.txt
      sed -i 's/CXX_STANDARD 20/CXX_STANDARD 17/g' CMakeLists.txt
      sed -i 's/cxx_std_20/cxx_std_17/g' CMakeLists.txt

      # Remove cxxopts from dependencies - it's only used for CLI apps, not the Python bindings
      sed -i 's/include(cmake\/extlib_cxxopts.cmake)/# cxxopts removed - not needed for Python bindings/' CMakeLists.txt
      sed -i 's/set(DEPENDENCIES qpdf jpeg utf8 json loguru cxxopts)/set(DEPENDENCIES qpdf jpeg utf8 json loguru)/' CMakeLists.txt

      # Comment out CLI executables and static libraries that use cxxopts
      # These compile app/parse_v*.cpp which include cxxopts directly
      # We only need the pybind11 module (pdf_parsers)
      sed -i '/add_executable(parse_v1.exe/,/target_link_libraries(parse_v1.exe/{s/^/#/}' CMakeLists.txt
      sed -i '/add_executable(parse_v2.exe/,/target_link_libraries(parse_v2.exe/{s/^/#/}' CMakeLists.txt
      sed -i '/add_executable(parse_v2_fonts.exe/,/target_link_libraries(parse_v2_fonts.exe/{s/^/#/}' CMakeLists.txt
      sed -i '/add_library(parse_v1 STATIC/,/target_link_libraries(parse_v1/{s/^/#/}' CMakeLists.txt
      sed -i '/add_library(parse_v2 STATIC/,/target_link_libraries(parse_v2/{s/^/#/}' CMakeLists.txt

      # Update pybind11 module to not depend on parse_v1/parse_v2 static libs
      sed -i 's/add_dependencies(pdf_parsers parse_v1 parse_v2)/#add_dependencies(pdf_parsers parse_v1 parse_v2)/' CMakeLists.txt
      sed -i 's/target_link_libraries(pdf_parsers PRIVATE parse_v1 parse_v2)/target_link_libraries(pdf_parsers PRIVATE ''${DEPENDENCIES} ''${LIB_LINK})/' CMakeLists.txt
    '';

    dontUseCmakeConfigure = true;

    nativeBuildInputs = [
      system-cmake
      pkg-config
      pythonRelaxDepsHook
    ];

    build-system = [
      setuptools
      cmake # Python package, not the system cmake
    ];

    # C++17 for compatibility and utf8cpp include path
    env.NIX_CFLAGS_COMPILE = "-I${lib.getDev utf8cpp}/include/utf8cpp";
    env.NIX_CXXFLAGS_COMPILE = "-std=c++17";

    buildInputs = [
      pybind11
      # cxxopts removed - not needed for Python bindings, only for CLI apps
      libjpeg
      loguru-cpp
      nlohmann_json
      qpdf_11
      utf8cpp
      zlib
    ];

    env.USE_SYSTEM_DEPS = true;

    cmakeFlags = [
      "-DUSE_SYSTEM_DEPS=True"
      "-DCMAKE_CXX_STANDARD=17"
      "-DCMAKE_CXX_STANDARD_REQUIRED=ON"
    ];

    dependencies = [
      tabulate
      pillow
      pydantic
      docling-core
    ];

    pythonRelaxDeps = [
      "pydantic"
      "pillow"
    ];

    # Listed as runtime dependencies but only used in CI to build wheels
    preBuild = ''
      sed -i '/cibuildwheel/d' pyproject.toml
      sed -i '/delocate/d' pyproject.toml
    '';

    pythonImportsCheck = [
      "docling_parse"
    ];

    nativeCheckInputs = [
      pytestCheckHook
    ];

    meta = {
      changelog = "https://github.com/docling-project/docling-parse/blob/${src.tag}/CHANGELOG.md";
      description = "Simple package to extract text with coordinates from programmatic PDFs";
      homepage = "https://github.com/docling-project/docling-parse";
      license = lib.licenses.mit;
      maintainers = [];
    };
  }
