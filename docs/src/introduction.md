(c:introduction)=
# Introduction and Concepts

%---------------------------------------------------------------------------
(s:introduction)=
## Introduction

This chapter is an introduction to the AcceleratorLattice package which is part of the
greater SciBmad ecosystem of toolkits and programs for accelerator simulations. With AcceleratorLattice,
lattices can be constructed and manipulated. Essentially, a `lattice` instance contains
a set of "`branches`" and a branch contains 
an array of lattice `elements` with each element representing an object like a magnet
or a RF cavity. A branch can be used to describe such
things as LINACs, storage rings, injection lines, X-ray beam lines, etc. Different branches in a
lattice can be connected together. For example, an injection line branch can be connected to a storage
ring branch or the lines of two rings can be connected together to form a colliding beam machine. 
This ability to describe the interconnections between branches means that 
a lattice instance can hold all the information about an entire machine complex from beam creation
to dump lines enabling a single lattice to be used as the basis of start-to-end simulations.

The sole purpose of the AcceleratorLattice package is to implement methods for lattice construction.
Other stuff, like tracking and lattice analysis (for example, calculating
closed orbits and Twiss functions), is left to other packages in the SciBmad ecosystem.

%---------------------------------------------------------------------------
(s:doc)=
## Documentation

There are three main sources of documentation of the AcceleratorLattice package. 
One source is this PDF manual which gives in-depth documentationon. 
A second source is the web based introduction and overview guide.
Finally, functions, structs and other objects are documented in the code files themselves. 
Taking advantage of Julia's built-in documentation system, this code-file documentation 
can be accessed via using Julia's REPL.

%---------------------------------------------------------------------------
(s:history)=
## Brief History

AcceleratorLattice has it's origins in the Bmad{footcite:p}`Sagan:Bmad2006` ecosystem of toolkits and programs 
developed over several decades at Cornell University.
While the development of AcceleratorLattice is heavily influenced by the 
experience --- both good and bad --- of the development and use of Bmad as well as experience
with other accelerator simulation programs, the code of the two are
completely separate with Bmad being written in Fortran and AcceleratorLattice being written in Julia.

The Julia language itself is used as the basis for constructing lattices with AcceleratorLattice. 
Other simulation programs
have similarly utilized the underlying programming language for constructing 
lattices{footcite:p}`Appleby:Merlin2020;Iadarola:Xsuite2023`. This is in marked contrast to many accelerator
simulation programs such programs as MAD{footcite:p}`Grote:MAD1989`, 
Elegant{footcite:p}`Borland:Elegant2000`, and Bmad. 
By using Julia for the lattice language, the user will automatically have access to such features 
as plotting, optimization packages, linear algebra packages, etc. 
This gives a massive boost to the versatility and usability of any SciBmad simulation program.
Moreover, maintainability is greatly enhanced due to the reduction in the amount of code that needs
to be developed.

%---------------------------------------------------------------------------------------------------
(s:ack)=
## Acknowledgements

Thanks must go to the people who have contributed to this effort and without
whom SciBmad would only be a shadow of what it is today: 

Etienne Forest (aka Patrice Nishikawa),
Dan Abell,
Scott Berg,
Oleksii Beznosov,
Alexander Coxe,
Laurent Deniau,
Auralee Edelen,
Ryan Foussel,
Juan Pablo Gonzalez-Aguilera,
Georg Hoffstaetter,
Chris Mayes,
Matthew Signorelli,
Hugo Slepicka,

%---------------------------------------------------------------------------
(s:using)=
## Using AcceleratorLattice.jl

AcceleratorLattice is hosted on GitHub. The official repository is at
```{code} yaml
  github.com/bmad-sim/AcceleratorLattice.jl
```
The `README.md` file there has instructions on how to install AcceleratorLattice.

A `using` statement must be given before using AcceleratorLattice in Julia
```{code} yaml
  using AcceleratorLattice
```

%---------------------------------------------------------------------------
(s:manual.con)=
## Manual Conventions

This manual has the following conventions:
%
- **Type fields:**
`Fields` of a type are also referred to as `components` or `parameters`.
A component `c` of a type `S` can be referred to as `S.c`. In the case
of lattice elements, `Ele` (the abstract type that all elements inherit from) is
used represent any of the subtypes such as `Quadrupole`, etc. If the component
is an array, the notation `S.c[]` can be used to emphasize this.
%

%---------------------------------------------------------------------------
(s:element.def)=
## Lattice Elements

The basic building block used to describe an accelerator is the lattice `element`. An
element is generally something physical like a bending magnet or a
quadrupole, or a diffracting crystal. 

Lattice elements can be divided into two classes.
One class are the elements that particles are tracked through. These "tracking" elements are
contained in the "tracking branches" ([](#s:branch.def)) of the lattice. Other elements, 
called "`lord`" elements, are used to
represent relationships between elements. "`Super-lord`" elements ([](#c:super)) are
used when elements overlap spatially. "`Multipass_lord`" elements ([](#c:multipass))
are used when a beam goes through the same elements multiple times like in a recirculating Linac
or when different beam go through the same elements like in the interaction region of a
colliding beam machine.

%---------------------------------------------------------------------------
(s:branch.def)=
## Lattice Branches

The next level up from lattice `elements` are the `branches`.
Each branch holds an array of lattice elements. 
A branch is of type `Branch`. 

There are two types of `branches`: branches whose `Branch.type` parameter is set to
a suitable subtype of `LordBranch` holds Lord elements and 
branches whose `Branch.type` parameter is set to `TrackingBranch` holds an ordered
list of elements that can be tracked through. AcceleratorLattice defines three lord branches named:
```{code} yaml
  "super"       -- Contains super lord elements.
  "multipass"   -- Contains multipass lord elements.
  "girder"      -- Contains Girder elements.
```
Additional lord branches may be added by the user if desired.

A tracking branch can represent a LINAC, X-Ray beam line, storage ring, etc.
For all tracking branches, the first element in the element array
must be of type `BeginningEle` ([](#s:begin.ele)).
Additionally, for all tracking branches, 
the end element must be of type `Marker` ([](#s:mark)).

All tracking branches have a name `Branch.name` inherited from the `BeamLine` that defines
the branch in the lattice file and branches contains an array of elements `Branch.ele[]`.
If the `BeamLine` used to instantiate a tracking branch does not have a name, The default name
is used. The default name is `"Bn"` where `n` is the index of the
branch in the `Lattice.branch` array. For example, `"B2"` would be the default name of 
`lat.branch[2]` (assuming that this is a tracking branch).

%---------------------------------------------------------------------------
(s:lattice.def)=
## Lattices

A `lattice` ([](#s:lattice.def)) is the root structure holding the information about a
"machine". A machine may be as simple as a line of elements (like the elements of a Linac) or
as complicated as an entire accelerator complex with multiple storage rings, Linacs, transfer
lines, etc. All lattices are of type `Lattice`.

Essentially, a `lattice`, has an array `Lattice.branch[]` of `branches` with each branch 
describing part of the machine. 
Branches can be interconnected to form a unified whole.
Tracking branches can be interconnected using `Fork` elements ([](#s:fork)). 
This is used to simulate forking beam lines such as a connections to a transfer line, dump line, or an
X-ray beam line. The `branch` from which other `branches` fork but is not forked to by any
other `branch` is called a `root` branch.

A lattice may contain multiple `root` `branches`. For example, a pair of intersecting storage
rings will generally have two `root` branches, one for each ring.

Branches can be accessed by name using the overloaded index operator for `Lattice`. 
For example, if `lat` is an instance of a lattice, the super lord branch ([](#s:branch.def)),
which has the name `"super"`, can be accessed via:
```{code} yaml
  lat["super"]     # Access by branch name
  lat.branch[2]    # Access by branch index
```
Where it is assumed for this example that the super lord branch has index 2.

Similarly, lattice elements can be accessed by name or by index.
For example, if `lat` is a lattice instance, and `"q1"` is the name of an element or
elements that are in a branch named "B2", the following are equivalent:
```{code} yaml
  elist = lat["q1"]
  elist = find(lat, "q1")
  b2 = lat.branch["B2"]; elist = b2["q1"]
```
`elist` will be a vector of elements since a name may match to multiple elements.

%---------------------------------------------------------------------------
(s:conventions)=
## AcceleratorLattice Conventions

AcceleratorLattice has the following conventions:
%
- **Evaluation is at upstream end:** 
For lattice element parameters that are s-dependent, the evaluation location is the
`upstream` edge of the element ([](#s:ref.construct)). These parameters include the 
element's floor position, the reference energy/momentum, and the s-position.
%

%---------------------------------------------------------------------------
(s:min.lat)=
## Minimal Working Lattice Example

The following is a minimal example of constructing a lattice with a quadrupole, drift, and then
a bend:
```{code} yaml
  using AcceleratorLattice
  @ele begin_ele = BeginningEle(pc_ref = 1e7, species_ref = species("electron"))
  @ele q = Quadrupole(L = 0.6, K2 = 0.3)
  @ele d = Drift(L = 0.4)
  @ele b = Bend(L = 1.2, angle = 0.001)

  a_line = beamline("simple_line", [begin_ele, q, d, b])
  lat = Lattice("simple_lat", [a_line])
```

%---------------------------------------------------------------------------
(s:X)=
## Differences From Bmad

There are many differences between AcceleratorLattice and Bmad. Many of of these will be fairly
obvious. Some differences to be aware of:
- Bmad is generally case insensitive (except for things like file names). AcceleratorLattice, like
the Julia language, is case sensitive.
%
With Bmad, the branch array within a lattice and the element array within a branch is
indexed from zero. With SciBmad, indexing of `Lattice.branch[]` and `branch.ele[]` is 
from one conforming to the Julia standard.
%
- The Bmad names for the coordinate systems ([](#s:coords)) was somewhat different and not
always consistent. The `floor` and `element body` names are the same but `machine`
coordinates are called the `laboratory` in Bmad.
%
- Evaluation was at the downstream end ([](#s:conventions)) in Bmad not the upstream end.
%
- With Bmad a value for any aperture limits of zero means the limit does not exist.
with AcceleratorLattice a value of `NaN` means the aperture does not exist. Additionally, with
Bmad a positive value for `x1_limit` or `y1_limit` meant that the aperture was
on the negative side of the `x-axis` or `y-axis` respectively. With AcceleratorLattice, a positive
value for `x_limit[1]` or `y_limit[1]` means the aperture is on the positive side of 
of the `x-axis` or `y-axis` respectively. This makes the notation consistent across 
the different ways to specify apertures (compare with `Mask` element syntax.).
%
- AcceleratorLattice defines the reference point for misalignment of a Bend element as the center 
of the chord between the entrance and exit end points. 
With Bmad, the reference point is at the center of the reference trajectory arc between the entrance
and the exit. An additional difference is that the Bmad `roll` misalignment is called `tilt`
under AcceleratorLattice.
%
- Bmad does not allow redefinition of named variables nor elements. AcceleratorLattice allows this.
%
- With Bmad, the beginning and end elements are implicitly inserted into a branch line.
With AcceleratorLattice, only an end element will be implicitly inserted if the end of the beamline is
not a marker. 
Also with Bmad the beginning element is always named `Beginning` while with AcceleratorLattice there
is no restriction on the name. 
%
- Restrictions on the order of statements used to create a lattice are different. 
For example, in Bmad, a statement defining a lattice element can be placed anywhere
except if there is an `expand_lattice` statement and the element is not being used
with superposition in which case the element definition must be before the `expand_lattice`
statement. With AcceleratorLattice, element definitions must come before the element is used in a line.
%
- With Bmad superposition of two non-drift elements, if there existed the appropriate
combined type, will result in a super-slave of the appropriate combined type. For example,
a `solenoid` superimposed over a `quadrupole` would give a `sol_quad` super slave with
`solenoid` and `quadrupole` super lords. The problem here is that calculation of the
super slave parameters may not be possible. For example if the super lord
elements are misaligned, in general it is not possible to compute a corresponding super slave
misalignment. To avoid this, AcceleratorLattice creates a `UnionEle` super slave element
(which in Bmad is known as a "jumbo" super slave). It is up to the tracking routines to
figure out how to track though a `UnionEle`
%
- In `Bmad` there are two types of bends called `sbend` and `rbend`. 
This organization was inherited from `MAD`. While both `sbends` and `rbends`
represent the same physical type of bend, the two have different ways to specify the bend parameters. 
This can be confusing since `rbends` and `sbends` use the same names for different parameters.
For example, the length `l` for an `sbend` is the arc length but for an `rbend` it is the
chord length. To avoid confusion, AcceleratorLattice combines the two into a single `Bend` type with
distinct parameter names. For example, `L` is the arc length and `L_chord` is the chord length.



```{footbibliography}
```
