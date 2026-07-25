{ lib }:

let
  workingDirectory = builtins.getEnv "PWD";
  envPath = "${workingDirectory}/.env";

  unquote =
    value:
    let
      length = builtins.stringLength value;
      isDoubleQuoted = lib.hasPrefix "\"" value && lib.hasSuffix "\"" value;
      isSingleQuoted = lib.hasPrefix "'" value && lib.hasSuffix "'" value;
    in
    if length >= 2 && (isDoubleQuoted || isSingleQuoted) then
      builtins.substring 1 (length - 2) value
    else
      value;

  parseLine =
    rawLine:
    let
      line = lib.removeSuffix "\r" rawLine;
      match = builtins.match "([A-Za-z_][A-Za-z0-9_]*)=(.*)" line;
    in
    if line == "" || lib.hasPrefix "#" line then
      null
    else if match == null then
      throw "Invalid line in ${envPath}: ${line}"
    else
      {
        name = builtins.elemAt match 0;
        value = unquote (builtins.elemAt match 1);
      };
in
if workingDirectory == "" then
  throw "Cannot locate .env. Run the Nix command with --impure from the dotfiles directory."
else if !builtins.pathExists envPath then
  throw "Missing ${envPath}. Copy .env.example to .env and set the required values."
else
  builtins.listToAttrs (
    builtins.filter (entry: entry != null) (
      map parseLine (lib.splitString "\n" (builtins.readFile envPath))
    )
  )
