# Remove duplicate CLI binary to avoid conflict with llama-cloud-services
{ llama-parse }:

llama-parse.overridePythonAttrs (old: {
  postFixup = (old.postFixup or "") + ''
    rm -rf $out/bin
  '';
})
