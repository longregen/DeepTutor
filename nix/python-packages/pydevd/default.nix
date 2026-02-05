# Override nixpkgs pydevd to disable tests that fail in Nix sandbox
# These tests check threading state which is affected by the test runner
{ pydevd
}:

pydevd.overridePythonAttrs (old: {
  disabledTests = (old.disabledTests or []) ++ [
    # These tests fail because pytest imports threading before the test runs,
    # causing "assert 'threading' not in sys.modules" to fail
    "test_tracing_other_threads"
    "test_tracing_basic"
    "test_find_main_thread_id"
  ];
})
