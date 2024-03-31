# AcceleratorLattice.jl
High energy accelerator lattice construction and manipulation.
Compatible with Bmad.
This is a long term project currently under development.

## State of the Software
Can construct simple lattices so tracking code development can begin. 
But bookkeeping is incomplete so the lattice is not usable for simulations.

## Installing
1. Clone this Git repo. Typically to \~/.julia/dev/ 
```
  git clone https://github.com/bmad-sim/AcceleratorLattice.jl.git
```
2.
```
import Pkg
Pkg.add(path=".julia/dev/AcceleratorLattice.jl")    # This is relative to the current directory!
                                                    # so make sure you are in the root directory.
using AcceleratorLattice
``` 
