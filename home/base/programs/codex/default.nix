{ unstable, ... }:

{
  programs.codex = {
    enable = true;
    package = unstable.codex;
  };
}
