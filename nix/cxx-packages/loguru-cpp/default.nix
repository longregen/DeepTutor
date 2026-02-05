{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation {
  pname = "loguru-cpp";
  version = "unstable-2023-03-04";

  src = fetchFromGitHub {
    owner = "emilk";
    repo = "loguru";
    rev = "4adaa185883e3c04da25913579c451d3c32cfac1";
    hash = "sha256-NpMKyjCC06bC5B3xqgDr2NgA9RsPEeiWr9GbHrHHzZ8=";
  };

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-DLOGURU_WITH_STREAMS=ON"
    "-DLOGURU_BUILD_TESTS=OFF"
    "-DLOGURU_BUILD_EXAMPLES=OFF"
  ];

  meta = with lib; {
    description = "A lightweight C++ logging library";
    homepage = "https://github.com/emilk/loguru";
    license = licenses.publicDomain;
    maintainers = [];
  };
}
