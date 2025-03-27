(c:ele.groups)=
# Element Parameters
Generally, element parameters are grouped into "`element` `parameter` `group`"
types. How these groups are used in a lattice element is discussed in [](#c:ele).
This chapter discusses the groups in detail.

The parmeter groups are:
```{csv-table}

:align: center
:header: "Element", "Element"

[ACKickerParams](#s:ackicker.g), [LengthParams](#s:length.g)
[FloorParams](#s:floor.g), [LordSlaveStatusParams](#s:lord.slave.g)
[ApertureParams](#s:aperture.g), [MasterParams](#s:master.g)
[BMultipoleParams](#s:bmultipole.g), [FloorParams](#s:orientation.g)
[BeamBeamParams](#s:beam.beam.g), [OriginEleParams](#s:origin.ele.g)
[BendParams](#s:bend.g), [PatchParams](#s:patch.g)
[DescriptionParams](#s:descrip.g), [RFParams](#s:rf.g)
[DownstreamReferenceParams](#s:dreference.g), [RFAutoParams](#s:rfauto.g)
[EMultipoleParams](#s:emultipole.g), [ReferenceParams](#s:reference.g)
[ForkParams](#s:fork.g), [SolenoidParams](#s:solenoid.g)
[GirderParams](#s:girder.g), [TrackingParams](#s:tracking.g)
[InitParticleParams](#s:init.particle.g), [TwissParams](#s:twiss.g)
```

Element parameter groups inherit from the abstract type `EleParams` which
in turn inherits from `BaseEleParams`. Some
parameter groups have sub-group components.
These sub-groups also inherit from `BaseEleParams`:
```{code} yaml
abstract type BaseEleParams end
abstract type EleParams <: BaseEleParams end
abstract type EleParameterSubParams <: BaseEleParams end
```

To see which element types contain a given group, use the `info(::EleParams)`
method. Example:
```{code} yaml
julia> info(ApertureParams)
ApertureParams: Vacuum chamber aperture.
x_limit::Vector{Number}         Min/Max horizontal aperture limits. (m)
y_limit::Vector{Number}         Min/Max vertical aperture limits. (m)
...
Found in:
ACKicker
BeamBeam
BeginningEle
...
```

To get information on a given element parameter, including what element group the parameter is in,
use the `info(::Symbol)` function using the symbol corresponding to the parameter. For example,
to get information on the multipole component `Ks2L` do:
```{code} yaml
julia> info(:Ks2L)
User name:       Ks2L
Stored in:       BMultipoleParams.Ks
Parameter type:  Number
Units:           1/m^2
Description:     Skew, length-integrated, momentum-normalized,
magnetic multipole of order 2.
```

Notes:
begin{itemize}
%
- All parameter groups have associated docstrings that can be accessed using the REPL help system.
%
- NaN denotes a real parameter that is not set.
%
- Parameters marked "dependent" are parameters calculated by AcceleratorLattice and not settable by the User.
%
- There are several lattice element parameters that are not stored in a parameter group but are stored
alongside of the parameter groups in the element Dict. Included is the element's name, and information
on lords and slaves of the element.
%
end{itemize}

To simplify the structure of a lattice element, certain element parameters are not stored in the
element structure but are calculated as needed. These "`output`" cannot be set.
See [](#s:ele.access) for details.

%---------------------------------------------------------------------------------------------------
(s:ackicker.g)=
## ACKickerParams
The `ACKickerParams` holds parameters associated with `ACKicker` elements.

The parameters of this group are:
```{code} yaml
amp_function::Function      - Amplitude function.
```


%---------------------------------------------------------------------------------------------------
(s:alignment.g)=
## BodyShiftParams
caption[Element alignment.]
{BodyShiftParams parameters The reference point is the origin
about which the element alignment is calculated.
A) For straight elements, the reference point is in the center of the element.
For `Bend` elements, the reference point is at the midpoint of the chord connecting
the entrance point to the exit point. The drawing for the bend is valid for a `ref_tilt`
of zero. For non-zero `ref_tilt`, the outward direction from the bend center will not be
the {math}`x`-axis.
}  label{f:alignment}
```

{Alignment geometry. A) `z_rot` (or `z_rot_tot`) rotation. B) Combined
`offset[1]` with `y_rot` (or `offset_tot[1]` with `y_rot_tot`).
}  label{f:alignment}
```

The `BodyShiftParams` gives the alignment (position and angular orientation) of the physical element
relative to the nominal position defined by the branch coordinates ([](#s:orient)).
Alignment is specified with respect to the "alignment reference point" of an element as shown
in Fig~[](#s:alignment). The `Bend` reference point is chosen to be the center of the chord
connecting the two ends.
This reference point was chosen over using the midpoint on the reference orbit arc since a
common simulation problem is to simulate a bend with a `z_rot` keeping the entrance and exit
endpoints fixed.

The parameters of the `BodyShiftParams` are:
```{code} yaml
offset::Vector - {math}`[x, y, z]` offset.
x_rot::Number  - Rotation around the x-axis.
y_rot::Number  - Rotation around the z-axis.
z_rot::Number  - Rotation around the z-axis.
```
If the element is supported by a `Girder`, the alignment parameters are with respect to the
orientation of the `Girder` position. If there is no supporting `Girder`, the alignment
parameters are with respect to the branch reference coordinates. There are output alignment
parameters:
```{code} yaml
q_shift::Quaternion     - Quaternion representation of x_rot, y_rot, z_rot.
offset_tot::Vector      - {math}`[x, y, z]` offset.
x_rot_tot::Number       - Rotation around the x-axis.
y_rot_tot::Number       - Rotation around the z-axis.
z_rot_tot::Number       - Rotation around the z-axis.
q_shift_tot::Quaternion - Quaternion  representation of tot rotations.
```
The "total alignment" parameters which have a `_tot` suffix are always the alignment
of the element with with respect to the branch coordinates.
If there is no support `Girder`, the total alignment will be the same as the "relative"
(non-tot) alignment.

The relative alignment can be set by the User.
The total alignment is computed by AcceleratorLattice based upon the relative alignment and the alignment
of any `Girder`. `Girder` elements themselves also have both relative and total
alignments since Girders can support other Girders.

The `q_shift` output parameter gives the quaternion representation of
`x_rot`, `y_rot` and `z_rot`. Similarly, the`q_shift_tot` output parameter gives the
quaternion representation of `x_rot_tot`, `y_rot_tot` and `z_rot_tot`.

%---------------------------------------------------------------------------------------------------
(s:aperture.g)=
## ApertureParams
{
A) RECTANGULAR and ELLIPTICAL apertures. As drawn, `x_limit[1]` and `y_limit[1]` are
negative and `x_limit[2]` and `y_limit[2]` are positive. B) The VERTEX aperture is defined
by a set of vertices.
}  label{f:apertures}
```

The `ApertureParams` stores information about apertures an element may have.
The parameters of this group are:
```{code} yaml
x_limit::Vector{Number}     - Min/Max x-aperture limits. (m)
y_limit::Vector{Number}     - Min/Max y-aperture limits. (m)
aperture_shape::ApertureShape - Aperture shape. Default: ELLIPTICAL
aperture_at::BodyLoc.T        - Aperture location. Default: BodyLoc.ENTRANCE_END
wall::Wall2D                  - Aperture defined by vertex array.
custom_aperture::Dict         - Custom aperture information.
aperture_shifts_with_body::Bool
- Alignment affects aperture? Default: false.
```

The aperture location is set by the `aperture_at` parameter. Possible values are
given by the `BodyLoc` enum group ([](#s:bodyloc)). The default is `BodyLoc.ENTRANCE_END`.
The `.EVERYWHERE` location might be problematic for some types of particle tracking and
so might not be always available.

The `aperture_shape` parameter selects the shape of the aperture. Possible values are
given by the `ApertureShape` Holy trait group.
```{code} yaml
RECTANGULAR   - Rectangular shape.
ELLIPTICAL    - Elliptical shape.
VERTEX        - Shape defined by set of vertices.
CUSTOM_SHAPE  - Shape defined with a custom function.
```

For `RECTANGULAR` and `ELLIPTICAL` shapes the `x_limit` and `y_limit` parameters are
used to calculate the aperture as shown in {numref}`f:apertures`A. For an `ELLIPTICAL` aperture,
a particle with position {math}`(x, y)` is outside of the aperture if any
one of the following four conditions is true:
```{code} yaml
1) x < 0 and y < 0 and (x/x_limit[1])^2 + (y/y_limit[1])^2 > 1
2) x < 0 and y > 0 and (x/x_limit[1])^2 + (y/y_limit[2])^2 > 1
3) x > 0 and y < 0 and (x/x_limit[2])^2 + (y/y_limit[1])^2 > 1
4) x > 0 and y > 0 and (x/x_limit[2])^2 + (y/y_limit[2])^2 > 1
```
For a `RECTANGULAR` aperture the corresponding four conditions are:
```{code} yaml
1) x < x_limit[1]
2) x > x_limit[2]
3) y < y_limit[1]
4) y > y_limit[2]
```

Default values for the limits are `-Inf` for `x_limit[1]` and `y_limit[1]` and
`Inf` for `x_limit[2]` and `y_limit[2]`.

The `misalignment_moves_aperture` parameter determines whether misaligning an element
([](#s:alignment.g)) affects the placement of the aperture. The default is `false`.
A common case where `misalignment_moves_aperture` would be `false` is when a beam pipe,
which incorporates the aperture, is not physically touching the surrounding magnet element.
When tracking a particle, assuming that there are only apertures at the element ends,
the order of computation with `misalignment_moves_aperture` set to `false` is
```{code} yaml
1) Start at upstream end of element
2) Check upstream aperture if there is one.
3) Convert from branch coordinates to body coordinates.
4) Track through the element body.
5) Convert from body coordinates to branch coordinates.
6) Check downstream aperture if there is one.
7) End at downstream end of element.
```
With `misalignment_moves_aperture` set to `true`, the computation order is
```{code} yaml
1) Start at upstream end of element
2) Convert from branch coordinates to body coordinates.
3) Check upstream aperture if there is one.
4) Track through the element body.
5) Check downstream aperture if there is one.
6) Convert from body coordinates to branch coordinates.
7) End at downstream end of element.
```

The `CUSTOM_SHAPE` setting for `aperture_shape` indicates whether a User supplied function
is used to calculate whether the particle has hit the aperture. The function is stored
in the `custom_aperture` parameter. The `custom_aperture` parameter is a Dict that stores
the aperture function along with any data that the aperture calculation needs. The aperture
function must be stored in `custom_aperture[:function]` and this function will be
called with the signature
```{code} yaml 
custom_aperture[:function](position::Vector, ele::Ele) -> ParticleState
```
where `position` is the phase space 6-vector of the particle, `ele` is the element
with the aperture, and a `ParticleState` ([](#s:particlestate)) value is returned.

The `VERTEX` setting for `aperture_shape` is for defining an aperture using a
set of vertex points as illustrated in {numref}`f:apetures`B. Between vertex points, the aperture
can can follow a straight line or the arc of an ellipse. The vertex points are specified by
setting the `section` parameter of `ApertureParams`. Example:
```{code} yaml
wall = Wall2D([Vertex1([1.0, 4.0]), Vertex1([-1.0, 4.0, 6.0]),
Vertex1([-5.0, 1.0]), Vertex1([-5.0, -1.0]),
Vertex1([1.0, -1.5)]], r0 = [-2.5, 0.5])
```

%---------------------------------------------------------------------------------------------------
(s:bmultipole.g)=
## BMultipoleParams
The `BMultipoleParams` group stores magnetic multipole strengths. Also see `EMultipoleParams`.
The parameters of this group are:
```{code} yaml
vec::Vector{BMultipole1}
```
This group stores a vector of `BMultipole1` structs.
The `BMultipole1` structure stores the values for a magnetic multipole of a given order.
Only orders where there is a non-zero multipole are stored and there is no maximum limit to the
order that can be stored. The multipoles will be stored in increasing order.

The `BMultipole1` structure has components:
```{code} yaml
Kn::Number     - Normal normalized component. EG: "Kn2", "Kn2L".
Ks::Number     - Skew multipole component. EG: "Ks2", "Ks2L".
Bn::Number     - Normal field component.
Bs::Number     - Skew field component.
tilt::Number   - Rotation of multipole around z-axis.
order::Int     - Multipole order.
integrated::Union{Bool,Nothing} - Integrated multipoles or not?
```
The `order` component gives the multipole order.
There is storage for both normalized (`Kn` and `Ks`) and unnormalized (`Bn` and `Bs`)
field strengths. The letter "`n`" designates the normal component and "`s`" designates
the skew component.
The AcceleratorLattice bookkeeping code will take care of calculating the normalized field if the unnormalized
field is set and vice versa. The reason why the structure has three components,
normal, skew and tilt, that describe the field when only two would be sufficient is due convenience.
Having normal and skew components is convenient when magnet has multiple windings that control
both independently. A common case is combined horizontal and vertical steering magnets. On the
other hand, being able to "misalign" the multipole using the `tilt` component is also
useful.

The dot selection operator for an element ([](#s:ele.access)) is overloaded so that
magnetic multipole parameters for order {math}`J` can be accessed using the following notation:
{tt
Need custom handling!!!!
Name        & Stored In  & Normalized & Integrated & Description  midrule
KnJ         & Kn         & Yes        & No         & Normal field. 
KsJ         & Ks         & Yes        & No         & Skew field. 
KnJL        & Kn         & Yes        & Yes        & Normal field. 
KsJL        & Ks         & Yes        & Yes        & Skew field. 
BnJ         & Bn         & No         & No         & Normal field. 
BsJ         & Bs         & No         & No         & Skew field. 
BnJL        & Bn         & No         & Yes        & Normal field. 
BsJL        & Bs         & No         & Yes        & Skew field. 
tiltJ       & tilt       & --         & --         & Field tilt. 
integratedJ & integrated & --         & --         & Integrated fields? 
bottomrule
Substitute the multipole order for {math}`J` in the above table. For example, `Ks2L` is the
normalized length-integrated skew field component of order 2.

Notice that both integrated
and non-integrated fields are potentially stored in the same component of `BMultipole1`.
Which type is stored is determined by the `integrated` logical. If `true`, the integrated
value is stored and vice versa. The `integrated` setting can be different for different orders.
The setting of `integrated` for a given order is determined by whether the first field component
to be set for that order is an integrated quantity or not. After the value of `integrated` is set,
an error will be thrown if a something that has the opposite sense in terms of integration is
set. For example:
```{code} yaml
@ele qq = Quadrupole(l = 0.6, Ks0L = 1.0)  # 0th order multipole is integrated
qq.Bn1 = 0.3                  # 1st order multipole is not integrated
qq.Ks1 = 0.5                  # This is OK.
println(qq.integrated0)       # Will print "true"
println(qq.Bn0)               # Can use non-integrated component.
qq.Bn0 = 0.7                  # Cannot set non-integrated component! error thrown!
toggle_integrated!(qq, MAGNETIC, 0)  # toggle integrated setting for order 0.
```
In the above example, the 0th order multipole is initialized using `Ks0L` so that
multipole will have the `integrated` component set to `true` and non-integrated values
cannot be set. However, independent of the setting of `integrated`, both integrated and
non-integrated quantities can always be used in an equation. To change the value of `integrated`,
use the `toggle_integrated!` function. This function also translates the values stored in the
field components of the structure so that the field will stay constant.

The setting of `integrated` for a given multipole will also determine what stays constant
of the length of the magnet changes. If `integrated` is `true`, the integrated values
will be invariant and vice versa for `integrated` being `false`. Similarly, the setting
of the `field_master` parmeter ([](#s:master.g)) will determine whether normalized or
unnormalized quantities will stay constant if the reference energy is varied.

%---------------------------------------------------------------------------------------------------
(s:beam.beam.g)=
## BeamBeamParams
The parameters of this group are:
```{code} yaml
n_slice::Number           - Number of slices the Strong beam is divided into.
n_particle::Number        - Number of particle in the strong beam.
species::Species          - Strong beam species. Default is weak particle species.
z0_crossing::Number       - Weak particle phase space z when strong beam center
-   passes the BeamBeam element.
repetition_freq:: Number  - Strong beam repetition rate.
twiss::Twiss              - Strong beam Twiss at IP.
sig_x::Number             - Strong beam horizontal sigma at IP.
sig_y::Number             - Strong beam vertical sigma at IP.
sig_z::Number             - Strong beam longitudinal sigma.
bbi_constant::Number      - BBI constant. Set by Bmad. See manual.
```

%---------------------------------------------------------------------------------------------------
(s:bend.g)=
## BendParams
The `BendParams` stores the parameters that characterize the shape of a `Bend` element
[](#s:bend). The only relavent shape parameter that is not in the `BendParams` is the
length `L` which is in the `LengthParams`.

The parameters of this group are:
```{code} yaml
bend_type::BendType.T     - Type of bend. Default: BendType.SECTOR.
angle::Number             - Reference bend angle.
g::Number                 - Reference bend strength = 1/radius.
bend_field_ref::Number    - Reference bend field.
L_chord::Number           - Chord length.
tilt_ref::Number          - Reference tilt.
e1::Number                - Entrance end pole face rotation.
e2::Number                - Exit end pole face rotation.
e1_rect::Number           - Entrance end pole face rotation.
e2_rect::Number           - Exit end pole face rotation.
edge_int1::Number         - Entrance end fringe field integral.
edge_int2::Number         - Exit end fringe field integral
exact_multipoles::ExactMultipoles.T  - Default: ExactMultipoles.OFF
```


Associated output parameters:
```{code} yaml
rho::Number             - Reference bend radius.
L_sagitta::Number       - Sagitta length.
bend_field::Number      - Actual dipole field in the plane of the bend.
norm_bend_field::Number - Actual dipole strength in the plane of the bend.
```

{centering
```{figure} figures/bend.svg
caption[Bend geometry]{
Bend geometry. Red dots are the entry and exit points that define the origin for the
coordinate systems at the entry end {math}`(s_1, x_1)` and exit ends {math}`(s_2, x_2)` respectively.
In the figure, the angle `alpha` is denoted {math}`alpha` and the radius
`rho` is denoted {math}`rho`.
A) Bend geometry with positive bend angle. For the geometry shown,
`g`, `angle`, `rho`, `e1`, `e2`, `e1_rect`, and `e2_rect` are all positive.
B) Bend geometry with negative bend angle. For the geometry shown,
`g`, `angle`, `rho`, `e1`, `e2`, `e1_rect`, and `e2_rect` are all negative.
Note: The figures are drawn for zero `ref_tilt` where the rotation axis is parallel to the
{math}`y`-axis.
}
:name: f:bend
}
```

In detail:
%
- **angle** Newline
The total Reference bend angle. A positive `angle` represents a
bend towards negative {math}`x` as shown in {numref}`f:bend`.
%
- **bend_field_ref** Newline
The `bend_field_ref` parameter is the reference magnetic bending field which is the field
that is needed for the reference particle to be bent in a circle of radius `rho`
and the placement of lattice elements downstream from the bend. The actual ("total") field is
a vector sum of
`bend_field_ref` plus the value of the `Bn0`  and `Bs0` multipoles. If `tilt0` and `Bs0`
are zero, the actual field is
```{code} yaml
B-field (total) = bend_field_ref + Bn0
```
See the discussion of `g` and `Kn0` below for more details.
%
- **bend_field (output param), norm_bend_field (output_param)** Newline
The actual dipole bend field ignoring any skew field component which is set by `Bs0`.
The relation between this and `bend_field_ref` is
```{code} yaml
bend_field = bend_field_ref + Bn0 * cos(tilt0) + Bs0 * sin(tilt0)
```
%
- **bend_type** Newline
The `bend_type` parameter sets the "logical shape" of the bend.
This parameter is of type `BendType.T` ([](#s:bendtype)) and can take values of
```{code} yaml
BendType.RECTANGULAR  - or
BendType.SECTOR       - The default
```
The logical shape of a bend, in most situations, is irrelevant.
The only case where the logical shape is used is when the bend angle is varied.
In this case, for a `SECTOR` bend, the face angles `e1` and `e2` are
held constant and `e1_rect` and `e2_rect` are varied to keep Eqs{eeaeea} satisfied.
%
- **e1, e2** Newline
The values of `e1` and `e2` gives the rotation angle of the entrance and exit pole faces
respectively with respect to the radial {math}`x_1` and {math}`x_2` axes as shown in {numref}`f:bend`.
Zero `e1` and `e2` gives a wedge shaped magnet.
Also see `e1_rect` and `e2_rect`. The relationship is
begin{equation}
parbox{30em} {
e1 = e1_rect + angle/2 
e2 = e2_rect + angle/2
label{eeaeea}
end{equation}

Note: The correspondence between `e1` and `e2` and the corresponding parameters used in the
SAD program {footcite:p}`Zhou:SADmaps` is:
```{code} yaml
e1(AccelLattice) =  e1(SAD) * angle + ae1(SAD)
e2(AccelLattice) =  e2(SAD) * angle + ae2(SAD)
```
%
- **e1_rect, e2_rect**
Face angle rotations like `e1` and `e2` except angles are measured with respect to
fiducial lines that are parallel to each other and rotated by `angle`/2 from the radial
{math}`x_1` and {math}`x_2` axes as shown in {numref}`f:sbend`.
Zero `e1_rect` and `e2_rect` gives a rectangular magnet shape.
%
- **exact_multipoles** Newline
The `exact_multipoles` switch can be set to one of:
```{code} yaml
off                 ! Default
vertically_pure
horizontally_pure
```
This switch determines if the multipole fields, both magnetic and electric, and including the
`k1` and `k2` components, are corrected for the finite curvature of the reference orbit in a
bend. See [](#s:field.exact) for a discussion of what `vertically` pure versus
`horizontally` pure means. Setting `exact_multipoles` to `vertically_pure` means that the
individual {math}`a_n` and {math}`b_n` multipole components are used with the vertically pure solutions
begin{equation}
bfB = sum_{n = 0}^infty left[ frac{a_n}{n+1} nabla phi_n^r + frac{b_n}{n+1} nabla phi_n^i right], qquad
bfE = sum_{n = 0}^infty left[ frac{a_{en}}{n+1} nabla phi_n^i + frac{b_{en}}{n+1} nabla phi_n^r right]
end{equation}
and if `exact_multipoles` is set to `horizontally_pure` the horizontally pure solutions
{math}`psi_n^r` and {math}`psi_n^i` are used instead of the vertically pure solutions {math}`phi_n^r` and
{math}`phi_n^i`.
%
- **edge_int1, edge_int2** Newline
The field integral for the entrance pole face `edge_int1` is given by
begin{equation}
text{edge}_1 = int_{pole} ! ! ds , frac{B_y(s) , (B_{y0} - B_y(s))}
{2 , B_{y0}^2}
label{fsbbb}
end{equation}
For the exit pole face there is a similar equation for `edge_int2`

Note: In Bmad and MAD, these integrals are represented by the product of `fint` and `hgap`.

Note: The SAD program uses `fb1+f1` for the entrance fringe and `fb2+f1` for the exit
fringe. The correspondence between the two is
begin{example2}
edge_int1 = (fb1 + f1) / 12
edge_int2 = (fb2 + f1) / 12
end{example2}

`edge_int1` and `edge_int2` can be related to the Enge function which is sometimes used to model the
fringe field. The Enge function is of the form
begin{equation}
B_y(s) = frac{B_{y0}}{1 + exp[P(s)]}
end{equation}
where
begin{equation}
P(s) = C_0 + C_1 , s + C_2 , s^2 + C_3 , s^3 + , ldots
end{equation}
The {math}`C_0` term simply shifts where the edge of the bend is. If all the {math}`C_n` are zero except for
{math}`C_0` and {math}`C_1` then
begin{equation}
C_1 = frac{1}{2 , text{field_int}}
end{equation}
%
- **g, rho (output param)** Newline
The Reference bending radius which determines the reference coordinate system is `rho` (see
[](#s:ref)). `g` = `1/rho` is the "bend strength" and is proportional to the Reference
dipole magnetic field. `g` is related to the reference magnetic field `bend_field_ref` via
begin{equation}
text{g} = frac{q}{p_0} , text{bend_field_ref}
label{gqpb}
end{equation}
where {math}`q` is the charge of the reference particle and {math}`p_0` is the reference momentum. It is
important to keep in mind that changing `g` will change the Reference orbit ([](#s:coords.3)) and
hence will move all downstream lattice elements in space.

The total bend strength felt by a particle is the vector sum of `g` plus the zeroth order
magnetic multipole. If the multipole `tilt0` and `Ks0` is zero, the total bend strength is
```{code} yaml
norm_bend_field = g + Kn0
```
Changing the multipole strength `Kn0` or `Ks0` leaves the Reference orbit and the positions of
all downstream lattice elements
unchanged but will vary a particle's orbit. One common mistake when designing lattices is to vary
`g` and not `Kn0` which results in downstream elements moving around. See Sref{s:ex.chicane}
for an example.

Note: A positive `g`, which will bend particles and the reference orbit in the {math}`-x` direction
represents a field of opposite sign as the field due a positive `hkick`.
%
- **h1, h2** Newline
The attributes `h1` and `h2` are the curvature of the entrance and exit pole faces.
%
- **L, L_arc, L_chord, L_sagitta (output param)**  Newline
The `L` parameter, which is in the `LengthParams` and not the `BendParams`,
is the arc length of the reference trajectory through the bend.

`L_chord` is the chord length from entrance point to exit point.
The `L_sagitta` parameter is the sagitta length (The sagitta is the distance
from the midpoint of the arc to the midpoint of the chord). `L_sagitta` can be negative and will have
the same sign as the `g` parameter.
%
- **L_rectangle** Newline
The `L_rectangle` parameter is the "rectangular" length defined to be the distance between the
entrance and exit points. The coordinate system used for the calculation is defined by the setting
of `fiducial_pt`. {numref}`f:rbend` shows `l_rectangle` for `fiducial_pt` set to
`entrance_end` (the coordinate system corresponds to the entrance coordinate system of the bend).
In this case, and in the case where `fiducial_pt` is set to `exit_end`, the rectangular
length will be {math}`rho sinalpha`. If `fiducial_pt` is set to `none` or `center`,
`l_rectangle` is the same as the chord length.
%
- **ref_tilt** Newline
The `ref_tilt` attribute rotates a bend about the longitudinal axis at the entrance face of the
bend. A bend with `ref_tilt` of {math}`pi/2` and positive `g` bends the element in the {math}`-y`
direction ("downward"). See {numref}`f:tilt.bend`. It is important to understand that `ref_tilt`,
unlike the `tilt` attribute of other elements, bends both the reference orbit along with the
physical element. Note that the MAD `tilt` attribute for bends is equivalent to the Bmad
`ref_tilt`. Bends in Bmad do not have a `tilt` attribute.

Important! Do not use `ref_tilt` when doing misalignment studies for a machine. Trying to misalign
a dipole by setting `ref_tilt` will affect the positions of all downstream elements! Rather, use the
`tilt` parameter.

%---------------

The attributes `g`, `angle`, and `L` are mutually dependent. If any two are specified for
an element AcceleratorLattice will calculate the appropriate value for the third.

In the local coordinate system ([](#s:ref)), looking from "above" (bend viewed from positive
{math}`y`), and with `ref_tilt` = 0, a positive `angle` represents a particle rotating clockwise. In
this case. `g` will also be positive. For counterclockwise rotation, both `angle` and `g`
will be negative but the length `l` is always positive. Also, looking from above, a positive
`e1` represents a clockwise rotation of the entrance face and a positive `e2` represents a
counterclockwise rotation of the exit face. This is true irregardless of the sign of `angle` and
`g`. Also it is always the case that the pole faces will be parallel when
```{code} yaml
e1 + e2 = angle
```

%---------------------------------------------------------------------------------------------------
(s:descrip.g)=
## DescriptionParams
The components of this group are element descriptive strings:
```{code} yaml
type::String
ID::String
class::String
```
For example
```{code} yaml
@ele q1 = Quadrupole(type = "rotating quad", ...)
```

These strings can be used to in element searching:
```{code} yaml
eles(lat, "type = "*rot*")     # Can use these strings in searching
```
In this example `lat` is the lattice that contains `q1` and the `eles` function
will return a vector of all elements whose `type` string has the substring "`rot`"
in it.

%---------------------------------------------------------------------------------------------------
(s:dreference.g)=
## DownstreamReferenceParams
The components of this group are:
```{code} yaml
species_ref_downstream::Species  - Reference species.
pc_ref_downstream::Number        - Reference momentum*c.
E_tot_ref_downstream::Number     - Reference total energy.
```

Associated output parameters are:
```{code} yaml
β_ref_downstream::Number         - Reference v/c.
γ_ref_downstream::Number         - Reference relativistic gamma factor.
```

This group holds the reference energy and species at the downstream end of an element.
Also see the `ReferenceParams` ([](#s:reference.g)) documentation.
This group and `ReferenceParams` group are always paired.
That is, these two are always both present or both not present in any given element.

For most elements, the values of the parameters in `DownstreamReferenceParams` will
be the same as the values in the corresponding `ReferenceParams` parameters.
That is, the value of `species_ref_downstream` in `DownstreamReferenceParams` will be the same
as the value of `species_ref` in `ReferenceParams`, the value of `pc_ref_downstream`
will be the same as `pc_ref`, etc. Elements where the reference energy (here "energy" refers
to either pc_ref, E_tot_ref, β, or γ) differs between upstream and downstream
include `LCavity` and `Patch` elements.
Elements where the reference energy and species differ between upstream and downstream include
`Foil` and `Converter` elements.

Parameters of the `DownstreamReferenceParams` are not user settable and are
calculated by the AcceleratorLattice bookkeeping routines. See the `ReferenceParams` documentation
for how these parameters are calculated.

%---------------------------------------------------------------------------------------------------
(s:emultipole.g)=
## EMultipoleParams
The `EMultipoleParams` group stores electric multipole strengths. Also see `BMultipoleParams`.
The parameters of this group are:
```{code} yaml
vec::Vector{EMultipole1}
```
This group stores a vector of `EMultipole1` structs.
The `EMultipole1` structure stores the values for a electric multipole of a given order.
Only orders where there is a non-zero multipole are stored and there is no maximum limit to the
order that can be stored. The multipoles will be stored in increasing order.

The `EMultipole1` structure has components:
```{code} yaml
En::Number     - Normal field component.
Es::Number     - Skew field component.
Etilt::Number  - Rotation of multipole around z-axis.
order::Int     - Multipole order.
Eintegrated::Union{Bool,Nothing} - Integrated multipoles or not?
```
The `order` component gives the multipole order.
There is storage for unnormalized (`En` and `Es`) field strengths however, unlike magnetic
multipoles, there are no components for normalized field strengths.
The letter "`n`" designates the normal component and "`s`" designates the skew component.
There is also a `Etilt` component which will tilt the entire multipole [](#???).
The reason why the structure has three components,
normal, skew and tilt, that describe the field when only two would be sufficient is due convenience.
Having normal and skew components is convenient when magnet has multiple windings that control
both independently.

The dot selection operator for an element ([](#s:ele.access)) is overloaded so that
electric multipole parameters for order {math}`J` can be accessed using the following notation:
{tt
Need custom handling!!!!
Name         & Stored In   & Integrated & Description  midrule
EnJ          & En          & No         & Normal field. 
EsJ          & Es          & No         & Skew field. 
EnJL         & En          & Yes        & Normal field. 
EsJL         & Es          & Yes        & Skew field. 
EtiltJ       & Etilt       & --         & Field tilt. 
EintegratedJ & Eintegrated & --         & Integrated fields? 
bottomrule
Substitute the multipole order for {math}`J` in the above table. For example, `Es2L` is the
normalized length-integrated skew field component of order 2.

Notice that both integrated
and non-integrated fields are potentially stored in the same component of `EMultipole1`.
Which type is stored is determined by the `Eintegrated` logical. If `true`, the integrated
value is stored and vice versa. The `Eintegrated` setting can be different for different orders.
The setting of `Eintegrated` for a given order is determined by whether the first field component
to be set for that order is an integrated quantity or not. After the value of `Eintegrated` is set,
an error will be thrown if a something that has the opposite sense in terms of integration is
set. For example:
```{code} yaml
@ele qq = Quadrupole(l = 0.6, Es0L = 1.0)  # 0th order is integrated
qq.En1 = 0.3                  # 1st order multipole is not integrated
qq.Es1 = 0.5                  # This is OK.
println(qq.Eintegrated0)      # Will print "true"
println(qq.En0)               # Can use non-integrated component.
toggle_integrated!(qq, ELECTRIC, 0)  # change integrated setting for order 0.
```
In the above example, the 0th order multipole is initialized using `Es0L` so that
multipole will have the `Eintegrated` component set to `true` and non-integrated values
cannot be set. However, independent of the setting of `Eintegrated`, both integrated and
non-integrated quantities can always be used in an equation. To change the value of `Eintegrated`,
use the `toggle_integrated!` function. This function also translates the values stored in the
field components of the structure so that the field will stay constant.

The setting of `Eintegrated` for a given multipole will also determine what stays constant
of the length of the magnet changes. If `Eintegrated` is `true`, the integrated values
will be invariant with length changes and vice versa if `integrated` is `false`.
Similarly, the setting of the `field_master` parmeter ([](#s:master.g)) will determine
whether normalized or unnormalized quantities will stay constant if the reference energy is varied.

%---------------------------------------------------------------------------------------------------
(s:fork.g)=
## ForkParams
The components of this group are:
```{code} yaml
to_line::Union{BeamLine,Branch}   - Beam line to fork to
to_ele::Union{String,Ele}         - Element forked to.
direction::Int                    - Longitudinal Direction of injected beam.
propagate_reference::Bool         - Propagate reference species and energy?
```

This group is used with a `Fork` element and specifies how the fork element attaches to
another branch.

Propagate will be done initially, even with `propagate_reference` set to false, if the
reference species or reference energy is not set in beginning element of the forked to branch.

%---------------------------------------------------------------------------------------------------
(s:girder.g)=
## GirderParams
The components of this group are:
```{code} yaml
supported::Vector{Ele}    - Elements supported by girder.
```


%---------------------------------------------------------------------------------------------------
(s:init.particle.g)=
## InitParticleParams
The components of this group are:
```{code} yaml
orbit::Vector{Number}     - Phase space 6-vector.
spin::Vector{Number}      - Spin 3-vector. ```

%---------------------------------------------------------------------------------------------------
(s:length.g)=
## LengthParams
The components of this group are:
```{code} yaml
L::Number               - Length of element.
s::Number               - Starting s-position.
s_downstream::Number    - Ending s-position.
orientation::Int        - Longitudinal orientation. +1 or -1.
```

%---------------------------------------------------------------------------------------------------
(s:lord.slave.g)=
## LordSlaveStatusParamslabel{s:lord.enum}
label{s:slave.enum}

The components of this group are: 
```{code} yaml
lord_status::Lord.T     - Lord status.
slave_status::Slave.T   - Slave status.
```

The possible values of `lord_status` are:
- Lord.NOT  - Not a lord
- Lord.SUPER  - Is a Super lord (
- Lord.MULTIPASS  - Is a Multipass lord (

The possible values of `lord_status` are: 
- Slave.NOT  - Not a slave
- Slave.SUPER  - Is a Super slave (
- Slave.MULTIPASS  - Multipass slave (

All elements in a tracking branch have this element group even if the type of element (For example,
`Drift` elements) is such that the element will never be a lord or a slave.

Notice that elements that are supported by a `Girder` are not marked as slaves to the `Girder`
although the supported elements will have a pointer to the supporting girder.

This group is used in lattice element lord/slave bookkeeping ([](#c:lord.slave.book)). See this
section for more details.

%---------------------------------------------------------------------------------------------------
(s:master.g)=
## MasterParams
The components of this group are:
```{code} yaml
is_on::Bool = true
field_master::Bool = false         # Does field or normalized field stay constant with energy changes?
```

%---------------------------------------------------------------------------------------------------
(s:orientation.g)=
## FloorParams
The `FloorParams` stores the nominal (calculated without alignment shifts)
position and angular orientation in the floor coordinates of the upstream end of the element.
system. The components of this group are:
```{code} yaml
r::Vector          - [x,y,z] position. Accessed using `r_floor`
q::Quaternion      - Quaternion orientation. Accessed using `q_floor`.
```




%---------------------------------------------------------------------------------------------------
(s:origin.ele.g)=
## OriginEleParams
The components of this group are:
```{code} yaml
origin_ele::Ele           - Origin reference element. Default is NULL_ELE.
origin_ele_ref_pt::Loc.T  - Origin reference point. Default is Loc.CENTER.
```

The `OriginEleParams` is used with `Fiducial`, `FloorShift`, and `Girder` elements.
The `OriginEleParams` is used to set the coordinate reference frame from which
the orientation set by the `BodyShiftParams` is measured. To specify that the floor coordinates are
to be used, set the `origin_ele` to `NULL_ELE`. Typically this is the same as using the
beginning element of the first branch of a lattice as long as the first element does not have
any orientation shifts.


%---------------------------------------------------------------------------------------------------
(s:patch.g)=
## PatchParams
```{figure} figures/patch.svg
caption[Patch Element.]
{A) A `patch` element can align its exit face arbitrarily with respect to its entrance face. The
red arrow illustrates a possible particle trajectory form entrance face to exit face. B) The
reference length of a `patch` element, if `ref_coords` is set to the default value of
`exit_end`, is the longitudinal distance from the entrance origin to the exit origin using the
reference coordinates at the exit end as shown. If `ref_coords` is set to `entrance_end`, the
length of the patch will be equal to the `z_offset`.}
:name: f:patch
```

The components of this group are:
```{code} yaml
t_offset::Number          - Time offset.
E_tot_offset::Number      - Total energy offset. Default is NaN (not used).
E_tot_exit::Number        - Fix total energy at exit end. Default is NaN (not used).
pc_exit::Number           - Reference momentum*c at exit end. Default is NaN (not used).
flexible::Bool            - Flexible patch? Default is false.
L_user::Number            - User set Length? Default is NaN (length calculated by bookkeeping code).
ref_coords::BodyLoc.T     - Reference coordinate system used inside the patch. Default is BodyLoc.EXIT_END.
```

A straight line element like a `drift` or a `quadrupole` has the exit face parallel to the
entrance face. With a `patch` element, the entrance and exit faces can be arbitrarily oriented
with respect to one another as shown in {numref}`f:patch`A.

index{rigid patch}index{inflexible patch}
index{flexible patch}
There are two different ways the orientation of the exit face is determined. Which way is used is
determined by the setting of the `flexible` attribute.  With the `flexible` attribute set to
`False`, the default, The exit face of the `patch` will be determined from the offset, tilt
and pitch attributes as described in [](#s:patch.coords). This type of `patch` is called
"rigid" or "inflexible" since the geometry of the `patch` is solely determined by the
`patch`'s attributes as set in the lattice file and is independent of everything else. Example:
```{code} yaml
pt: patch, z_offset = 3.2   ! Equivalent to a drift
```

With `flexible` set to `True`, the exit face is taken to be the reference frame of the
entrance face of the next element in the lattice. In this case, it must be possible to compute the
reference coordinates of the next element before the reference coordinates of the `patch` are
computed. A `flexible` `patch` will have its offsets, pitches, and tilt as dependent
parameters ([](#s:depend)) and these parameters will be computed appropriately. Here the
`patch` is called "flexible" since the geometry of the patch will depend upon the geometry of
the rest of the lattice and, therefore, if the geometry of the rest of the lattice is modified (is
"flexed"), the geometry of the `patch` will vary as well. See Section~[](#s:ex.erl) for an
example.

The coordinates of the lattice element downstream of a `flexible` `patch` can be computed
if there is a `fiducial` element ([](#s:fiducial)) somewhere downstream or if there is a
`multipass_slave` ([](#c:multipass)) element which is just downstream of the `patch` or at
most separated by zero length elements from the `patch`. In this latter case, the
`multipass_slave` must represent an {math}`N`Th pass slave with {math}`N` greater than 1. This works since
the first pass slave will be upstream of the `patch` and so the first pass slave will have its
coordinates already computed and the position of the downstream slave will be taken to be the same
as the first pass slave. Notice that, without the `patch`, the position of multipass slave
elements are independent of each other.

With `bmad_standard` tracking ([](#s:tkm)) A particle, starting at the upstream face of the
`patch`, is propagated in a straight line to the downstream face and the suitable coordinate
transformation is made to translate the particle's coordinates from the upstream coordinate frame to
the downstream coordinate frame ([](#s:patch.std)). In this case the `patch` element can be
thought of as a generalized `drift` element.

If there are magnetic or electric fields within the `patch`, the tracking method through the
`patch` must be set to either `runge_kutta` or `custom`. Example:
```{code} yaml
pa2: patch, tracking_method = runge_kutta, field_calc = custom,
mat6_calc_method = tracking, ...
```
In order to supply a custom field when `runge_kutta` tracking is used, `field_calc`
([](#s:integ)) needs to be set to `custom`. In this case, custom code must be supplied for
calculating the fields as a function of position ([](#s:custom.ele)).

The `E_tot_offset` attribute offsets the
reference energy:
```{code} yaml
E_tot_ref(exit) = E_tot_ref(entrance) + E_tot_offset (eV)
```
Setting the `E_tot_offset` attribute will affect a particle's {math}`p_x`, {math}`p_y` and {math}`p_z` coordinates
via Eqs{ppp} and eq{ppppp}.  Notice that `E_tot_offset` does not affect a particle's actual
energy, it just affects the difference between the particle energy and the reference energy.

Alternatively, to set the reference energy, the `E_tot_set` or `p0c_set` attributes can be
used to set the reference energy/momentum at the exit end. It is is an error if more than one of
`E_tot_offset`, `E_tot_set` and `p0c_set` is nonzero.

`Important`: Bmad may apply the energy transformation either before or after the coordinate
transformation. This matters when the speed of the reference particle is less than {math}`c`. For this
reason, and due to complications involving PTC, it is recommended to use two patches in a row when
both the orbit and energy are to be patched.

A `patch` element can have an associated electric or magnetic field ([](#s:fieldmap)). This can
happen, for example, if a patch is used at the end of an injection line to match the reference
coordinates of the injection line to the line being injected into ([](#s:ex.inj)) and the patch
element is within the field generated by an element in the line being injected into. In such a case,
it can be convenient to set what the reference coordinates are since the orientation of any fields
that are defined for a patch element will be oriented with respect to the patch element's reference
coordinates. For this, the `ref_coords`
parameter of a patch can be used. Possible settings are:
`ref_coords` are:
```{code} yaml
entrance_end  !
exit_end      ! Default
```
The default setting of `ref_coords` is `exit_end` and with this the reference coordinates are
set by the exit end coordinate system (see {numref}`f:patch`). If `ref_coords` is set to
`entrance_end`, the reference coordinates are set by the entrance end coordinate system. Example:
```{code} yaml
p1: patch, x_offset = 1, x_pitch = 0.4   ! L = 0.289418 see below
p2: p1, ref_coords = entrance_end        ! L = 0
```
Here `p1` has `ref_coords` set to `exit_end` (the default). `p2` inherits the parameters
of `p1` and sets `ref_coords` to `entrance_end`.

It is important to keep in mind that if there are multiple patches in a row, while two different
configurations may be the same in a geometrical sense the total length may not be the same. For
example:
```{code} yaml
pA: patch, x_offset = 1    ! L = 0
pB: patch, x_pitch = 0.4   ! L = 0
sum: line = (pA, pB)
```
The configuration of `pA` followed by `pB` is equivalent geometrically to the `p1` patch
above but the total length of the `(pA, pB)` line is zero which is different from the length of
`p1`.

Unfortunately, there is no intuitive way to define the "`length`" `L` of a patch. This is
important since the transit time of the reference particle is the element length divided by the
reference velocity. And the reference transit time will affect how the phase space {math}`z` coordinate
changes through the patch via Eq{zbctt}. If the parameter `user_sets_length` is set to True, the
value of `l` set in the lattice file will be used (default is zero). `user_sets_length` is set
to False (the default), the length of a patch is calculated depending upon the setting of
`ref_coords`.  If `ref_coords` is set to `exit_end`, the length of the patch is calculated
as the perpendicular distance between the origin of the patch's entrance coordinate system and the
exit face of the patch as shown in {numref}`f:patch`B. If `ref_coords` is set to `entrance_end`,
the length is calculated as the perpendicular distance between the entrance face and the origin of
the exit coordinate system. In this case, the length will be equal to `z_offset`.

To provide flexibility, the `t_offset` attribute can be
used to offset the reference time. The reference time at the exit end of the patch
`t_ref(exit)` is related to the reference time at the beginning of the patch `t_ref(entrance)`
via
```{code} yaml
t_ref(exit) = t_ref(entrance) + t_offset + dt_travel_ref
```
where `dt_travel_ref` is the time for the reference particle to travel through the patch.
`dt_travel_ref` is defined to be:
```{code} yaml
dt_travel_ref = L / beta_ref
```
Where `L` is the length of the `patch` and `beta_ref` is the reference velocity/c at the
exit end of the element. That is, the reference energy offset is applied {em before} the reference
particle is tracked through the patch. Since this point can be confusing, it is recommended that a
`patch` element be split into two consecutive patches if the `patch` has finite `l` and
`E_tot_offset` values.

While a finite `t_offset` will affect the reference time at the end of a patch, a finite
`t_offset` will {em not} affect the time that is calculated for a particle to reach the end of
the patch. On the other hand, a finite `t_offset` will affect a particle's {math}`z` coordinate via
Eqs{zbctt}. The change in {math}`z`, {math}`delta z` will be
begin{equation}
delta z = beta cdot c cdot text{t_offset}
end{equation}
where {math}`beta` is the normalized particle speed (which is independent of any energy patch). Another
way of looking at this is to note that In a drift, if the particle is on-axis and on-energy, t and
t_ref change but z does not change. In a time patch (a patch with only `t_offset` finite), t_ref
and z change but t does not.

When a lattice branch contains both normally oriented and reversed elements
([](#s:ref.construct)), a `patch`, or series of `patches`, which reflects the {math}`z` direction
must be placed in between. Such a `patch`, (or patches) is called a `reflection` `patch`.
See Section~[](#s:reflect.patch) for more details on how a reflection patch is defined. In order
to avoid some confusing conceptual problems involving the coordinate system through a reflection
patch, Runge-Kutta type tracking is prohibited with a reflection patch.footnote
{
In general, Runge-Kutta type tracking through a patch is a waste of time unless electric or magnetic
fields are present.

index{wall}
Since the geometry of a `patch` element is complicated, interpolation of the chamber wall in the
region of a patch follows special rules. See section~[](#s:wall.vacuum) for more details.



%---------------------------------------------------------------------------------------------------
(s:rf.g)=
## RFParams
The components of this group are:
```{code} yaml
frequency::Number         - RF frequency.
harmon::Number            - RF frequency harmonic number.
voltage::Number           - RF voltage.
gradient::Number          - RF gradient.
phase::Number             - RF phase.
multipass_phase::Number   - RF Phase added to multipass elements.
cavity_type::Cavity.T     - Cavity type. Default is Cavity.STANDING_WAVE.
n_cell::Int               - Number of cavity cells. Default is 1.
```


Whether `voltage` or `gradient` is kept constant with length changes is determined by
the setting of `field_master` ([](#s:master.g)). If `field_master` is `true`, the
`gradient` is kept constant and vice versa.

%---------------------------------------------------------------------------------------------------
(s:rfauto.g)=
## RFAutoParams
The components of this group are:
```{code} yaml
do_auto_amp::Bool           - Will autoscaling set auto_amp? Default is true.
do_auto_phase::Bool         - Will autoscaling set auto_phase? Default is true.
auto_amp::Number            - Auto RF field amplitude scale value.
auto_phase::Number          - Auto RF phase value.
```

%---------------------------------------------------------------------------------------------------
(s:reference.g)=
## ReferenceParams
The components of this group are:
```{code} yaml
species_ref::Species          - Reference species entering end.
pc_ref::Number                - Reference momentum*c upstream end.
E_tot_ref::Number             - Reference total energy upstream end.
time_ref::Number              - Reference time upstream end.
time_ref_downstream::Number   - Reference time downstream end.
extra_dtime_ref::Number       - User set reference time change.
dE_ref::Number                - Sets change in reference energy.
```

Associated output parameters are:
```{code} yaml
β_ref::Number                 - Reference v/c upstream end.
γ_ref::Number                 - Reference relativistic gamma factor.
```

This group holds the reference energy, species, and time parameters at the upstream
end of a lattice element.
Also see the `DownstreamReferenceParams` group documentation ([](#s:dreference.g)).
The `DownstreamReferenceParams` group holds the reference energy and species
at the downstream end of the element.
This group and `DownstreamReferenceParams` group are always paired.
That is, these two are always both present or both not present in any given element.

For a `Beginning` element, parameters of this group are user settable except for the
`dvoltage_ref` parameter. For all other element types, except for `dvoltage_ref` and
`extra_dtime_ref`, the parameters of this
group are calculated by the AcceleratorLattice bookkeeping routines and are not user settable.

For most elements, the values of the parameters in `DownstreamReferenceParams` will
be the same as the values in the corresponding `ReferenceParams` parameters.
That is, the value of `species_ref_downstream` in `DownstreamReferenceParams` will be the same
as the value of `species_ref` in `ReferenceParams`, the value of `pc_ref_downstream`
will be the same as `pc_ref`, etc. Elements where the reference energy (here "energy" refers
to either pc_ref, E_tot_ref, β, or γ) differs between upstream and downstream are elements with
a non-zero `dvoltage_ref` and include `LCavity` and `Patch` elements.
Elements where the reference energy and species differ between upstream and downstream include
`Foil` and `Converter` elements.

For elements where `dvoltage_ref` is nonzero the downstream reference energy
`E_tot_ref_downstream` is calculated from the upstream `E_tot_ref` via the equation
```{code} yaml
E_tot_ref_downstream = E_tot_ref + dvoltage_ref * |Q_ref|
```
where `|Q_ref|` is the magnitude of the charge of the reference particle in units of the
fundamental charge. Once `E_tot_ref_downstream` has been calculated, the downstream values
of pc, β, and γ are calculated using the standard formulas. Notice that `dvoltage_ref` is
completely independent from the actual voltage seen by a particle which is set by the `voltage`
parameter of the `RFParams`.

The downstream reference time `time_ref_downstream` is calculated via
```{code} yaml
time_ref_downstream = time_ref + transit_time + extra_dtime_ref
```
where `transit_time` is the time to transit the element assuming a straight line trajectory
and a linear energy change throughout the element. . The general formula
for the transit time is
```{code} yaml
transit_time = L * (E_tot_ref + E_tot_ref_downstream) / (c * (pc_ref + pc_ref_downstream))
```
where `L` is the length of the element and `c` is the speed of light.
For elements where there is no energy
change (`dvoltage_ref` = 0), the transit time calculation simplifies to
```{code} yaml
transit_time = L / (β_ref * c)
```

The `extra_dtime_ref` parameter in the above is ment as a correction to take into account
for particle motion that is not straight or acceleration that is not linear in energy. For example,
in a wiggler, `extra_dtime_ref` can be used to correct for the oscillatory nature of the
particle trajectories.
Since AcceleratorLattice does not do tracking (see the discussion in [](#c:design)), `extra_dtime_ref`
must be calculated by the User.


%---------------------------------------------------------------------------------------------------
(s:solenoid.g)=
## SolenoidParams
The components of this group are:
```{code} yaml
Ksol::Number        - Normalized solenoid strength.
Bsol::Number        - Solenoid field.
```

%---------------------------------------------------------------------------------------------------
(s:tracking.g)=
## TrackingParams
The components of this group are:
```{code} yaml
num_steps::Int    - Number of steps.
ds_step::Number   - Step length.
```

%---------------------------------------------------------------------------------------------------
(s:twiss.g)=
## TwissParams
In development

The components of this group are:
```{code} yaml

aaa
```


```{footbibliography}
```
