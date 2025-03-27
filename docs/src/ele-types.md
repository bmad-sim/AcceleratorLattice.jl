(c:ele.types)=
# Lattice Element Types
%---------------------------------------------------------------------------------------------------

This chapter discusses the various types of elements
available in AcceleratorLattice.
These elements are:
```{csv-table}

:align: center
:header: "Element", "Element"

[ACKicker](#s:ackicker), [Marker](#s:marker)
[BeamBeam](#s:beambeam), [Mask](#s:mask)
[BeginningEle](#s:begin.ele), [Match](#s:match)
[Bend](#s:bend), [Multipole](#s:mult)
[Converter](#s:converter), [NullEle](#s:nullele)
[Collimator](#s:collimator), [Octupole](#s:octupole)
[CrabCavity](#s:crabcavity), [Patch](#s:patch)
[Drift](#s:drift), [Quadrupole](#s:quadrupole)
[EGun](#s:egun), [RFCavity](#s:rfcavity)
[Fiducial](#s:fiducial), [Sextupole](#s:sextupole)
[FloorShift](#s:floorshift), [Solenoid](#s:solenoid)
[Foil](#s:foil), [Taylor](#s:taylor)
[Fork](#s:fork), [ThickMultipole](#s:thickmult)
[Girder](#s:girder), [Undulator](#s:undulator)
[Instrument](#s:instrument), [UnionEle](#s:unionele)
[Kicker](#s:kicker), [Wiggler](#s:wiggler)
[LCavity](#s:lcavity), [](#)
```


%---------------------------------------------------------------------------------------------------
(s:ackicker)=
## ACKicker
An `ac_kicker` element simulates a "slow" time dependent kicker element.

NOTE: This Element is in development and is incomplete.
Missing: Need to document amp_function function to return the kick amplitude.

Element parameter groups associated with this element type are:
- [**BodyShiftParams**](#s:align.g): Element position/orientation shift.
- [**ApertureParams**](#s:aperture.g): Vacuum chamber aperture.
- [**BMultipoleParams**](#s:bmultipole.g): Magnetic multipoles.
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**MasterParams**](#s:master.g): Contains field_master parameter.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.


The calculated field will only obey Maxwell's equations in the limit that the time variation
of the field is "slow":
\begin{equation}
\omega \ll \frac{c}{r}
\end{equation}
where {math}`\omega` is the characteristic frequency of the field variation, {math}`c`
and {math}`r`
ends of the element must be able to "communicate" (which happens at the speed of light) in a time
scale short compared to the time scale of the change in the field.


%---------------------------------------------------------------------------------------------------
(s:beambeam)=
## BeamBeam
A `beambeam` element simulates an interaction with an opposing
("strong") beam traveling in the opposite direction.

NOTE: This Element is in development and is incomplete

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.



%---------------------------------------------------------------------------------------------------
(s:begin.ele)=
## BeginningEle
A `BeginningEle` element must be present as the first element of every tracking branch.
([](#s:branch.def)).

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**InitParticleParams**](#s:init.particle.g): Initial particle position and spin.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**TwissParams**](#s:twiss.g): Initial Twiss and coupling parameters.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.


Example:
```{code} yaml
@ele bg = BeginningEle(species_ref = Species("proton"), pc_ref = 1e11)
```


%---------------------------------------------------------------------------------------------------
(s:bend)=
## Bend
A `Bend` element represents a dipole bend. Bends have a design bend angle and bend radius
which determines the location of downstream elements as documented in [](#s:branch.coords).
The actual bending strength that a particle feels can differ from the design value as detailed
below.

Element parameter groups associated with this element type are:
- [**BodyShiftParams**](#s:align.g): Element position/orientation shift.
- [**ApertureParams**](#s:aperture.g): Vacuum chamber aperture.
- [**BMultipoleParams**](#s:bmultipole.g): Magnetic multipoles.
- [**BendParams**](#s:bend.g): Bend element parameters.
- [**EMultipoleParams**](#s:emultipole.g): Electric multipoles.
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**MasterParams**](#s:master.g): Contains field_master parameter.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.


```{figure} figures/bend.svg
\caption[Bend geometry]{
Bend geometry. Red dots are the entry and exit points that define the origin for the
coordinate systems at the entry end {math}`(s_1, x_1)` and exit ends {math}`(s_2, x_2)`
In the figure, the angle `alpha` is denoted {math}`\alpha`
`rho` is denoted {math}`\rho`
A) Bend geometry with positive bend angle. For the geometry shown,
`g`, `angle`, `rho`, `e1`, `e2`, `e1_rect`, and `e2_rect` are all positive.
B) Bend geometry with negative bend angle. For the geometry shown,
`g`, `angle`, `rho`, `e1`, `e2`, `e1_rect`, and `e2_rect` are all negative.
Note: The figures are drawn for zero `ref_tilt` where the rotation axis is parallel to the
{math}`y`
}
:name: f:bend2
```

The `BendParams` group ([](#s:bend.g)) contains the parameters that define the shape of the bend.

Example:
```{code} yaml
@ele b03w = Bend(l = 0.6, g = 0.017, kn1 = 0.003)
```


%---------------------------------------------------------------------------------------------------
(s:collimator)=
## Collimator
`Collimators` are field free elements that can collimate beam particles.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.

%---------------------------------------------------------------------------------------------------
(s:converter)=
## Converter
`Converter` elements convert from one particle species to another.
For example, converting electrons hitting on a metal target into positrons.

NOTE: This Element is in development and is incomplete.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.

%---------------------------------------------------------------------------------------------------
(s:crabcavity)=
## CrabCavity
A `CrabCavity` is an RF cavity that gives a {math}`z`
This is useful in colliding beam machines, where there is a finite crossing angle at the
interaction point, to rotate the beams near the IP.

NOTE: This Element is in development and is incomplete.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.


%---------------------------------------------------------------------------------------------------
(s:drift)=
## Drift
A `Drift` is a field free element.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.

%---------------------------------------------------------------------------------------------------
(s:egun)=
## EGun
An `EGun` element represents an electron gun and encompasses a region starting from the cathode
were the electrons are generated.

NOTE: This Element is in development and is incomplete.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.

%---------------------------------------------------------------------------------------------------
(s:fiducial)=
## Fiducial
A `Fiducial` element is used to fix the position and orientation of the reference orbit within
the floor coordinate system at the location of the `Fiducial` element. A `Fiducial` element
will affect the floor floor coordinates ([](#s:floor)) of elements both upstream and downstream
of the fiducial element.

NOTE: This Element is in development and is incomplete.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**LordSlaveParams**](#s:lord.slave.g): Element lord and slave status.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.


%---------------------------------------------------------------------------------------------------
(s:floorshift)=
## FloorShift
A `FloorShift` element shifts the reference orbit in the floor coordinate system without
affecting particle tracking. That is, in terms of tracking, a `FloorShift` element is equivalent
to a `Marker` ([](#s:marker)) element.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:foil)=
## Foil
A `Foil` element represents a planar sheet of material which can strip electrons from a particle.
In conjunction, there will be scattering of the particle trajectory as well as an associated energy
loss.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:fork)=
## Fork
```{figure} figures/fork-patch.svg
\caption[Cornell/Brookhaven CBETA ERL/FFAG machine with fork elements.]
{
Section of the 8-pass (4 passes with increasing energy and 4 passes with decreasing energy)
Cornell/Brookhaven CBETA ERL/FFAG machine. Fork elements are used to connect the
injection line to the ring and to connect the ring to a diagnostic line. The geometry of the
switchyard, used to correct the timings of the differing energy beams, is done using Patch elements.
}
:name: f:fork.cbeta
```

A `Fork` element marks a branching point in a lattice branch. Examples include `Fork` from
a ring to an extraction line or an X-ray beam line, or `Fork` from the end of an injection line to
someplace in a ring. An example is shown in {numref}`f:fork.cbeta`.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**TrackingParams**](#s:tracking.g): Default tracking settings.
- [**ForkParams**](#s:fork.g): Fork parameters.
- [**ReferenceParams**](#s:reference.g): Reference energy and species.
- [**DownstreamReferenceParams**](#s:dreference.g): Reference energy and species at downstream end.

The `branch` containing a `Fork` element is called the
"`base` `branch`". The `branch` that the `Fork` element points to is called the
"`forked-to` `branch`". The to_ele...

Fork elements may be put in a lattice by including them in beamlines before a lattice
is instantiated. After a lattice has been instantiated, Fork elements can be inserted
by using the `superimpose!` or `insert!` functions.

The components of this group are:
```{code} yaml
to_line::Union{BeamLine,Nothing}  - Beam line to fork to. Default: nothing.
to_ele::Union{String,Ele,Nothing} - Element forked to. Default: nothing.
direction::Int                    - Longitudinal Direction of injected beam.
```

If `to_line` is set to a `BeamLine` -> New branch
Otherwise the fork is to an existing lattice element.




If a fork creates a new branch, and if the The reference energy or species type for the forked-to branch is the particle
particle associated with a branch can be set by setting the `particle` attribute of the `Fork`
element.


\index{patch}
Forked-to branches can themselves have `Fork` elements. A branch always starts out tangential to the
line it is branching from.  A `patch` element ([](#s:patch)) can be used to reorient the
reference orbit as needed. Example:
```{code} yaml
@ele x_patch = Patch,(offset[1] = 0.01)
@ele pb = Fork(to_line = x_line)
@ele bgn = BeginningEle(p0c = 1e3, species_ref = Species("photon")
! Photon reference momentum
from_line = BeamLine([... a, pb, b, ...])       ! Defines base branch
x_line = BeamLine([bgn, x_patch, x1, x2, ...])  ! Defines forked-to branch
```
In this example, a photon generated at the fork element `pb` with {math}`x = 0`
`from_line` reference orbit through `pb` will, when transferred to the `x_line`, and
propagated through `x_patch`, have an initial value for {math}`x` of {math}`-0.01`

Forking elements have zero length and, like `Marker` elements, the position of a particle tracked
through a `Fork` element does not change.

Forking elements do not have orientational attributes like `x_pitch` and `tilt`
([](#s:offset)). If the orientation of the forked-to branch needs to be modified, this can be
accomplished using a `patch` element at the beginning of the line.

\index{is_on}
The `is_on` attribute, while provided for use by a program, is ignored by Bmad proper.

If the reference orbit needs to be shifted when `Fork` from one ring to another ring, a patch can
be placed in a separate "transfer" line to isolate it from the branches defining the
rings. Example:
```{code} yaml
ring1: line = (... A, F1, B, ...)     ! First ring
x_line: line = (X_F1, X_PATCH, X_F2)  ! "Transfer" line
ring2: line = (... C, F2, D, ...)     ! Second ring
use, ring1

f1: fork, to_line = x_line
f2: fork, to_line = x_line, direction = -1
x_patch: patch, x_offset = ...
x_f1: fork, to_line = ring1, to_ele = f1, direction = -1
x_f2: fork, to_line = ring2, to_ele = f2
```
Here the `fork` `F1` in `ring1` forks to `x_line` which
in turn forks to `ring2`.

The above example also illustrates how to connect machines for particles going in the reverse
direction. In this case, rather than using a single `fork` element to connect lines, pairs of
`fork` elements are used. `Ring2` has a `fork` element `f2` that points back through
`x_line` and then to `ring1` via the `x_f1` fork. Notice that both `f2` and `x_f2`
have their `direction` attribute set to -1 to indicate that the fork is appropriate for particles
propagating in the -{math}`s`
will, by default, connect to the downstream end of the `x_line`. The default setting of
`direction` is 1.

It is important to note that the setting of `direction` does not change the placement of elements
in the forked line. That is, the global position ([](#s:global)) of any element is unaffected by
the setting of `direction`. To shift the global position of a forked line, `patch`
elements must be used. In fact, the `direction` parameter is merely an indicator to a program on
how to treat particle propagation. The `direction` parameter is not used in any calculation done
by Bmad.

\index{beginning_ele}\index{fiducial}\index{fork}\index{photon_fork}
\index{marker}\index{to_ele}
The `to_ele` attribute for a `Fork` element is used to designate the element of the forked-to
branch that the `Fork` element connects to. To keep things conceptually simple, the `to_ele`
must be a "marker-like" element which has zero length and unit transfer matrix. Possible
`to_ele` types are:
```{code} yaml
beginning_ele
fiducial
fork and photon_fork
marker
```
When the `to_ele` is not specified, the default is to connect to the beginning of the forked-to
branch if `direction` is 1 and to connect to the end of the downstream branch if `direction` is
-1. In this case, there is never a problem connecting to the beginning of the forked-to branch since
all branches have a `beginning_ele` element at the beginning. When connecting to the end of the
forked-to branch the last element in the forked-to branch must be a marker-like element. Note that, by
default, a marker element is placed at the end of all branches ([](#s:branch.construct))

The default reference particle type of a branch line will be a `photon` is using a
`photon_fork` or will be the same type of particle as the base branch if a `fork` element is
used. If the reference particle of a branch line is different from the reference particle in the
base branch, the reference energy (or reference momentum) of a forked-to branch line needs to be set
using line parameter statements ([](#s:beginning)). If the reference particle of a branch line is
the same as the reference particle in the base branch, the reference energy will default to the
reference energy of the base branch if the reference energy is not set for the branch.

Example showing an injection line branching to a ring which, in turn, branches to two x-ray lines:
```{code} yaml
inj: line = (..., br_ele, ...)            ! Define the injection line
use, inj                                  ! Injection line is the root
br_ele: fork, to_line = ring              ! Fork element to ring
ring: line = (..., x_br, ..., x_br, ...)  ! Define the ring
ring[E_tot] = 1.7e9                       ! Ring ref energy.
x_br: photon_fork, to_line = x_line       ! Fork element to x-ray line
x_line: line = (...)                      ! Define the x-ray line
x_line[E_tot] = 1e3
```

The `new_branch` attribute is, by default, `True` which means that the lattice branch created
out of the `to_line` line is distinct from other lattice branches of the same name. Thus, in the
above example, the two lattice branches made from the `x_line` will be distinct. If
`new_branch` is set to `False`, a new lattice branch will not be created if a lattice branch
created from the same line already exists. This is useful, for example, when a chicane line branches
off from the main line and then branches back to it.

When a lattice is expanded ([](#s:expand)), the branches defined by the `use` statement
([](#s:use)) are searched for fork elements that branch to new forked-to branches. If found, the
appropriate branches are instantiated and the process repeated until there are no more branches to
be instantiated. This process does {\em not} go in reverse. That is, the lines defined in a lattice
file are not searched for fork elements that have forked-to instantiated branches. For example, if, in
the above example, the use statement was:
```{code} yaml
use, x_line
```
then only the `x_line` would be instantiated and the lines `inj` and `ring` would be
ignored.

If the forked-to branch and base branch both have the same reference particle, and if the element
forked into is the beginning element, the reference energy and momentum of the forked-to branch will be
set to the reference energy and momentum at the fork element. In this case, neither the reference
energy nor reference momentum of the forked-to branch should be set. If it is desired to have the
reference energy/momentum of the forked-to branch different from what is inherited from the fork
element, a patch element ([](#s:patch)) can be used at the beginning of the forked-to branch. In all
other cases, where either the two branches have different reference particles or the fork connects
to something other than the beginning element, there is no energy/momentum inheritance and either
the reference energy or reference momentum of the forked-to branch must be set.

How to analyze a lattice with multiple branches can be somewhat complex and will vary from program
to program. For example, some programs will simply ignore everything except the root branch. Hopefully
any program documentation will clarify the matter.

%---------------------------------------------------------------------------------------------------
(s:girder)=
## Girder
A `Girder` is a support structure that orients the elements that are attached to it in space. A
girder can be used to simulate any rigid support structure and there are no restrictions on how the
lattice elements that are supported are oriented with respect to one another.  Thus, for example,
optical tables can be simulated.

```{figure} figures/girder.svg
\caption[Girder example.] {
Girder supporting three elements labeled `A`, `B`, and `C`.  {math}`\cal O_A`
frame at the upstream end of element `A` ([](#s:ref.construct)), {math}`\cal O_C`
frame at the downstream end of element `C`, and {math}`\cal O_G`
frame of the girder if the `origin_ele` parameter is not set. {math}`{\bf r}_{CA}`
{math}`\cal O_A` to {math}`\cal O_C`. The length `l` of the girder is set to be the difference in {math}`s`
points {math}`\cal O_C` and {math}`\cal O_A`
}
:name: f:girder
```

A `girder` is a support structure that orients the elements that are attached to it in space. A
girder can be used to simulate any rigid support structure and there are no restrictions on how the
lattice elements that are supported are oriented with respect to one another.  Thus, for example,
optical tables can be simulated.

Element parameter groups associated with this element type are:
- [**FloorParams**](#s:orientation.g): Floor floor position and orientation.
- [**LengthParams**](#s:length.g): Length and s-position parameters.
- [**DescriptionParams**](#s:descrip.g): Element descriptive strings.
- [**BodyShiftParams**](#s:alignment.g): Alignment with respect to the reference.

A simple example of a girder is shown in {numref}`f:girder`. Here a girder supports three
elements labeled `A`, `B`, and `C` where `B` is a bend so the geometry is
nonlinear. Such a girder may specified in the lattice file like:
```{code} yaml
lat = Lattice(...)        # Create lattice
create_external_ele(lat)  # Optional: Create external elements
@ele g1 = Girder(supported = [A, B, C], ...)
create_girder!(g1)
```
The `create_girder` command must appear after the lattice has been constructed.
The list of `supported` elements must contain only elements that are in a single
lattice. Be careful here since lattice creation involves creating copies of the elments
in the `BeamLines` that define the lattice. Use of the function `create_external_ele`
may be useful here. The `find` function may also be used to search for the appropriate
elements in the lattice.

The list of supported elements does not have to be in any order and may contain elements from
multiple branches. A `Girder` may not support slave elements.
If a super slave or multipass slave element is in the list, the slave will
be removed and the corresponding lords of the slave will be substituted into the list.

A lattice element may have at most one `Girder` supporting it. However, a `Girder` can be
supported by another `Girder` which in turn can be supported by a third `Girder`, etc. Girders
that support other Girders must be defined in the lattice file after the supported girders are
defined.

If all the supported elements of a `Girder` are contained within a single lattice branch
(lord elements are considered to be in the branch(s) that their slaves are in), The length `L`
of the `Girder` is calculated by the difference in {math}`s`
supported element with minimal {math}`s`
the maximal {math}`s`
set to `NaN`. The girder length is not used in any calculations.

The reference frame from which a `Girder`'s orientation is measured is set by the
`origin_ele` and `origin_ele_ref_point` parameters ([](#s:origin.ele.g)).
Orientation shifts are controlled by the `BodyShiftParams` ([](#s:align.g)).

When a girder is shifted in space, the elements
it supports are also shifted.  In this case, the orientation
attributes give the orientation of
the element with respect to the `girder`. The orientation with
respect to the local reference coordinates is given by
`x_offset_tot`, etc, which are computed from the orientation attributes
of the element and the `girder`. An example will make this clear:
```{code} yaml
q1: quad, l = 2
q2: quad, l = 4, x_offset = 0.02, x_pitch = 0.01
d: drift, l = 8
g4: girder = \{q1, q2\}, x_pitch = 0.002, x_offset = 0.03
this_line: line = (q1, d, q2)
use, this_line
```
\index{overlay}
In this example, `g4` supports quadrupoles `q1` and `q2`.
Since the supported elements are colinear, the computation is greatly
simplified. The reference frame of `g4`, which is the default
`origin` frame, is at {math}`s = 7`
start of `q1` at at {math}`s = 0`
at {math}`s = 14`
centers so the {math}`s`
```{code} yaml
Element        S_ref   dS_from_g4
q1             1.0     -6.0
g4             7.0      0.0
q2            12.0      5.0
```
Using a small angle approximation to simplify the calculation, the `x_pitch` of `g4` produces
an offset at the center of `q2` of {math}`0.01 = 0.002 * 5`
`q2`, give the total `x_offset`, denoted `x_offset_tot` of `q2` is
{math}`0.06 = 0.01 + 0.03 + 0.02`
The total `x_pitch`, denoted `x_pitch_tot`, of `q2` is {math}`0.022 = 0.02 + 0.001`

A `Girder` that has its `is_on` attribute set to False is considered to be unsifted with
respect to it's reference frame.

%---------------------------------------------------------------------------------------------------
(s:instrument)=
## Instrument
An `Instrument` is like a `Drift` except it represents some measurement device.

%---------------------------------------------------------------------------------------------------
(s:kicker)=
## Kicker
A `Kicker` element gives particles a kick.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:lcavity)=
## LCavity
An `LCavity` is a LINAC accelerating cavity.  The main difference between an `RFCavity` and an
`LCavity` is that, unlike an `RFCavity`, the reference energy ([](#s:ref.energy)) through
an `LCavity` is not constant.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:marker)=
## Marker
A `Marker` is a zero length element meant to mark a position in the machine.

%---------------------------------------------------------------------------------------------------
(s:mask)=
## Mask
A `Mask` element defines an aperture where the mask area can
essentially have an arbitrary shape.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:match)=
## Match
A `Match` element is used to adjust Twiss and orbit parameters.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:mult)=
## Multipole
A `Multipole` is a thin magnetic multipole lens.

%---------------------------------------------------------------------------------------------------
(s:nullele)=
## NullEle
A `NullEle` is used for bookkeeping purposes. For example, a `NullEle` can be used as
the default value for a function argument or as a temporary place marker in a lattice.

%---------------------------------------------------------------------------------------------------
(s:octupole)=
## Octupole
An `Octupole` is a magnetic element with a cubic field dependence
with transverse position ([](#s:mag.field)).

%-----------------------------------------------------------------------------
(s:patch)=
## Patch

```{figure} figures/patch-problem.svg
\caption[The branch reference coordinates in a `Patch` element.]
{The branch reference coordinates in a `Patch` element. The `Patch` element, shown
schematically as an irregular quadrilateral, is sandwiched between elements `ele_a` and
`ele_b`. `L` is the length of the `Patch`. In this example, the `Patch` has a finite
`y_rot`.}
:name: f:patch.prob
```

A `Patch` element shifts the reference orbit and time. Also see `FloorShift`
([](#s:floorshift)) and `Fiducial` ([](#s:fiducial)) elements. A common application of a patch
is to orient two branch lines with respect to each other.


A `Patch` ([](#s:patch)) element is different in that there is no "natural" coordinate
system to use within the Patch. This is generally not an issue when the region inside the
Patch is field and aperture free since particle tracking can be done in one step from edge
to edge. However, when there are fields or apertures an internal
coordinate system is needed so that the fields or apertures can be unambiguously positioned.


Generally, if a particle is reasonably near the branch reference curve, there is a one-to-one mapping
between the particle's position and branch {math}`(x, y, s)`


with a non-zero `x_rot` or non-zero `y_rot` breaks the one-to-one mapping. This is
illustrated in {numref}`f:patch.prob`.  The `Patch` element, shown schematically as an, irregular
quadrilateral, is sandwiched between elements `ele_a` and `ele_b`. The branch coordinate system
with origin at {math}`\alpha`
the `Patch` has its origin labeled {math}`\gamma`
taken to be the longitudinal distance from {math}`\alpha` to {math}`\gamma`
coordinates defining the longitudinal direction. The "beginning" point of the `Patch` on the
reference curve a distance `L` from point {math}`\gamma` is labeled {math}`\beta`

In the branch {math}`(x, y, s)` coordinate system a particle at {math}`\alpha` will have some value {math}`s = s_0`
particle at point {math}`\beta` will have the same value {math}`s = s_0` and a particle at {math}`\gamma`
{math}`s = s_1 = s_0 + L`. A particle at point {math}`r_a`
assigning {math}`(x, y, s)`
the region of `ele_a`, the particle's {math}`s` position will be {math}`s_{a2}`
value {math}`s_0`
`ele_a` will have {math}`s \le s_0`
the `Patch` region, the particle's {math}`s` position will be {math}`s_{a1}`
{math}`s_0`
`Patch` will have {math}`s \ge s_0`

To resolve this problem, AcceleratorLattice considers a particle at position {math}`r_a`
region. This means that there is, in theory, no lower limit to the {math}`s`
the `Patch` region can have. This also implies that there is a discontinuity in the {math}`s`
of a particle crossing the exit face of `ele1`. Typically, when particles are translated from the
exit face of one element to the exit face of the next, this `Patch` problem does not appear. It
only appears when the track between faces is considered.

Notice that a particle at position {math}`r_b`
be in either `ele_a` or the `Patch`. While this creates an ambiguity it does not complicate
tracking.

%---------------------------------------------------------------------------------------------------
(s:quadrupole)=
## Quadrupole
A `Quadrupole` is a magnetic element with a linear field dependence
with transverse offset ([](#s:mag.field)).


%---------------------------------------------------------------------------------------------------
(s:rfcavity)=
## RFCavity
An `RFCavity` is an RF cavity without acceleration generally used in a storage ring. The main
difference between an `RFCavity` and an `LCavity` is that, unlike an `Lcavity`, the
reference energy ([](#s:phase.space)) through an `RFCavity` is constant.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:sextupole)=
## Sextupole
A `Sextupole` is a magnetic element with a quadratic field
dependence with transverse offset ([](#s:mag.field)).


%---------------------------------------------------------------------------------------------------
(s:solenoid)=
## Solenoid
A `solenoid` is an element with a longitudinal magnetic field.

%---------------------------------------------------------------------------------------------------
(s:taylor)=
## Taylor
A `Taylor` element is a Taylor map ([](#s:taylor.phys)) that maps the input orbital phase space and
possibly spin coordinates of a particle to the output orbital and
spin coordinates at the exit end of the element.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:thickmult)=
## ThickMultipole
A `ThickMultipole` is a general non-zero length multipole element.

%---------------------------------------------------------------------------------------------------
(s:undulator)=
## Undulator
An `Undulator` is and element with a periodic array of alternating bends.
Also see `Wiggler` elements.

NOTE: This Element is in development and is incomplete.

%---------------------------------------------------------------------------------------------------
(s:unionele)=
## UnionEle
A `UnionEle` is an element that contains a collection of other elements.
A `UnionEle` is used when elements overlap spatially which happens with superposition ([](#c:super)).

%---------------------------------------------------------------------------------------------------
(s:wiggler)=
## Wiggler
A `Wiggler` is and element with a periodic array of alternating bends.
Also see `Undulator` elements.

NOTE: This Element is in development and is incomplete.
```{footbibliography}
```
