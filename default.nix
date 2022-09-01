{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let

mach-nix = import (builtins.fetchGit {
  url = "https://github.com/DavHau/mach-nix";
  ref = "refs/tags/3.5.0";
}) {};                                                                                                                

python_stuff = mach-nix.mkPython {

  requirements = ''
  	scipy
  '';                                                                                             
};

in

mkShell {
  buildInputs = [ julia_17-bin python_stuff ];
  shellHook = ''
    figlet -f slant "Welcome to my Dump!"
    export PYTHON=${python_stuff}/bin/python
    export PYTHONPATH=${python_stuff}/lib/python3.9/site-packages:$PYTHONPATH
  '';
}
