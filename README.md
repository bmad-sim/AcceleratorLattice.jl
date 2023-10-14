# AcceleratorLattice.jl
High energy accelerator lattice construction and manipulation.
Compatible with Bmad.
This is a long term project currently under development.

## State of the Software
2023/10/9: Can construct simple lattices but bookkeeping is incomplete so the lattice is not usable for simulations.

## Installing
1. Clone this Git repo. Typically to \~/.julia/dev/ 
```
  git clone https://github.com/bmad-sim/AcceleratorLattice.jl.git ~/.julia/dev/AcceleratorLattice.jl
```
2. In Julia do:
```
julia> import Pkg
julia> Pkg.activate(".julia/dev/AcceleratorLattice.jl")    # This is relative to the current directory!
                                                           # so make sure you are in the root directory.
julia> Pkg.instantiate()
julia> using AcceleratorLattice
```
