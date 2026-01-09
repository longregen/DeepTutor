# Remove duplicate CLI binary to avoid conflict with llama-index
{ llama-index-cli }:

llama-index-cli.overridePythonAttrs (old: {
  postFixup = (old.postFixup or "") + ''
    rm -rf $out/bin
  '';
})
