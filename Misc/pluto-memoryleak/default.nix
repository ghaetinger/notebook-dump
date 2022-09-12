{ pkgs ? import <nixpkgs> { }}:

pkgs.mkShell {
    buildInputs = with pkgs; [ nodejs deno figlet ];
    shellHook = ''
    figlet "Testing Console.log + React memory leak"
    '';
}
