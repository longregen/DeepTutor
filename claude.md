# Claude Code Guidelines for DeepTutor

## Build machin nouances\

When building nix packages, please use `-j 1 --cores 4` because the machine fails to build with more cores in parallel.

## Nix Python Packaging Strategies

### 1. Examine source files before patching
Use curl + tar to inspect pyproject.toml, setup.py, or other files to understand exact formats before writing patches:
```bash
curl -sL "https://files.pythonhosted.org/packages/source/s/package_name/package_name-1.0.0.tar.gz" | tar -xzO "package_name-1.0.0/pyproject.toml"
```

### 2. Disable specific tests instead of doCheck=false
Keep tests meaningful by disabling only failing tests:
```nix
# Disable specific test functions
disabledTests = (old.disabledTests or []) ++ ["test_specific_failing_test"];

# Disable entire test files
disabledTestPaths = (old.disabledTestPaths or []) ++ ["tests/test_problematic.py"];
```

### 3. Organize package overrides in nix/python-packages/
Each overridden package gets its own directory for consistency:
```
nix/python-packages/
├── package-name/
│   ├── default.nix
│   └── patches/
│       └── fix-something.patch
```

Import in flake.nix overlay:
```nix
package-name = import ./nix/python-packages/package-name {
  inherit (pyPrev) package-name;
};
```

### 4. Backport upstream fixes as patches
Search for fixed issues upstream, fetch the patch, and apply it:
```nix
patches = (old.patches or []) ++ [
  # Backport fix for issue #123
  ./patches/fix-issue-123.patch
];
```

### 5. Remove strict version constraints with postPatch
When packages have overly strict version pins:
```nix
postPatch = ''
  substituteInPlace pyproject.toml \
    --replace-quiet '"dependency <= 1.0.0",' '"dependency",'
'';
```

### 6. Monkey-patch stdlib issues in package code
When Python stdlib has bugs not backported to your version, patch the package to work around it:
```python
# In a patch file, add at module level:
_original_method = module.Class.method
def _patched_method(self, arg):
    try:
        return _original_method(self, arg)
    except AttributeError:
        return None
module.Class.method = _patched_method
```

### 7. Expose packages individually for testing
Add packages to flake outputs for individual builds:
```nix
packages = {
  inherit package-a package-b package-c;
  # Allows: nix build .#package-a
};
```
