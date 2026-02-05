{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pip,
  ascii-colors,
}:
buildPythonPackage rec {
  pname = "pipmaster";
  version = "0.5.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-WcrFYyzqJis2uAWAlTRekFUs0seueO+RuG3e6FrNBkg=";
  };

  build-system = [setuptools];

  dependencies = [
    pip
    setuptools
    ascii-colors
  ];

  postPatch = ''
    touch requirements.txt
  '';

  # Patch pipmaster to be a no-op in Nix environment
  # This prevents lightrag from trying to pip install packages at runtime
  # All packages must be pre-installed via Nix instead
  postInstall = ''
    cat > $out/lib/python*/site-packages/pipmaster/package_manager.py << 'EOF'
"""
Pipmaster stub for Nix environments.
All packages must be pre-installed via Nix - runtime pip install is disabled.
"""

class PackageManager:
    def __init__(self, *args, **kwargs):
        pass

    def is_installed(self, package_name, *args, **kwargs):
        return True

    def install(self, package_name, *args, **kwargs):
        return True

    def install_edit(self, package_name, *args, **kwargs):
        return True

    def install_version(self, package_name, version, *args, **kwargs):
        return True

    def install_or_update(self, package_name, *args, **kwargs):
        return True

    def install_multiple(self, packages, *args, **kwargs):
        return True

    def install_or_update_multiple(self, packages, *args, **kwargs):
        return True

    def install_requirements(self, requirements_file, *args, **kwargs):
        return True

    def uninstall(self, package_name, *args, **kwargs):
        return True

    def uninstall_multiple(self, packages, *args, **kwargs):
        return True

    def get_installed_version(self, package_name, *args, **kwargs):
        return None

    def get_package_info(self, package_name, *args, **kwargs):
        return {}

# Module-level convenience functions
_pm = PackageManager()

def is_installed(package_name, *args, **kwargs):
    return True

def install(package_name, *args, **kwargs):
    return True

def install_edit(package_name, *args, **kwargs):
    return True

def install_version(package_name, version, *args, **kwargs):
    return True

def install_or_update(package_name, *args, **kwargs):
    return True

def install_multiple(packages, *args, **kwargs):
    return True

def install_or_update_multiple(packages, *args, **kwargs):
    return True

def install_requirements(requirements_file, *args, **kwargs):
    return True

def uninstall(package_name, *args, **kwargs):
    return True

def uninstall_multiple(packages, *args, **kwargs):
    return True

def get_installed_version(package_name, *args, **kwargs):
    return None

def get_package_info(package_name, *args, **kwargs):
    return {}
EOF
  '';

  pythonImportsCheck = ["pipmaster"];

  meta = with lib; {
    description = "A Python package manager helper";
    homepage = "https://github.com/ParisNeo/pipmaster";
    license = licenses.asl20;
    maintainers = [];
  };
}
