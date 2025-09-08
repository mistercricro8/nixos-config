{ ... }:

{
  isPathDir = path: builtins.pathExists (path + "/.");
}
