# Override nixpkgs docling to use custom docling-parse
{ docling
, docling-parse
}:

docling.overridePythonAttrs (old: {
  dependencies =
    builtins.map
    (dep:
      if dep.pname or "" == "docling-parse"
      then docling-parse
      else dep)
    (old.dependencies or []);
})
