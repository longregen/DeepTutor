{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  tqdm,
  colorlog,
  requests,
}:

buildPythonPackage rec {
  pname = "robust-downloader";
  version = "0.0.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/56/a1/779e9d0ebbdc704411ce30915a1105eb01aeaa9e402d7e446613ff8fb121/robust_downloader-0.0.2-py3-none-any.whl";
    hash = "sha256-j+CL+2TXFP0aBIp99ut7QT605iQwmknbLBb7uApihp0=";
  };

  build-system = [ setuptools ];

  dependencies = [
    tqdm
    colorlog
    requests
  ];

  pythonImportsCheck = [ "robust_downloader" ];

  meta = with lib; {
    description = "A minimal Python downloader with robustness in mind - resumable downloads, retries, and more";
    homepage = "https://github.com/fedebotu/robust-downloader";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
