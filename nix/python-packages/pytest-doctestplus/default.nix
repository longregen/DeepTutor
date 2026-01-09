# Override nixpkgs pytest-doctestplus with fix for numpy ufunc inspection
{ pytest-doctestplus
}:

pytest-doctestplus.overridePythonAttrs (old: {
  patches = (old.patches or []) ++ [
    # Backport fix for CPython #117692: numpy ufuncs don't have __code__
    # attribute which Python's inspect.unwrap() tries to access.
    # Fixed in Python 3.12.4+ but not backported to 3.11.
    ./patches/fix-ufunc-code-attr.patch
  ];

  disabledTests = (old.disabledTests or []) ++ [
    # Fails on Python 3.11 due to numpy ufunc __code__ attribute issue
    "test_ufunc"
  ];
})
