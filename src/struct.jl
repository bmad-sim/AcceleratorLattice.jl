#---------------------------------------------------------------------------------------------------
# Defines the types used throughout the package.

#---------------------------------------------------------------------------------------------------
# BeamLineItem

"""
    abstract type BeamLineItem

Abstract type for stuff that can be in a beam line. Subtypes are:

    BeamLine
    BeamLineEle
    Branch
    Ele
""" BeamLineItem

abstract type BeamLineItem end

#---------------------------------------------------------------------------------------------------
# Ele

"""
    abstract type Ele <: BeamLineItem end

Abstract type from which all concrete lattice element types inherit.
All concreate lattice element types are constructed using the `@construct_ele_type` macro.

All concreate lattice element types have a single field:

    pdict :: Dict{Symbol, Any}
""" Ele
 
abstract type Ele <: BeamLineItem end

#---------------------------------------------------------------------------------------------------
# Eles

"""
    Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}

Single element or vector of elemements."
""" Eles

Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}


Base.collect(x::T) where T <: Ele = [x]

#---------------------------------------------------------------------------------------------------
# construct_ele_type

"""
    macro construct_ele_type(type_name, doc::String) -> nothing
    ELE_TYPE_INFO = Dict{DataType,String}()

Constructor for element types and a Dict for storing a descriptive string. Example:
```
    @construct_ele_type Drift  "Field free region."
```
Result: `Drift` struct is defined and `ELE_TYPE_INFO[Drift]` holds the `doc` string.
""" construct_ele_type, ELE_TYPE_INFO

ELE_TYPE_INFO = Dict{DataType,String}()

macro construct_ele_type(type_name, doc::String)
  eval( Meta.parse("mutable struct $type_name <: Ele; pdict::Dict{Symbol,Any}; end") )
  str_type = String("$type_name")
  eval( Meta.parse("export $str_type") )
  eval( Meta.parse("ELE_TYPE_INFO[$type_name] = \"$doc\""))
  return nothing
end

#---------------------------------------------------------------------------------------------------
# @ele macro

"""
    macro ele(expr)

Element constructor Example:
    @ele q1 = Quadrupole(L = 0.2, Ks1 = 0.67, ...)
Result: The variable `q1` is a `Quadrupole` with the argument values put the the appropriate place.

Note: All element parameter groups associated with the element type will be constructed. Thus, in the
above example,`q1` above will have `q1.LengthGroup` (equivalent to `q1.pdict[:LengthGroup]`) created.
"""
macro ele(expr)
  expr.head == :(=) || error("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\"")
  name = expr.args[1]
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :name, "$name"))))
  return esc(expr)   # This will call the lattice element constructor below
end

#---------------------------------------------------------------------------------------------------
# @eles macro

"""
    macro eles(block)

Constructs elements for all elements on each line in a block. Equivalent to applying the 
@ele macro to each line.

### Example:
```
@eles begin
q1 = Quadrupole(L = 0.2, Ks1 = 0.67)
q2 = Quadrupole(L = 0.6, Kn1 = -0.3)

d = Drift(L = 0.2)
end
```
"""
macro eles(block)
  block.head == :block || error("@eles must be followed by a block!")
  eles = filter(x -> !(x isa LineNumberNode), block.args)
  for ele in eles
    name = ele.args[1]
    insert!(ele.args[2].args, 2, :($(Expr(:kw, :name, "$name"))))
  end
  return esc(block)
end

#---------------------------------------------------------------------------------------------------
# Element construction function. Called by `ele` macro.

"""
    function (::Type{T})(; kwargs...) where T <: Ele


Lattice element constructor.
The constructor initializes `Ele.pdict[:branch]` since it is assumed by the
bookkeeping code to always exist.
"""
function (::Type{T})(; kwargs...) where T <: Ele
  ele = T(Dict{Symbol,Any}(:branch => nothing))
  pdict = ele.pdict
  pdict[:changed] = Dict{Union{Symbol,DataType},Any}()

  # Setup parameter groups.
  for group in PARAM_GROUPS_LIST[typeof(ele)]
    pdict[Symbol(group)] = group()
  end

  # Put name in first in case there are errors and the ele name needs to be printed.
  if haskey(kwargs, :name)
    pdict[:name] = kwargs[:name]
  else
    pdict[:name] = "Not Set!"
  end

  # Put parameters in parameter groups and changed area
  for (sym, val) in kwargs
    if sym == :name; continue; end
    Base.setproperty!(ele, sym, val)
  end

  return ele
end

#---------------------------------------------------------------------------------------------------
# Construct ele types

@construct_ele_type ACKicker            "Time varying kicker."
@construct_ele_type BeamBeam            "Colliding beam element."
@construct_ele_type BeginningEle        "Initial element at start of a branch."
@construct_ele_type Bend                "Dipole bend."
@construct_ele_type Collimator          "Collimation element."
@construct_ele_type Converter           "Target to produce new species. EG: Positron converter."
@construct_ele_type CrabCavity          "RF crab cavity." 
@construct_ele_type Drift               "Field free region."
@construct_ele_type EGun                "Electron gun."
@construct_ele_type Fiducial            "Floor coordinate system fiducial point."
@construct_ele_type FloorShift          "Floor coordinates shift."
@construct_ele_type Foil                "Strips electrons from an atom."
@construct_ele_type Fork                "Connect lattice branches together."
@construct_ele_type Girder              "Support element."
@construct_ele_type Instrument          "Measurement element."
@construct_ele_type Kicker              "Particle kicker element."
@construct_ele_type LCavity             "Linac accelerating RF cavity."
@construct_ele_type Marker              "Zero length element to mark a particular position."
@construct_ele_type Match               "Orbit, Twiss, and dispersion matching element."
@construct_ele_type Multipole           "Zero length multipole."
@construct_ele_type NullEle             "Placeholder element used for bookkeeping."
@construct_ele_type Octupole            "Octupole element."
@construct_ele_type Patch               "Reference orbit shift."
@construct_ele_type Quadrupole          "Quadrupole element."
@construct_ele_type RFCavity            "RF cavity element."
@construct_ele_type Sextupole           "Sextupole element."
@construct_ele_type Solenoid            "Solenoid."
@construct_ele_type Taylor              "General Taylor map element."
@construct_ele_type Undulator           "Undulator."
@construct_ele_type UnionEle            "Container element for overlapping elements." 
@construct_ele_type Wiggler             "Wiggler."

"""
NullEle lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is a const NullEle element with `name` set to "null" that can be used for coding.
"""
const NULL_ELE = NullEle(Dict{Symbol,Any}(:name => "NULL_ELE"))

#---------------------------------------------------------------------------------------------------
# BeamLineEle

"""
    mutable struct BeamLineEle <: BeamLineItem

An item in a `BeamLine.line[]` array that represents a lattice element.

## Fields
• `ele::Ele` \\
• `pdict::Dict{Symbol,Any}` \\

Essentially, `BeamLineEle` is an `Ele` along with some extra information stored in the `pdict` Dict
component. The extra information is the element's orientation and multipass state.

Note: All instances a given Ele in beamlines are identical so that the User can easily 
make a Change to all. When the lattice is expanded, deepcopyies of Eles will be done.
"""
mutable struct BeamLineEle <: BeamLineItem
  ele::Ele
  pdict::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
# BeamLine

"""
    mutable struct BeamLine <: BeamLineItem

Structure holding a beamline.

## Fields

• `id::String`                  - ID stringused for multipass bookkeeping. \\
• `line::Vector{BeamLineItem}`  - Vector of beam line components. \\
• `pdict::Dict{Symbol,Any}`     - Extra information. See below. \\

Standard components of `pdict` are:
• `name`          - String to be used for naming the lattice branch if this is a root branch. \\
• `orientation`   - +1 or -1. \\
• `geometry`      - `OPEN` or `CLOSED`. \\
• `multipass`     - `true` or `false`. \\
"""
mutable struct BeamLine <: BeamLineItem
  id::String
  line::Vector{BeamLineItem}
  pdict::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
# EleParameterGroupInfo

"""
    Internal: struct EleParameterGroupInfo

Struct holding information on a single `EleParameterGroup` group.
Used in constructing the `ELE_PARAM_GROUP_INFO` Dict.

## Contains
• `description::String`      - Descriptive string. \\
• `bookkeeping_needed::Bool  - If true, this indicates there exists a bookkeeping function for the \\
  parameter group that needs to be called if a parameter of the group is changed. \\
"""
struct EleParameterGroupInfo
  description::String
  bookkeeping_needed::Bool
end

#---------------------------------------------------------------------------------------------------
# EleParameterGroup

"""
    abstract type BaseEleParameterGroup
    abstract type EleParameterGroup <: BaseEleParameterGroup
    abstract type EleParameterSubGroup <: BaseEleParameterGroup

`EleParameterGroup` is the base type for all element parameter groups.
`EleParameterSubGroup` is the base type for structs that are used as components of an element
parameter group.

To see in which element types contain a given parameter group, use the `info(::EleParameterGroup)`
method. To see what parameter groups are contained in a Example:
```
    info(AlignmentGroup)      # List element types that contain AlignmentGroup
```
""" BaseEleParameterGroup, EleParameterGroup, EleParameterSubGroup

abstract type BaseEleParameterGroup end
abstract type EleParameterGroup <: BaseEleParameterGroup end
abstract type EleParameterSubGroup <: BaseEleParameterGroup end

#---------------------------------------------------------------------------------------------------
# BMultipole subgroup

"""
    mutable struct BMultipole <: EleParameterSubGroup

Single magnetic multipole of a given order.
Used by `BMultipoleGroup`.

## Fields

• `Kn::Number`                 - Normal normalized component. EG: `"Kn2"`, `"Kn2L"`. \\
• `Ks::Number`                 - Skew multipole component. EG: `"Ks2"`, `"Ks2L"`.  \\
• `Bn::Number`                 - Normal field component. \\ 
• `Bs::Number`                 - Skew field component. \\
• `tilt::Number`               - Rotation of multipole around `z`-axis. \\
• `order::Int`                 - Multipole order. \\
• `integrated::Union{Bool,Nothing}` - Integrated or not? \\
  Also determines what stays constant with length changes. \\
"""
@kwdef mutable struct BMultipole <: EleParameterSubGroup  # A single multipole
  Kn::Number = 0.0                 # EG: "Kn2", "Kn2L" 
  Ks::Number = 0.0                 # EG: "Ks2", "Ks2L"
  Bn::Number = 0.0
  Bs::Number = 0.0  
  tilt::Number = 0.0
  order::Int   = -1                # Multipole order
  integrated::Union{Bool,Nothing} = nothing  # Also determines what stays constant with length changes.
end

#---------------------------------------------------------------------------------------------------
# Dispersion subgroup

"""
Dispersion parameters for a single axis.

""" Dispersion1

@kwdef mutable struct Dispersion1 <: EleParameterSubGroup
  eta::Number = 0           # Position dispersion.
  etap::Number = 0          # Momentum dispersion.
  deta_ds::Number = 0       # Dispersion derivative.
end

#---------------------------------------------------------------------------------------------------
# EMultipole

"""
    mutable struct EMultipole <: EleParameterSubGroup

Single electric multipole of a given order.
Used by `EMultipoleGroup`.

## Fields

• `En::Number`                  - Normal field component. EG: "En2", "En2L" \\
• `Es::Number`                  - Skew fieldEG component. EG: "Es2", "Es2L" \\
• `Etilt::Number`               - Rotation of multipole around `z`-axis. \\
• `order::Int`                  - Multipole order. \\
• `Eintegrated::Bool`           - Integrated field or not?. \\
  Also determines what stays constant with length changes. \\
""" EMultipole

@kwdef mutable struct EMultipole <: EleParameterSubGroup
  En::Number = 0.0                    # EG: "En2", "En2L"
  Es::Number = 0.0                    # EG: "Es2", "Es2L"
  Etilt::Number = 0.0
  order::Int = -1 
  Eintegrated::Union{Bool,Nothing} = nothing
end

#---------------------------------------------------------------------------------------------------
# Twiss subgroup.

@kwdef mutable struct Twiss <: EleParameterSubGroup
  beta_a::Number = 0
  alpha_a::Number = 0
  beta_b::Number = 0
  alpha_b::Number = 0
end

#---------------------------------------------------------------------------------------------------
# Twiss1 subgroup

"""
    mutable struct Twiss1 <: EleParameterSubGroup

Twiss parameters for a single mode.

""" Twiss1

@kwdef mutable struct Twiss1 <: EleParameterSubGroup
  beta::Number = 0          # Beta Twiss
  alpha::Number = 0         # Alpha Twiss
  gamma::Number = 0         # Gamma Twiss
  phi::Number = 0           # Phase
  eta::Number = 0           # Position dispersion.
  etap::Number = 0          # Momentum dispersion.
  deta_ds::Number = 0       # Dispersion derivative.
end

#---------------------------------------------------------------------------------------------------
# Vertex1 subgroup

"""
  struct Vertex1 <: EleParameterSubGroup

Single vertex. An array of vertices can be used to construct an aperture.
If `radius_x`, and `radius_y` )and possibly `tilt`) are set, this specifies the shape of the elliptical arc
of the chamber wall from the vertex point to the next vertex point. 
If not set, the chamber wall from the vertex to the next vertex is a straight line.

## Fields
• `r0::Vector{Number}`     - (x, y) coordinate of vertex point. \\
• `radius_x::Number`      - Horizontal ellipse radius. \\
• `radius_y::Number`      - Vertical ellipse radius. \\
• `tilt::Number`          - Tilt of ellipse. \\
""" Vertex1

@kwdef mutable struct Vertex1 <: EleParameterSubGroup
  r0::Vector{Number} = [NaN, NaN]
  radius_x::Number = NaN
  radius_y::Number = NaN
  tilt::Number = NaN
end

Vertex1(r0::Vector{Number}, rx::Number = NaN, ry::Number = NaN) = 
                                 Vertex1(r0 = r0, radius_x = rx, radius_y = ry, NaN)

#---------------------------------------------------------------------------------------------------
# Wall2D subgroup

"""
    mutable struct Wall2D <: EleParameterSubGroup

Vacuum chamber wall cross-section.

## Fields
• `vertex::Vector{Vertex1}` - Array of vertices. \\
• `r0::Vector{Number}`      - Origin point. \\
""" Wall2D

@kwdef mutable struct Wall2D <: EleParameterSubGroup
  vertex::Vector{Vertex1} = Vector{Vertex1}()
  r0::Vector{Number} = [0.0, 0.0]
end

Wall2D(v::Vector{Vertex1}) = Wall2D(v, [0.0, 0.0])

#---------------------------------------------------------------------------------------------------
# AlignmentGroup

"""
    mutable struct AlignmentGroup <: EleParameterGroup

Orientation of an element. 

- For `Patch` elements this is the orientation of the exit face with respect to the entrance face.
- For `FloorShift` and `Fiducial` elements this is the orientation of the element with respect
  to the reference element.
- For other elements this is the orientation of element body alignmnet point with respect to 
the supporting girder if it exists or with respect to the machine coordinates.

## Fields
• `offset::Vector`         - [x, y, z] offsets not including any Girder . \\
• `x_rot::Number`          - Rotation around the x-axis not including any Girder alignment shifts.  \\
• `y_rot::Number`          - Rotation around the y-axis not including any Girder misalignments. \\
• `tilt::Number`           - Rotation around the z-axis not including any Girder misalignment. \\

# Associated Output Parameters
The `tot` parameters are defined only for elements that can be supported by a `Girder`.
These parameters are the body coordinates with respect to machine coordinates. 
These parameters are calculated by `AcceleratorLattice` and will be equal to the corresponding
non-tot fields if there is no `Girder`.
• `offset_tot::Vector`     - [x, y, z] offsets including Girder alignment shifts. \\
• `x_rot_tot::Number`      - Rotation around the x-axis including Girder misalignment. \\
• `y_rot_tot::Number`      - Rotation around the z-axis including Girder misalignment. \\
• `tilt_tot::Number`       - Rotation around the z-axis including Girder misalignment. \\
""" AlignmentGroup

@kwdef mutable struct AlignmentGroup <: EleParameterGroup
  offset::Vector = [0.0, 0.0, 0.0] 
  x_rot::Number = 0
  y_rot::Number = 0
  tilt::Number = 0
end

#---------------------------------------------------------------------------------------------------
# ApertureGroup

"""
    struct ApertureGroup <: EleParameterGroup

Vacuum chamber aperture struct.

## Fields
• `x_limit::Vector`                     - `[x-, x+]` Limits in x-direction. \\
• `y_limit::Vector`                     - `[y-, y+]` Limits in y-direction. \\
• `wall::Wall2D`                        - Aperture defined by an array of vertices. \\
• `aperture_shape::ApertureShape.T`     - Aperture shape. Default is `ApertureShape.ELLIPTICAL`. \\
• `aperture_at::BodyLoc.T`              - Where aperture is. Default is `BodyLoc.ENTRANCE_END`. \\
• `misalignment_moves_aperture::Bool`   - Do element misalignments move the aperture? Default is false. \\
• `custom_aperture::Dict`               - Custom aperture information. \\
""" ApertureGroup

@kwdef mutable struct ApertureGroup <: EleParameterGroup
  x_limit::Vector = [-Inf, Inf]
  y_limit::Vector = [-Inf, Inf]
  aperture_shape::typeof(ApertureShape) = ELLIPTICAL
  aperture_at::BodyLoc.T = BodyLoc.ENTRANCE_END
  wall::Wall2D = Wall2D()
  misalignment_moves_aperture::Bool = false
  custom_aperture::Dict = Dict()
end

#---------------------------------------------------------------------------------------------------
# BeamBeamGroup

#### This is incomplete ####

"""
    mutable struct BeamBeamGroup <: EleParameterGroup

## Fields
• `n_slice::Number`          - Number of slices the Strong beam is divided into. \\
• `n_particle::Number`       - Number of particle in the strong beam. \\
• `species::Species`         - Strong beam species. Default is weak particle species. \\
• `z0_crossing::Number`      - Weak particle phase space z when strong beam center.  \\
                             -   passes the BeamBeam element. \\
• `repetition_freq::Number`  - Strong beam repetition rate. \\
• `twiss::Twiss`             - Strong beam Twiss at IP. \\
• `sig_x::Number`            - Strong beam horizontal sigma at IP. \\
• `sig_y::Number`            - Strong beam vertical sigma at IP. \\
• `sig_z::Number`            - Strong beam longitudinal sigma. \\
• `bbi_constant::Number`     - BBI constant. Set by Bmad. See manual. \\
""" BeamBeamGroup

@kwdef mutable struct BeamBeamGroup <: EleParameterGroup
  n_slice::Number = 1
  n_particle::Number = 0
  species::Species = Species()
  z0_crossing::Number = 0       # Weak particle phase space z when strong beam Loc.CENTER passes
                                #   the BeamBeam element.
  repetition_freq::Number = 0  # Strong beam repetition rate.
  twiss::Twiss = Twiss()        # Strong beam Twiss at IP.
  sig_x::Number = 0
  sig_y::Number = 0
  sig_z::Number = 0
  bbi_constant::Number = 0      # Will be set by Bmad. See manual.
end

#---------------------------------------------------------------------------------------------------
# BendGroup

"""
    mutable struct BendGroup <: EleParameterGroup

## Fields
• `bend_type::BendType.T`     - Is e or e_rect fixed? 
  Also is len or len_chord fixed? Default is `BendType.SECTOR`. \\
• `angle::Number`             - Reference bend angle. \\
• `g::Number`                 - Reference coordinates bend curvature. \\
• `bend_field_ref::Number`    - Reference bend field. \\
• `L_chord::Number`           - Chord length. \\
• `tilt_ref::Number`          - Tilt angle of reference (machine) coordinate system. \\
• `e1::Number`                - Pole face rotation at the entrance end with respect to a sector geometry. \\
• `e2::Number`                - Pole face rotation at the exit end with respect to a sector geometry. \\
• `e1_rect::Number`           - Pole face rotation with respect to a rectangular geometry. \\
• `e2_rect::Number`           - Pole face rotation with respect to a rectangular geometry. \\
• `edge_int1::Number`         - Field integral at entrance end. \\
• `edge_int2::Number`         - Field integral at exit end. \\
• `exact_multipoles::ExactMultipoles.T` - Field multipoles treatment. Default is `ExactMultipoles.OFF`. \\

## Output Parameters
• `rho::Number`               - Reference bend radius. \\ 
• `L_sagitta::Number`         - Sagitta length of bend semi circle. \\
• `bend_field::Number`        - Actual bend field in the plane of the bend. \\
• `norm_bend_field::Number`   - Actual bend strength in the plane of the bend. \\

## Notes
For tracking there is no distinction made between sector like (`BendType.SECTOR`) bends and
rectangular like (`BendType.RECTANGULAR`) bends. The `bend_type` switch is only important when the
bend angle or length is varied. See the documentation for details.

Whether `bend_field_ref` or `g` is held constant when the reference energy is varied is
determined by the `field_master` setting in the MasterGroup struct.
""" BendGroup

@kwdef mutable struct BendGroup <: EleParameterGroup
  bend_type::BendType.T = BendType.SECTOR 
  angle::Number = 0.0
  g::Number = 0.0           
  bend_field_ref::Number = 0.0
  L_chord::Number = 0.0
  tilt_ref::Number = 0.0
  e1::Number = 0.0
  e2::Number = 0.0
  e1_rect::Number = 0.0
  e2_rect::Number = 0.0
  edge_int1::Number = 0.5
  edge_int2::Number = 0.5
  exact_multipoles::ExactMultipoles.T = ExactMultipoles.OFF
end

#---------------------------------------------------------------------------------------------------
# BMultipoleGroup

"""
    mutable struct BMultipoleGroup <: EleParameterGroup

Vector of magnetic multipoles.

## Field
• `pole::Vector{BMultipole}` - Vector of multipoles. \\

"""
@kwdef mutable struct BMultipoleGroup <: EleParameterGroup
  pole::Vector{BMultipole} = Vector{BMultipole}(undef,0)         # Vector of multipoles.
end

#---------------------------------------------------------------------------------------------------
# DescriptionGroup

"""
    mutable struct DescriptionGroup <: EleParameterGroup

Strings that can be set and used with element searches.
These strings have no affect on tracking.

# Fields

• `type::String` \\
• `ID::String` \\
• `class::String` \\
""" DescriptionGroup

@kwdef mutable struct DescriptionGroup <: EleParameterGroup
  type::String = ""
  ID::String = ""
  class::String = ""
end

#---------------------------------------------------------------------------------------------------
# DownstreamReferenceGroup

"""
    mutable struct DownstreamReferenceGroup <: EleParameterGroup

Downstream end of element reference energy and species. This group is useful for
elements where the reference energy or species is not constant.
Elements where this is true include `LCavity`, `Foil`, and `Converter`.

To simplify the lattice bookkeeping, all elements that have a `ReferenceGroup` also have
a `DownstreamReferenceGroup`. 

## Fields
• `species_ref_downstream::Species`  - Reference species exit end. \\
• `pc_ref_downstream::Number`        - Reference `momentum*c` downstream end. \\
• `E_tot_ref_downstream::Number`     - Reference total energy downstream end. \\

## Associated output parameters:
• `β_ref_downstream::Number`         - Reference `v/c` upstream end. \\
• `γ_ref_downstream::Number`         - Reference gamma factor downstream end. \\
"""
@kwdef mutable struct DownstreamReferenceGroup <: EleParameterGroup
  species_ref_downstream::Species = Species()
  pc_ref_downstream::Number = NaN
  E_tot_ref_downstream::Number = NaN
end

#---------------------------------------------------------------------------------------------------
# EMultipoleGroup

"""
    mutable struct EMultipoleGroup <: EleParameterGroup

Vector of Electric multipoles.

## Field
• `pole::Vector{EMultipole}`  - Vector of multipoles. \\
"""
@kwdef mutable struct EMultipoleGroup <: EleParameterGroup
  pole::Vector{EMultipole} = Vector{EMultipole}([])         # Vector of multipoles. 
end

#---------------------------------------------------------------------------------------------------
# FloorPositionGroup

"""
    mutable struct FloorPositionGroup <: EleParameterGroup

Position and orientation in global coordinates.
In a lattice element this group gives the coordinates at the entrance end of the element
ignoring misalignments.

# Fields
• `r::Vector`              - `[x,y,z]` position. \\
• `q::Quaternion{Number}`  - Quaternion orientation. \\
""" FloorPositionGroup

@kwdef mutable struct FloorPositionGroup <: EleParameterGroup
  r::Vector = [0.0, 0.0, 0.0]
  q::Quaternion{Number} = Quaternion(1.0, 0.0, 0.0, 0.0)
end

#---------------------------------------------------------------------------------------------------
# ForkGroup

"""
    mutable struct ForkGroup <: EleParameterGroup

Fork element parameters.

## Fields
• `to_line::Union{BeamLine, Nothing}`   - Beam line to fork to. \\
• `to_ele::String`                      - Element forked to. \\
• `direction::Int`                      - Longitudinal Direction of injected beam. \\
• `new_branch::Bool`                    - New or existing `to_line`? \\
""" ForkGroup

@kwdef mutable struct ForkGroup <: EleParameterGroup
  to_line::Union{BeamLine, Nothing} = nothing
  to_ele::String = ""
  direction::Int = +1
  new_branch::Bool = true
end

#---------------------------------------------------------------------------------------------------
# GirderGroup

"""
    mutable struct GirderGroup <: EleParameterGroup

Girder parameters.

## Fields
• `eles:::Vector{Ele}`        - Elements supported by girder. \\
• `origin_ele::Ele`           - Origin reference element. \\
• `origin_ele_ref_pt::Loc.T`  - Origin reference point. Default is `Loc.CENTER`. \\
""" GirderGroup

@kwdef mutable struct GirderGroup <: EleParameterGroup
  eles::Vector{Ele} = Ele[]
  origin_ele::Ele = NullEle
  origin_ele_ref_pt::Loc.T = Loc.CENTER
end

#---------------------------------------------------------------------------------------------------
# InitParticleGroup

"""
    mutable struct InitParticleGroup <: EleParameterGroup

Initial particle position.

## Fields
• `orbit::Vector{Number}`     - Phase space 6-vector. \\
• `spin::Vector{Number}`      - Spin 3-vector. \\
"""
@kwdef mutable struct InitParticleGroup <: EleParameterGroup
  orbit::Vector{Number} = Vector{Number}([0,0,0,0,0,0])     # Phase space vector
  spin::Vector{Number} = Vector{Number}([0,0,0])            # Spin vector
end

#---------------------------------------------------------------------------------------------------
# LengthGroup

"""
    mutable struct LengthGroup <: EleParameterGroup

Element length and s-positions.

# Fields

• `L::Number`               - Length of element. \\
• `s::Number`               - Starting s-position. \\
• `s_downstream::Number`    - Ending s-position. \\
• `orientation::Int`        - Longitudinal orientation. +1 or -1. \\
""" LengthGroup

@kwdef mutable struct LengthGroup <: EleParameterGroup
  L::Number = 0.0               # Length of element
  s::Number = 0.0               # Starting s-position
  s_downstream::Number = 0.0    # Ending s-position
  orientation::Int = 1          # Longitudinal orientation
end

#---------------------------------------------------------------------------------------------------
# LordSlaveStatusGroup

"""
    mutable struct LordSlaveStatusGroup <: EleParameterGroup

Lord and slave status of an element.

## Fields
• `lord_status::Lord.T`     - Lord status. \\
• `slave_status::Slave.T`   - Slave status. \\
"""

@kwdef mutable struct LordSlaveStatusGroup <: EleParameterGroup
  lord_status::Lord.T = Lord.NOT
  slave_status::Slave.T = Slave.NOT
end

#---------------------------------------------------------------------------------------------------
# MasterGroup

"""
    mutable struct MasterGroup <: EleParameterGroup

## Fields
• `is_on::Bool`         - Turns on or off the fields in an element. When off, the element looks like a drift. \\
• `field_master::Bool`  - The setting of this matters when there is a change in reference energy. \\
In this case, if `field_master` = true, magnetic multipoles and Bend unnormalized fields will be held constant
and normalized field strengths willbe varied. And vice versa when `field_master` is `false`. \\
""" MasterGroup

@kwdef mutable struct MasterGroup <: EleParameterGroup
  is_on::Bool = true
  field_master::Bool = false         # Does field or normalized field stay constant with energy changes?
end

#---------------------------------------------------------------------------------------------------
# PatchGroup

"""
    mutable struct PatchGroup <: EleParameterGroup

`Patch` element parameters.

## Fields
• `t_offset::Number`          - Time offset. \\
• `E_tot_offset::Number`      - Total energy offset. Default is `NaN` (not used). \\
• `E_tot_exit::Number`        - Fix total energy at exit end. Default is `NaN` (not used). \\
• `pc_exit::Number`           - Reference momentum*c at exit end. Default is `NaN` (not used). \\
• `flexible::Bool`            - Flexible patch? Default is `false`. \\
• `L_user::Number`            - User set Length? Default is `NaN` (length calculated by bookkeeping code). \\
• `ref_coords::BodyLoc.T`     - Reference coordinate system used inside the patch. Default is `BodyLoc.EXIT_END`. \\
""" PatchGroup

@kwdef mutable struct PatchGroup <: EleParameterGroup
  t_offset::Number = 0.0                      # Time offset
  E_tot_offset::Number = NaN
  E_tot_exit::Number = NaN                    # Reference energy at exit end
  pc_exit::Number = NaN                       # Reference momentum at exit end
  flexible::Bool = false
  L_user::Number = NaN
  ref_coords::BodyLoc.T = BodyLoc.EXIT_END
end

#---------------------------------------------------------------------------------------------------
# ReferenceGroup

"""
    mutable struct ReferenceGroup <: EleParameterGroup

Reference energy, time, species, etc at upstream end of an element.
See also `DownstreamReferenceGroup 

## Fields
• `species_ref::Species`          - Reference species entering end. \\
• `pc_ref::Number`                - Reference `momentum*c` upstream end. \\
• `E_tot_ref::Number`             - Reference total energy upstream end. \\
• `time_ref::Number`              - Reference time upstream end. \\
• `time_ref_downstream::Number`   - Reference time downstream end. \\
• `extra_dtime_ref::Number`       - User set additional time change. \\
• `dE_ref`::Number            - Sets the change in the reference energy. \\

## Associated output parameters are
• `β_ref::Number`                 - Reference `v/c` upstream end. \\
• `γ_ref::Number`                 - Reference gamma factor upstream end. \\
"""
@kwdef mutable struct ReferenceGroup <: EleParameterGroup
  species_ref::Species = Species()
  pc_ref::Number = NaN
  E_tot_ref::Number = NaN
  time_ref::Number = 0.0
  time_ref_downstream::Number = 0.0
  extra_dtime_ref::Number = 0.0
  dE_ref::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# RFGroup

"""
    mutable struct RFGroup <: EleParameterGroup

RF voltage parameters. Also see `RFAutoGroup`.

## Fields

• `frequency::Number`       - RF frequency. \\
• `harmon::Number`          - RF frequency harmonic number. \\
• `voltage::Number`         - RF voltage. \\
• `gradient::Number`        - RF gradient. \\
• `phase::Number`           - RF phase. \\
• `multipass_phase::Number` - RF Phase added to multipass elements. \\
• `cavity_type::Cavity.T`   - Cavity type. Default is `Cavity.STANDING_WAVE`. \\
• `n_cell::Int`             - Number of cavity cells. Default is `1`. \\
""" RFGroup

@kwdef mutable struct RFGroup <: EleParameterGroup
  frequency::Number = 0.0
  harmon::Number = 0.0
  voltage::Number = 0.0
  gradient::Number = 0.0
  phase::Number = 0.0
  multipass_phase::Number = 0.0
  cavity_type::Cavity.T = Cavity.STANDING_WAVE
  n_cell::Int = 1
end

#---------------------------------------------------------------------------------------------------
# RFAutoGroup

"""
    mutable struct RFAutoGroup <: EleParameterGroup

RF autoscale parameters. Also see `RFGroup`.

## Fields

• `do_auto_amp::Bool`           - Will autoscaling set `auto_amp`? Default is `true`. \\
• `do_auto_phase::Bool`         - Will autoscaling set `auto_phase`? Default is `true`. \\
• `auto_amp::Number`            - Auto RF field amplitude scale value. \\
• `auto_phase::Number`          - Auto RF phase value. \\
""" RFAutoGroup

@kwdef mutable struct RFAutoGroup <: EleParameterGroup
  do_auto_amp::Bool = true    
  do_auto_phase::Bool = true
  auto_amp::Number = 1.0    
  auto_phase::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# SolenoidGroup

"""
  mutable struct SolenoidGroup <: EleParameterGroup

Solenoid parameters.

## Fields

• `Ksol::Number`        - Normalized solenoid strength. \\      
• `Bsol::Number`        - Solenoid field. \\
""" SolenoidGroup

@kwdef mutable struct SolenoidGroup <: EleParameterGroup
  Ksol::Number = 0.0              
  Bsol::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# TrackingGroup

"""
    mutable struct TrackingGroup <: EleParameterGroup

Sets the nominal values for tracking prameters.

# Fields
• `num_steps::Int`    - Number of steps. \\
• `ds_step::Number`   - Step length. \\

""" TrackingGroup

@kwdef mutable struct TrackingGroup <: EleParameterGroup
  num_steps::Int   = -1
  ds_step::Number = NaN
end



#---------------------------------------------------------------------------------------------------
# TwissGroup

"""
    mutable struct TwissGroup <: EleParameterGroup

Lattice element parameter group storing Twiss, dispersion and coupling parameters
for an element.
""" TwissGroup

@kwdef mutable struct TwissGroup <: EleParameterGroup
  a::Twiss1 = Twiss1()                # a-mode
  b::Twiss1 = Twiss1()                # b-mode
  c::Twiss1 = Twiss1()                # c-mode
  x::Dispersion1 = Dispersion1()      # x-axis
  y::Dispersion1 = Dispersion1()      # y-axis
end

#---------------------------------------------------------------------------------------------------
# BaseOutput

"""
    abstract type BaseOutput

Abstract type from which output group structs inherit.
AcceleratorLattice defines `OutputGroup <: BaseOutput` which is used for output parameters
defined by AcceleratorLattice. Custom output parameters may be defined by defining a new 
output group struct and a new `output_parameter` function method.

"""
abstract type BaseOutput end

#---------------------------------------------------------------------------------------------------
# OutputGroup

"""
    struct OutputGroup <: BaseOutput

Holy trait struct that is used to designate output element parameters.
""" OutputGroup

struct OutputGroup <: BaseOutput
end

#---------------------------------------------------------------------------------------------------
# AllGroup

"""
    struct AllGroup 

Struct used for element parameter bookkeeping whose presence represents that parameters 
in all parameter groups may have changed.
""" AllGroup

struct AllGroup; end

#---------------------------------------------------------------------------------------------------
# AbstractLattice 

"""
    abstract type AbstractLattice

Abstract lattice type from which the `Lattice` struct inherits.
"""
abstract type AbstractLattice end

#---------------------------------------------------------------------------------------------------
# Branch

"""
    mutable struct Branch <: BeamLineItem

Lattice branch structure. 

## Fields
• `name::String`                      - Name of the branch. \\
• `lat::Union{AbstractLattice, Nothing}`  - Pointer to the lattice containing the branch. \\
• `ele::Vector{Ele}`                  - Pointer to the array of lattice element contained in the branch. \\
• `pdict::Dict{Symbol,Any}`           - Dict for holding other branch parameters. \\

Note: `AbstractLattice` is used here since `Lattice` is not yet defined and Julia does not allow forward 
struct declarations.

## Standard pdict keys:
• `:geometry`   - `OPEN` or `CLOSED`. \\
• `:type`       - `MultipassLordBranch`, `SuperLordBranch`, `GirderBranch`, or `TrackingBranch`.  \\
• `:ix_branch`  - Index of branch in `lat.branch[]` array. \\
• `:ix_ele_min_changed` - For tracking branches: Minimum index of elements where parameter changes have been made. \\
  Set to `typemax(Int)` if no elements have been modified. \\
• `:ix_ele_max_changed` - For tracking branches: Maximum index of elements where parameter changes have been made. \\
  Set to `0` if no elements have been modified. \\

## Notes
The constant `NULL_BRANCH` is defined as a placeholder for signaling the absense of a branch.
The test `is_null(branch)` will test if a branch is a `NULL_BRANCH`.
""" Branch

@kwdef mutable struct Branch <: BeamLineItem
  name::String              = ""
  lat::Union{AbstractLattice, Nothing}  = nothing
  ele::Vector{Ele}          = Ele[]
  pdict::Dict{Symbol,Any}   = Dict{Symbol,Any}
end

""" 
The constant NULL_BRANCH is defined as a placeholder for signaling the absense of a branch.
The test is_null(branch) will test if a branch is a NULL_BRANCH.
""" NULL_BRANCH

const NULL_BRANCH = Branch(name = "NULL_BRANCH", pdict = Dict{Symbol,Any}(:ix_branch => -1))

#---------------------------------------------------------------------------------------------------
# Branch types

abstract type BranchType end
abstract type LordBranch <: BranchType end
abstract type TrackingBranch <: BranchType end

struct MultipassLordBranch <: LordBranch; end
struct SuperLordBranch <: LordBranch; end
struct GirderBranch <: LordBranch; end

struct GovernorBranch <: LordBranch; end  # This may never be used!

#---------------------------------------------------------------------------------------------------
# LatticeGlobal

"""
    LatticeGlobal

Struct holding "global" parameters used for tracking. 
Each Lattice will store a `LatticeGlobal` in `Lattice.pdict[:LatticeGlobal]`.
""" LatticeGlobal

mutable struct LatticeGlobal
  significant_length::Float64
  pdict::Dict{Symbol,Any}
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#---------------------------------------------------------------------------------------------------
# Lattice

"""
    mutable struct Lattice <: AbstractLattice

Lattice structure.

## Fields

• `name::String`. \\
• `branch::Vector{Branch}`. \\
• `pdict::Dict{Symbol,Any}`. \\

## Standard pdict keys

• `:record_changes`         - Bool: Record parameter changes? \\
• `:autobookkeeping`        - Bool: Automatic bookkeeping enabled? \\
• `parameters_have_changed` - Bool: Have any parameters changed since the last bookkeeping? \\

The `:record_changes` is usually `true` but can be set `false` by bookkeeping routines that 
want to make parameter changes without leaving a record. Also if `:record_changes` is `false`,
changes to parameters that normally should not be changed are allowed. This enables bookkeeping
code to modify, for example, dependent parameters.
"""
mutable struct Lattice <: AbstractLattice
  name::String
  branch::Vector{Branch}
  pdict::Dict{Symbol,Any}
end

