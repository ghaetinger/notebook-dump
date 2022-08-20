{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [ julia_17-bin ];
  shellHook = ''
    figlet -f slant "Welcome to my Dump!"
  '';
}
