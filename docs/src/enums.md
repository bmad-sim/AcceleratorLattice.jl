(c:enums)=
# Enums and Holy Traits
Enums ([](#s:enums)) and Holy traits ([](#s:holy)) are used to define "switches" which are
variables whose value can be one of a set of named constants.
A web search will provide documentation.

The advantage of Holy traits is that they can be used with function dispatch. The disadvantage is
that the same Holy trait value name cannot be used with multiple groups. Generally, if function
dispatch is not needed (which is true for the majority of cases), switch groups are defined using enums.

%---------------------------------------------------------------------------------------------------
(s:enums)=
## Enums
AcceleratorLattice uses the package `EnumX.jl` to define enums (enumerated numbers).
Essentially what happens is that for each enum group there is a group name, For example `BendType`,
along with a set of values which, for `BendType`, is `SECTOR` and `RECTANGULAR`. Values
are always referred to by their "full" name which in this example is `BendType.SECTOR` and
`BendType.RECTANGULAR`. Exception: `BranchGeometry.CLOSED` and `BranchGeometry.OPEN` are
used often enough so that the constants `OPEN` and `CLOSED` are defined.

The group name followed by a `.T` suffix denotes the enum type.
For example:
```{code} yaml
struct ApertureParams <: EleParams
aperture_type::ApertureShape.T = ApertureShape.ELLIPTICAL
aperture_at::BodyLoc.T = BodyLoc.ENTRANCE_END
...
```

The `enum` function is used to convert a list into an enum group and export the names.
The `enum` function also overloads `Base.string` so that something like `string(Lord.NOT)`
will return `"Lord.NOT"` instead of just `"NOT"` (an issue with the EnumX.jl package).
See the documentation for `enum` for more details.

The `enum_add` function is used to add values to an existing enum group. See the documentation for
`enum_add` for more details. This function is used with code extensions to customize AcceleratorLattice.

The enum groups are:
```{csv-table}
:align: center
:header: "Element", "Element"
[BendType](#s:bendtype), [Slave](#s:slave.enum)
[BodyLoc](#s:bodyloc), [Loc](#s:loc)
[BranchGeometry](#s:branchgeometry), [Select](#s:select)
[Cavity](#s:cavity), [ExactMultipoles](#s:exactmultipoles)
[Lord](#s:lord.enum), [FiducialPt](#s:fiducialpt)
[ParticleState](#s:particlestate), [](#)
```
%---------------------------------------------------------------------------------------------------
(s:bendtype)=
## BendType Enum Params
Type of Bend element. Possible values: 
- BendType.SECTOR  - Sector shape
- BendType.RECTANGULAR  - Rectangular shape

`BendType` is used with the `bend_type` parameter of the `BendParams` parameter group
([](#s:bend.g)). The `bend_type` parameter gives the "logical" shape of the bend.
The setting of `bend_type` is only relavent when the bend curvature is varied.
See [](#s:bend.g) for more details.

%---------------------------------------------------------------------------------------------------
(s:bodyloc)=
## BodyLoc Enum Params
Longitudinal location with respect to an element's body coordinates.
Possible values:
- BodyLoc.ENTRANCE_END  - Body entrance end
- BodyLoc.CENTER  - Element center
- BodyLoc.EXIT_END  - Body exit end
- BodyLoc.BOTH_ENDS  - Both ends
- BodyLoc.NOWHERE  - No location
- BodyLoc.EVERYWHERE  - Everywhere

`BodyLoc` enums are are useful to locate things that are "attached" to an element.
For example, specifying where apertures are placed.

%---------------------------------------------------------------------------------------------------
(s:branchgeometry)=
## BranchGeometry Enum Params
Geometry of a lattice branch. Used for setting a branche's `geometry` parameter.
Possible values:
- BranchGeometry.OPEN  - Open geometry like a Linac. Default
- BranchGeometry.CLOSED  - Closed geometry like a storage ring.

A branch with a `CLOSED` geometry is something like a storage ring where the particle beam
recirculates through the machine. A branch with an `OPEN` geometry is something like a linac.
In this case, the initial Twiss parameters need to be
specified at the beginning of the branch. If the
`geometry` is not specified, `OPEN` is the default.

Since the geometry is widely used, `OPEN` and `CLOSED` have been defined and
can be used in place of `BranchGeometry.OPEN` and `BranchGeometry.CLOSED`.

Notice that by specifying a `CLOSED` geometry, it does {em not} mean that the downstream end of
the last element of the branch has the same floor coordinates ([](#s:floor)) as the floor
coordinates at the beginning. Setting the geometry to `CLOSED` simply signals to a program to
compute the periodic orbit and periodic Twiss parameters as opposed to calculating orbits and Twiss
parameters based upon initial orbit and Twiss parameters given at the beginning of the branch.  Indeed,
it is sometimes convenient to treat branches as closed even though there is no closure in the floor
coordinate sense. For example, when a machine has a number of repeating "periods", it may be
convenient to only use one period in a simulation. Since AcceleratorLattice ignores closure in the floor
coordinate sense, it is up to the lattice designer to ensure that a branch is truly geometrically
closed if that is desired.

%---------------------------------------------------------------------------------------------------
(s:cavity)=
## Cavity Enum Params
Type of RF cavity.
Possible values:
- Cavity.STANDING_WAVE  - Standing wave cavity
- Cavity.TRAVELING_WAVE  - Traveling wave cavity

%---------------------------------------------------------------------------------------------------
(s:particlestate)=
## ParticleState Enum Params
State of a particle.
Possible values:
- ParticleState.PREBORN  - State before emission from cathode.
- ParticleState.ALIVE  - Alive and kicking.
- ParticleState.LOST  - Particle has been lost.
- ParticleState.LOST_NEG_X  - Hit aperture in the -x direction.
- ParticleState.LOST_POS_X  - Hit aperture in the +x direction.
- ParticleState.LOST_NEG_Y  - Hit aperture in the -y direction.
- ParticleState.LOST_POS_Y  - Hit aperture in the +y direction.
- ParticleState.LOST_PZ  - Lost all forward momentum.
- ParticleState.LOST_Z  - Out of RF bucket.

The `LOST` value is used when it is not possible to assign the particle state to one of the
other lost values.

The `.LOST_PZ` value is used by {math}`s`
able to handle particles changing their longitudinal motion direction. For tracking something
like dark current electrons which can go back and forth longitudinally, a time based tracker
is needed.

%---------------------------------------------------------------------------------------------------
(s:loc)=
## Loc Enum Params
Longitudinal location with respect to element's branch coordinates.
Possible values: 
- Loc.UPSTREAM_END  - Upstream element end
- Loc.CENTER  - center of element
- Loc.INSIDE  - Somewhere inside
- Loc.DOWNSTREAM_END  - Downstream element end


%---------------------------------------------------------------------------------------------------
(s:select)=
## Select Enum Params
Specifies where to select if there is a choice of elements or positions.
Possible values:
- Select.UPSTREAM  - Select upstream
- Select.DOWNSTREAM  - Select downstream


%---------------------------------------------------------------------------------------------------
(s:exactmultipoles)=
## ExactMultipoles Enum Params
How multipoles are handled in a Bend element.
Possible values:
- ExactMultipoles.OFF  - Bend curvature not taken into account.
- ExactMultipoles.HORIZONTALLY_PURE  - Coefficients correspond to horizontally pure multipoles.
- ExactMultipoles.VERTICALLY_PURE  - Coefficients correspond to vertically pure multipoles.


%---------------------------------------------------------------------------------------------------
(s:fiducialpt)=
## FiducialPt Enum Params
Fiducial point location with respect to element's branch coordinates.
Possible values:
- FiducialPt.ENTRANCE_END  - Entrance end of element
- FiducialPt.CENTER  - Center of element
- FiducialPt.EXIT_END  - Exit end of element
- FiducialPt.NONE  - No point chosen


%---------------------------------------------------------------------------------------------------
(s:holy)=
## Holy Traits
`Holy traits` (named after Tim Holy) are a design pattern in Julia that behave similarly
to `enums` ([](#s:enum)). A Holy trait group consists of a base abstract type with a set of values
(traits) which are abstract types that inherit from the base abstract type.

The advantage of Holy traits is that they can be used with function dispatch. The disadvantage is
that the same Holy trait value name cannot be used with multiple groups.

There is a convenience function `holy_traits` which will define a traits group, export the names,
and create a docstring for the group. Values can be added to an existing group by defining a
new struct that inherits from the group abstract type.

Example: To extend the `EleGeometry` trait group to include the value `HELIX_GEOMETRY` do
```{code} yaml
abstract type HELIX_GEOMETRY <: EleGeometry
```

%---------------------------------------------------------------------------------------------------
(s:apertureshape)=
## ApertureShape Holy Trait Params
The shape of an aperture.
- RECTANGULAR     - Rectangular shape.
- ELLIPTICAL      - Elliptical shape.
- VERTEX          - Shape defined by set of vertices.
- CUSTOM_SHAPE    - Shape defined with custom function.

%---------------------------------------------------------------------------------------------------
(s:elegeometry)=
## EleGeometry Holy Trait Params
The geometry of the reference orbit through an element. 
- STRAIGHT            - Straight line geometry.
- CIRCULAR            - Circular "bend-like" geometry.
- ZERO_LENGTH         - Zero longitudinal length geometry.
- PATCH_GEOMETRY      - Patch element like geometry.
- GIRDER_GEOMETRY     - Support girder-like geometry.
- CRYSTAL_GEOMETRY    - Crystal geometry.
- MIRROR_GEOMETRY     - Mirror geometry.

```{footbibliography}
```
