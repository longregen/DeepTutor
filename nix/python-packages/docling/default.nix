# Override nixpkgs docling to use custom docling-parse and relax deps
{ docling
, docling-parse
}:

docling.overridePythonAttrs (old: {
  pythonRelaxDeps = [
    "typer"
    "pypdfium2"
    "lxml"
    "pillow"
  ];
  dependencies =
    builtins.map
    (dep:
      if dep.pname or "" == "docling-parse"
      then docling-parse
      else dep)
    (old.dependencies or []);
})
