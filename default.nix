{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let

mach-nix = import (builtins.fetchGit {                                                                                
  url = "https://github.com/DavHau/mach-nix";                                                                         
  ref = "refs/tags/3.5.0";                                                                                            
}) {};                                                                                                                

python_stuff = mach-nix.mkPython {                                                                                    
  requirements = "rawpy";                                                                                             
}; 

in

mkShell {
  buildInputs = [ python_stuff julia_17-bin ];
}
