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
    macro construct_ele_type(type_name) -> nothing

Constructor for element types. Example:
    @construct_ele_type Drift
Result: Drift struct is defined.
""" construct_ele_type

macro construct_ele_type(type_name)
  eval( Meta.parse("mutable struct $type_name <: Ele; pdict::Dict{Symbol,Any}; end") )
  str_type = String("$type_name")
  eval( Meta.parse("export $str_type") )
  return nothing
end

#---------------------------------------------------------------------------------------------------
# @ele/@eles macros

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
  return esc(expr)   # This will call the constructor below
end

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

# Functions called by `ele` macro.

function (::Type{T})(; kwargs...) where T <: Ele
  ele = T(Dict{Symbol,Any}())
  pdict = ele.pdict
  pdict[:changed] = Dict{Symbol,Any}()

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

@construct_ele_type ACKicker
@construct_ele_type BeamBeam
@construct_ele_type BeginningEle
@construct_ele_type Bend
@construct_ele_type Collimator
@construct_ele_type Controller    # Controller
@construct_ele_type Converter
@construct_ele_type CrabCavity
@construct_ele_type Custom
@construct_ele_type Crystal       # Photonic
@construct_ele_type Drift
@construct_ele_type EGun
@construct_ele_type ElectricSeparator
@construct_ele_type EMField
@construct_ele_type Fiducial
@construct_ele_type FloorShift
@construct_ele_type Foil
@construct_ele_type Fork
@construct_ele_type Girder        # Controller
@construct_ele_type Instrument
@construct_ele_type Kicker
@construct_ele_type LCavity
@construct_ele_type Marker
@construct_ele_type Mask
@construct_ele_type Match
@construct_ele_type Multipole
@construct_ele_type NullEle
@construct_ele_type Octupole
@construct_ele_type Patch
@construct_ele_type Quadrupole
@construct_ele_type Ramper        # Controller
@construct_ele_type RFBend
@construct_ele_type RFCavity
@construct_ele_type SADMult
@construct_ele_type Sextupole
@construct_ele_type Solenoid
@construct_ele_type Taylor
@construct_ele_type ThickMultipole
@construct_ele_type Undulator
@construct_ele_type UnionEle
@construct_ele_type Wiggler

"""
NullEle lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is a const NullEle element with `name` set to "null" that can be used for coding.
"""
const NULL_ELE = NullEle(Dict{Symbol,Any}(:name => "NULL_ELE"))

#---------------------------------------------------------------------------------------------------
# EleParameterGroupInfo

"""
    Internal: struct EleParameterGroupInfo

Struct holding information on a single `EleParameterGroup` group.
Used in constructing the `ELE_PARAM_GROUP_INFO` Dict.

## Contains
• `description::String`      - Descriptive string. \\
• `bookkeeping_needed::Bool  - If true, this indicates there exists a bookkeeping function for the 
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
""" BaseEleParameterGroup, EleParameterGroup, EleParameterSubGroup

abstract type BaseEleParameterGroup end
abstract type EleParameterGroup <: BaseEleParameterGroup end
abstract type EleParameterSubGroup <: BaseEleParameterGroup end

#---------------------------------------------------------------------------------------------------
# AlignmentGroup

"""
    mutable struct AlignmentGroup <: EleParameterGroup

Orientation of an element (specifically, orientation of the body coordinates) with respect to the 
machine coordinates.

## Fields
• `offset::Vector`         - [x, y, z] offsets not including any Girder misalignments. \\
• `offset_tot::Vector`     - [x, y, z] offsets including Girder misalignments. \\
• `x_rot::Number`          - Rotation around the x-axis not including any Girder misalignments.  \\
• `x_rot_tot::Number`      - Rotation around the x-axis including Girder misalignment. \\
• `y_rot::Number`          - Rotation around the y-axis not including any Girder misalignments. \\
• `y_rot_tot::Number`      - Rotation around the z-axis including Girder misalignment. \\
• `tilt::Number`           - Rotation around the z-axis not including any Girder misalignment. 
  Not used by Bend elements. \\
• `tilt_tot::Number`       - Rotation around the z-axis including Girder misalignment. 
  Not used by Bend elements. \\
""" AlignmentGroup

@kwdef mutable struct AlignmentGroup <: EleParameterGroup
  offset::Vector = [0.0, 0.0, 0.0] 
  offset_tot::Vector = [0.0, 0.0, 0.0]
  x_rot::Number = 0
  x_rot_tot::Number = 0
  y_rot::Number = 0
  y_rot_tot::Number = 0
  tilt::Number = 0
  tilt_tot::Number = 0
end

#---------------------------------------------------------------------------------------------------
# ApertureGroup

"""
    struct ApertureGroup <: EleParameterGroup

Vacuum chamber aperture struct.

## Fields
• `x_limit::Vector`                         - `[x-, x+]` Limits in x-direction. \\
• `y_limit::Vector`                         - `[y-, y+]` Limits in y-direction. \\
• `aperture_shape::ApertureShape.T`         - Aperture shape. Default is `ApertureShape.ELLIPTICAL`. \\
• `aperture_at::BodyLoc.T`                  - Where aperture is. Default is `BodyLoc.ENTRANCE_END`. \\
• `misalignment_moves_aperture::Bool`       - Do element misalignments move the aperture? \\
""" ApertureGroup

@kwdef mutable struct ApertureGroup <: EleParameterGroup
  x_limit::Vector = [NaN, NaN]
  y_limit::Vector = [NaN, NaN]
  aperture_shape::typeof(ApertureShape) = ELLIPTICAL
  aperture_at::BodyLoc.T = BodyLoc.ENTRANCE_END
  misalignment_moves_aperture::Bool = true
end

#---------------------------------------------------------------------------------------------------
# BeamBeamGroup

#### This is incomplete ####

"""
    struct BeamBeamGroup

""" BeamBeamGroup

@kwdef mutable struct Twiss <: EleParameterSubGroup
  beta_a::Number = 0
  alpha_a::Number = 0
  beta_b::Number = 0
  alpha_b::Number = 0
end


@kwdef mutable struct BeamBeamGroup <: EleParameterGroup
  n_slice::Number = 1
  z0_crossing::Number = 0       # Weak particle phase space z when strong beam Loc.CENTER passes
                                #   the BeamBeam element.
  repetition_freq:: Number = 0  # Strong beam repetition rate.
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
• `angle::Number`             - Design bend angle. \\
• `rho::Number`               - Design bend radius. \\
• `g::Number`                 - Design bend strength. Note: Old Bmad `dg -> Kn0`. \\
• `g_tot::Number`             - Total bend strength = `g + Kn0`. \\
• `bend_field::Number`        - Design bend field. \\
• `bend_field_tot::Number`    - Total bend field including `Bn0`. \\
• `L_chord::Number`           - Chord length. \\
• `L_sagitta::Number`         - Sagitta length of bend semi circle. \\
• `L_rectangle::Number`       - Rectangular length. See manual. \\
• `ref_tilt::Number`          - Tilt angle of reference (machine) coordinate system. \\
• `e1::Number`                - Pole face rotation at the entrance end with respect to a sector geometry. \\
• `e2::Number`                - Pole face rotation at the exit end with respect to a sector geometry. \\
• `e1_rect::Number`           - Pole face rotation with respect to a rectangular geometry. \\
• `e2_rect::Number`           - Pole face rotation with respect to a rectangular geometry. \\
• `fint1::Number`             - Field integral at entrance end. Default value is `0.5`. \\
• `fint2::Number`             - Field integral at exit end. Default value is `0.5`. \\
• `hgap1::Number`             - Pole gap at entrance end. \\
• `hgap2::Number`             - Pole gap at exit end. \\
• `fiducial_pt::FiducialPt.T` - Fiducial point used when the bend geometry is varied. 
  Default is `FiducialPt.NONE`. \\
• `exact_multipoles::ExactMultipoles.T` - Field multipoles treatment. Default is `ExactMultipoles.OFF`. \\

## Notes
For tracking there is no distinction made between sector like (`BendType.SECTOR`) bends and
rectangular like (`BendType.RECTANGULAR`) bends. The `bend_type` switch is only important when the
bend angle or length is varied. See the documentation for details.

Whether `bend_field` or `g` is held constant when the reference energy is varied is
determined by the `field_master` setting in the MasterGroup struct.
"""
@kwdef mutable struct BendGroup <: EleParameterGroup
  bend_type::BendType.T = BendType.SECTOR 
  angle::Number = 0.0
  rho::Number = Inf
  g::Number = 0.0
  g_tot::Number = 0.0            
  bend_field::Number = 0.0    
  bend_field_tot::Number = 0.0   
  L_chord::Number = 0.0
  L_sagitta::Number = 0.0
  L_rectangle::Number = 0.0
  ref_tilt::Number = 0.0
  e1::Number = 0.0
  e2::Number = 0.0
  e1_rect::Number = 0.0
  e2_rect::Number = 0.0
  fint1::Number = 0.5
  fint2::Number = 0.5
  hgap1::Number = 0.0
  hgap2::Number = 0.0
  fiducial_pt::FiducialPt.T = FiducialPt.NONE
  exact_multipoles::ExactMultipoles.T = ExactMultipoles.OFF
end

#---------------------------------------------------------------------------------------------------
# BMultipole1

"""
    mutable struct BMultipole1 <: EleParameterSubGroup

Single magnetic multipole of a given order.
Used by `BMultipoleGroup`.

## Fields

• `Kn::Number`                 - Normal normalized component. EG: `"Kn2"`, `"Kn2L"`. \\
• `Ks::Number`                 - Skew multipole component. EG: `"Ks2"`, `"Ks2L"`.  \\
• `Bn::Number`                 - Normal field component. \\ 
• `Bs::Number`                 - Skew field component. \\
• `tilt::Number`               - Rotation of multipole around `z`-axis. \\
• `order::Int`                 - Multipole order. \\
• `integrated::Union{Bool,Nothing}` - Integrated or not? 
  Also determines what stays constant with length changes. \\
"""
@kwdef mutable struct BMultipole1 <: EleParameterSubGroup  # A single multipole
  Kn::Number = 0.0                 # EG: "Kn2", "Kn2L" 
  Ks::Number = 0.0                 # EG: "Ks2", "Ks2L"
  Bn::Number = 0.0
  Bs::Number = 0.0  
  tilt::Number = 0.0
  order::Int   = -1                # Multipole order
  integrated::Union{Bool,Nothing} = nothing  # Also determines what stays constant with length changes.
end

#---------------------------------------------------------------------------------------------------
# BMultipoleGroup

"""
    mutable struct BMultipoleGroup <: EleParameterGroup

Vector of magnetic multipoles.

## Field
• `vec::Vector{BMultipole1}` - Vector of multipoles.

"""
@kwdef mutable struct BMultipoleGroup <: EleParameterGroup
  vec::Vector{BMultipole1} = Vector{BMultipole1}([])         # Vector of multipoles.
end

#---------------------------------------------------------------------------------------------------
# EMultipole1

"""
    mutable struct EMultipole1 <: EleParameterSubGroup

Single electric multipole of a given order.
Used by `EMultipoleGroup`.

## Fields

• `En::Number`                  - Normal field component. EG: "En2", "En2L" \\
• `Es::Number`                  - Skew fieldEG component. EG: "Es2", "Es2L" \\
• `Etilt::Number`               - Rotation of multipole around `z`-axis. \\
• `order::Int`                  - Multipole order. \\
• `integrated::Bool`            - Integrated field or not?. 
  Also determines what stays constant with length changes. \\
""" EMultipole1

@kwdef mutable struct EMultipole1 <: EleParameterSubGroup
  En::Number = 0.0                    # EG: "En2", "En2L"
  Es::Number = 0.0                    # EG: "Es2", "Es2L"
  Etilt::Number = 0.0
  order::Int = -1 
  integrated::Bool = false
end

#---------------------------------------------------------------------------------------------------
# EMultipoleGroup

"""
    mutable struct EMultipoleGroup <: EleParameterGroup

Vector of Electric multipoles.

## Field
• `vec::Vector{EMultipole1}`  - Vector of multipoles. \\
"""
@kwdef mutable struct EMultipoleGroup <: EleParameterGroup
  vec::Vector{EMultipole1} = Vector{EMultipole1}([])         # Vector of multipoles. 
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
• `q::Quat`                - Quaternion orientation. \\
• `theta::Number`          - Global orientation angle. \\
• `phi::Number`            - Global orientation angle. \\
• `psi::Number`            - Global orientation angle. \\
""" FloorPositionGroup

@kwdef mutable struct FloorPositionGroup <: EleParameterGroup
  r::Vector = [0.0, 0.0, 0.0]
  q::Quat = Quat(1.0, 0.0, 0.0, 0.0)
  theta::Number = 0.0
  phi::Number = 0.0
  psi::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# GirderGroup

"""
    mutable struct GirderGroup <: EleParameterGroup

Girder parameters.

## Fields
• `origin_ele::Ele`           - Origin reference element. \\
• `origin_ele_ref_pt::Loc.T`  - Origin reference point. Default is `Loc.CENTER`. \\
• `dr::Vector`                - `[x, y, z]` offset. \\
• `dtheta::Number`            - Orientation angle. \\
• `dphi::Number`              - Orientation angle. \\
• `dpsi::Number`              - Orientation angle. \\
"""
@kwdef mutable struct GirderGroup <: EleParameterGroup
  origin_ele::Ele = NullEle
  origin_ele_ref_pt::Loc.T = Loc.CENTER
  dr::Vector = [0.0, 0.0, 0.0]
  dtheta::Number = 0.0
  dphi::Number = 0.0
  dpsi::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# InitParticleGroup

"""
    mutable struct InitParticleGroup <: EleParameterGroup

Initial particle position.

## Fields
• `orbit::Vector{Number}`     - Phase space vector. \\
• `spin::Vector{Number}`      - Spin vector. \\
"""
@kwdef mutable struct InitParticleGroup <: EleParameterGroup
  orbit::Vector{Number} = Vector{Number}([0,0,0,0,0,0])     # Phase space vector
  spin::Vector{Number} = Vector{Number}([0,0,0])            # Spin vector
end

#---------------------------------------------------------------------------------------------------
# LCavityGroup

"""
    mutable struct LCavityGroup <: EleParameterGroup

Used by `LCavity` elements but not `RFCavity` elements.
See also `RFAutoGroup` and `RFCommonGroup`.

##Fields
• `voltage_ref::Number`     - Voltage gain of the reference particle. \\
• `voltage_err::Number`     - Voltage deviation from reference. \\
• `voltage_tot::Number`     - Actual voltage = `voltage_ref` + `voltage_err`. \\
• `gradient_ref::Number`    - Voltage gradient of reference. \\  
• `gradient_err::Number`    - Gradient deviation from reference. \\
• `gradient_tot::Number`    - Actual gradient = `gradient_ref` + `gradient_err`. \\
• `phase_ref::Number`       - RF Phase of reference particle. \\
• `phase_err::Number`       - RF Phase deviation from reference. \\
• `phase_tot::Number`       - Actual RF phase = `phase_ref` + `phase_err`. \\
"""
@kwdef mutable struct LCavityGroup <: EleParameterGroup
  voltage_ref::Number = 0.0
  voltage_err::Number = 0.0
  voltage_tot::Number = 0.0
  gradient_ref::Number = 0.0
  gradient_err::Number = 0.0
  gradient_tot::Number = 0.0
  phase_ref::Number = 0.0
  phase_err::Number = 0.0
  phase_tot::Number = 0.0
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
# LordSlaveGroup

"""
    mutable struct LordSlaveGroup <: EleParameterGroup

Lord and slave status of an element.

## Fields
• `lord_status::Lord.T`     - Lord status. \\
• `slave_status::Slave.T`   - Slave status. \\
"""

@kwdef mutable struct LordSlaveGroup <: EleParameterGroup
  lord_status::Lord.T = Lord.NOT
  slave_status::Slave.T = Slave.NOT
end

#---------------------------------------------------------------------------------------------------
# MasterGroup

"""
    mutable struct MasterGroup <: EleParameterGroup

## Fields
• `is_on::Bool`         - Turns on or off the fields in an element. When off, the element looks like a drift. \\
• `field_master::Bool`  - The setting of this matters when there is a change in reference energy. 
In this case, if `field_master` = true, magnetic multipoles and Bend unnormalized fields will be held constant
and normalized field strengths willbe varied. Vice versa when `field_master` is `false`. \\
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
• `offset::Vector`            - `[x, y, z]` offset vector. \\
• `t_offset::Number`          - Time offset. \\
• `x_rot::Number`             - Rotation around the `x`-axis. \\
• `y_rot::Number`             - Rotation around the `y`-axis. \\
• `tilt::Number`              - Rotation around the `z`-axis. \\
• `E_tot_offset::Number`      - Total energy offset. Default is `NaN` (not used). \\
• `E_tot_exit::Number`        - Fix total energy at exit end. Default is `NaN` (not used). \\
• `pc_exit::Number`           - Reference momentum*c at exit end. Default is `NaN` (not used). \\
• `flexible::Bool`            - Flexible patch? Default is `false`. \\
• `L_user::Number`            - User set Length? Default is `NaN` (length calculated by bookkeeping code). \\
• `ref_coords::BodyLoc.T`     - Reference coordinate system used inside the patch. Default is `BodyLoc.EXIT_END`.
""" PatchGroup

@kwdef mutable struct PatchGroup <: EleParameterGroup
  offset::Vector = [0.0, 0.0, 0.0]            # [x, y, z] offsets
  t_offset::Number = 0.0                      # Time offset
  x_rot::Number = 0.0                         # Rotation around the x-axis
  y_rot::Number = 0.0                         # Rotation around the y-axis
  tilt::Number = 0.0                          # Rotation around the z-axis
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

Reference energy, time and species. 

Generally `species_ref_exit` will be he same as `species_ref`
but with `Converter` or `Foil` Elements they will generally be different.

## Fields
• `species_ref::Species`          - Reference species entering end. \\
• `species_ref_exit::Species`     - Reference species exit end. \\
• `pc_ref::Number`                - Reference `momentum*c` upstream end. \\
• `pc_ref_downstream::Number`     - Reference `momentum*c` downstream end. \\
• `E_tot_ref::Number`             - Reference total energy upstream end. \\
• `E_tot_ref_downstream::Number`  - Reference total energy downstream end. \\
• `time_ref::Number`              - Reference time upstream end. \\
• `time_ref_downstream::Number`   - Reference time downstream end. \\
• `β_ref::Number`                 - Reference `v/c` upstream end. \\
• `β_ref_downstream::Number`      - Reference `v/c` downstream end. \\
"""
@kwdef mutable struct ReferenceGroup <: EleParameterGroup
  species_ref::Species = Species("NotSet")
  species_ref_exit::Species = Species("NotSet")
  pc_ref::Number = NaN
  pc_ref_downstream::Number = NaN
  E_tot_ref::Number = NaN
  E_tot_ref_downstream::Number = NaN
  time_ref::Number = 0.0
  time_ref_downstream::Number = 0.0
  β_ref::Number = 0.0
  β_ref_downstream::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# RFCommonGroup

"""
    mutable struct RFCommonGroup <: EleParameterGroup

RF parameters except for `voltage`,  `gradient` and `phase`.
Used by both `RFCavity` and `LCavity` elements.
See also `RFAutoGroup`, `RFCavityGroup`, and `LCavityGroup` structures.

## Fields

• `multipass_phase::Number`   - RF Phase added to multipass elements. \\
• `frequency::Number`         - RF frequency. \\
• `harmon::Number`            - RF frequency harmonic number. \\
• `cavity_type::Cavity.T`     - Cavity type. Default is `Cavity.STANDING_WAVE`. \\
• `n_cell::Int`               - Number of cavity cells. Default is `1`. \\
""" RFCommonGroup

@kwdef mutable struct RFCommonGroup <: EleParameterGroup
  multipass_phase::Number = 0.0
  frequency::Number = 0.0
  harmon::Number = 0.0
  cavity_type::Cavity.T = Cavity.STANDING_WAVE
  n_cell::Int = 1
end

#---------------------------------------------------------------------------------------------------
# RFCavityGroup

"""
    mutable struct RFCavityGroup <: EleParameterGroup

RF voltage parameters. Used by `RFCavity` elements but not `LCavity` elements.
See also `RFAutoGroup` and `RFCommonGroup`.

## Fields

• `voltage::Number`   - RF voltage. \\
• `gradient::Number`  - RF gradient. \\
• `phase::Number`     - RF phase. \\
""" RFCavityGroup

@kwdef mutable struct RFCavityGroup <: EleParameterGroup
  voltage::Number = 0.0
  gradient::Number = 0.0
  phase::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# RFAutoGroup

"""
    mutable struct RFAutoGroup <: EleParameterGroup

RF autoscale parameters.

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
# StringGroup

"""
    mutable struct StringGroup <: EleParameterGroup

Strings that can be set and used with element searches.
These strings have no affect on tracking.

# Fields

• `type::String` \\
• `alias::String` \\
• `description::String` \\

""" StringGroup

@kwdef mutable struct StringGroup <: EleParameterGroup
  type::String = ""
  alias::String = ""
  description::String = ""
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

"""
Vacuum chamber wall.
"""
@kwdef mutable struct ChamberWallGroup <: EleParameterGroup
end

#---------------------------------------------------------------------------------------------------
# TwissGroup

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

#-----------------

"""
Dispersion parameters for a single axis.

""" Dispersion1

@kwdef mutable struct Dispersion1 <: EleParameterSubGroup
  eta::Number = 0           # Position dispersion.
  etap::Number = 0          # Momentum dispersion.
  deta_ds::Number = 0       # Dispersion derivative.
end

#-----------------

"""
Twiss parameters

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
# Branch

"""
    mutable struct Branch <: BeamLineItem

Lattice branch structure. 

## Fields
    name::String
    ele::Vector{Ele}
    pdict::Dict{Symbol,Any}

## Standard pdict keys:
• `:lat`        - Pointer to containing lattice. \\
• `:geometry`   - `OPEN` or `CLOSED`. \\
• `:type`       - `MultipassLordBranch`, `SuperLordBranch`, `GirderBranch`, or `TrackingBranch`.  \\
• `:ix_branch`  - Index of branch in `lat.branch[]` array. \\
• `:ix_ele_min_changed` - For tracking branches: Minimum index of elements where parameter changes have been made.
  Set to `typemax(Int)` if no elements have been modified.
• `:ix_ele_max_changed` - For tracking branches: Maximum index of elements where parameter changes have been made.
  Set to `0` if no elements have been modified.
• `:changed_ele`        - `Set{Ele}` For lord branches: Set of elements whose parameters have been modified.

## Notes
The constant `NULL_BRANCH` is defined as a placeholder for signaling the absense of a branch.
The test `is_null(branch)` will test if a branch is a `NULL_BRANCH`.
""" Branch

mutable struct Branch <: BeamLineItem
  name::String
  ele::Vector{Ele}
  pdict::Dict{Symbol,Any}
end

""" 
The constant NULL_BRANCH is defined as a placeholder for signaling the absense of a branch.
The test is_null(branch) will test if a branch is a NULL_BRANCH.
""" NULL_BRANCH

const NULL_BRANCH = Branch("NULL_BRANCH", Ele[], Dict{Symbol,Any}(:ix_branch => -1))

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
Each Lat will store a `LatticeGlobal` in `Lat.pdict[:LatticeGlobal]`.
""" LatticeGlobal

mutable struct LatticeGlobal
  significant_length::Float64
  pdict::Dict{Symbol,Any}
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#---------------------------------------------------------------------------------------------------
# AbstractLat & Lat

"""
    abstract type AbstractLat

Abstract lattice type from which the `Lat` struct inherits.
"""
abstract type AbstractLat end

"""
    mutable struct Lat <: AbstractLat

Lattice structure.

## Fields

• `name::String`. \\
• `branch::Vector{Branch}`. \\
• `pdict::Dict{Symbol,Any}`. \\

## Standard pdict keys

• `:doing_bookkeeping`    - Bool: In the process of bookkeeping?
• `:autobookkeeping`      - Bool: Automatic bookkeeping enabled?

"""
mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{Branch}
  pdict::Dict{Symbol,Any}
end

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
