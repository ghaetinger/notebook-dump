# How to run this

To run this, please download the latest `julia` binary, run it on the terminal and do the following:

```julia-repl
julia> using Pkg;
julia> Pkg.add("Pluto");
julia> using Pluto;
julia> Pluto.run();
```

Once you've been redirected to the locally hosted page on your browser, find and open the `assignment.jl` file. There, you'll find all the code and an interactive example all the way to the bottom.

Disclaimer: In the last few versions of Pluto, I've been getting an `EOF` error when doing too much computation. If that happens, just reload `Pluto`. If it persists, you can go into the `julia` REPL and type `include("./assignment1.jl")` and you'll have access to all the functions given you also `Pkg.add` all the dependencies listed on the `.jl` file under the `Environment Setup > Libraries` section.
