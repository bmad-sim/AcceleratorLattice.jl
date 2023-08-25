# AcceleratorLattice.jl
High energy accelerator lattice construction and manipulation.
Compatible with Bmad.
This is a long term project currently under development.

## Installing
1. Clone this Git repo. Typically to \~/.julia/dev/ 
```
  git clone https://github.com/bmad-sim/AcceleratorLattice.jl.git ~/.julia/dev/AcceleratorLattice.jl
```
1. In Julia do:
```
julia> import Pkg
julia> Pkg.activate(".julia/dev/AcceleratorLattice.jl")    # This is relative to the current directory!
                                                           # so make sure you are in the root directory.
julia> Pkg.instantiate()
julia> using AcceleratorLattice
```
