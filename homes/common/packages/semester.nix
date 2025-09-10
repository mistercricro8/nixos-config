{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jflap
    postman
    octave
  ];
}
