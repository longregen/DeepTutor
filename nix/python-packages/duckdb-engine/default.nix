# Override nixpkgs duckdb-engine to disable test requiring pytest_snapshot
{ duckdb-engine
}:

duckdb-engine.overridePythonAttrs (old: {
  disabledTestPaths = (old.disabledTestPaths or []) ++ [
    # Requires pytest_snapshot which is not available
    "duckdb_engine/tests/test_datatypes.py"
  ];
})
