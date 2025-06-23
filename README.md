# AcceleratorLattice.jl
High energy accelerator lattice construction and manipulation.
Compatible with Bmad.
This is a long term project currently under development.

## State of the Software
Can construct simple lattices so the tracking code being developed can use `AcceleratorLattice`. 

2025/6: Work on AcceleratorLattice is paused to focus on BeamTracking.jl and Beamlines.jl development. The plan is that when the lattice 
bookkeeping has been sorted out, Beamlines will be merged with AcceleratorLattice. Projected is that this will start happening the end of 2025.

## Installing

To use this package, in the Julia REPL run:

```julia
import Pkg; Pkg.add(url="https://github.com/bmad-sim/AcceleratorLattice.jl")
using AcceleratorLattice
``` 
## Simple Lattice Example

```
@eles begin
  begin0 = BeginningEle(pc_ref = 1e7, species_ref = Species("electron"))
  qf = Quadrupole(L = 0.6, Kn1 = 0.34)
  d = Drift(L = 0.4)
  b1 = Bend(L = 1.2, g = 0.034);
end

aline= BeamLine([begin0, qf, d, b1])
lat = Lattice([aline])
```
The result is:
```
julia> lat
Lattice: "lat"
Branch 1: "b1", geometry => OPEN                      L           s      s_downstream
      1  "begin0"             BeginningEle        0.000000    0.000000 ->    0.000000
      2  "qf"                 Quadrupole          0.600000    0.000000 ->    0.600000
      3  "d"                  Drift               0.400000    0.600000 ->    1.000000
      4  "b1"                 Bend                1.200000    1.000000 ->    2.200000
      5  "end_ele"            Marker              0.000000    2.200000 ->    2.200000
Branch 2: "super_lord"
     --- No Elements ---
Branch 3: "multipass_lord"
     --- No Elements ---
```
An individual element looks like:
```julia> lat.branch[1].ele[2]
Ele: "qf" (b1>>2)   Quadrupole
  branch             Branch 1: "b1" 
  ix_ele             2 
  BodyShiftParams:
    offset               [0.0, 0.0, 0.0] m            offset_tot           [0.0, 0.0, 0.0] m
    x_rot                0 rad                        x_rot_tot            0 rad
    y_rot                0 rad                        y_rot_tot            0 rad
    tilt                 0 rad                        tilt_tot             0 rad
  ApertureParams:
    x_limit                      [NaN, NaN] m         y_limit              [NaN, NaN] m
    aperture_at                  BodyLoc.ENTRANCE_END 
    aperture_type        ApertureShape.ELLIPTICAL 
    misalignment_moves_aperture  true 
  BMultipoleParams:
    Order Integrated              Tilt (rad)
        1      false                     0.0                    0.34  Kn1                     0.0  Ks1 (1/m^2)
                                               -0.011341179236737171  Bn1                    -0.0  Bs1 (T/m^1)
  EMultipoleParams: No electric multipoles
  FloorParams:
    r (r_floor)          [0.0, 0.0, 0.0] m
    q (q_floor)          1.0 + 0.0⋅i + 0.0⋅j + 0.0⋅k 
    theta (theta_floor)  0.0 rad
    phi (phi_floor)      0.0 rad                      psi (psi_floor)      0.0 rad
  LengthParams:
    L                    0.6 m                        orientation          1 
    s                    0.0 m                        s_downstream         0.6 m
... etc...
```

# AcceleratorLattice manual

[AcceleratorLattice manual](https://github.com/bmad-sim/AcceleratorLattice.jl/blob/main/manual/AcceleratorLattice.pdf)
