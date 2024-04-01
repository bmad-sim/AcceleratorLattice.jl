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

"Single element or vector of elemements."
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
  push!(ele_types_set, eval(Meta.parse("$str_type")))
  return nothing
end

ele_types_set = Set()  # Global list of element types.

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
  if expr.head != :(=); error("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\""); end
  name = expr.args[1]
  ### if isdefined(@__MODULE__, name)
  ###   error(f"Element already defined: {name}. Use @ele_redef if you really want to redefine.")
  ### end
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
  for group in param_groups_list[typeof(ele)]
    pdict[Symbol(group)] = group()
  end

  # Put name in first in case there are errors and the ele name needs to be printed.
  pdict[:name] = kwargs[:name]

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
@construct_ele_type Controller
@construct_ele_type Converter
@construct_ele_type CrabCavity
@construct_ele_type Crystal
@construct_ele_type Drift
@construct_ele_type EGun
@construct_ele_type ELSeparator
@construct_ele_type EMField
@construct_ele_type Fiducial
@construct_ele_type FloorShift
@construct_ele_type Foil
@construct_ele_type Fork
@construct_ele_type Girder
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
@construct_ele_type Ramper
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
""" NULL_ELE

const NULL_ELE = NullEle(Dict{Symbol,Any}(:name => "NULL"))

#---------------------------------------------------------------------------------------------------
# LatEleLocation

"""
    struct LatEleLocation

Element location within a lattice.

## Components
    ix_ele::Int          Element index in branch.ele[] array.
    ix_branch::Int       Branch index of branch containing the element in lat.branch[] array.
""" LatEleLocation

struct LatEleLocation
  ix_ele::Int         # Element index in branch.ele array.
  ix_branch::Int      # Branch index in lat.branch array.
end

"""
    LatEleLocation(ele::Ele)
Return corresponding `LatEleLocation` struct.
"""
LatEleLocation(ele::Ele) = LatEleLocation(ele.ix_ele, ele.branch.ix_branch)

#---------------------------------------------------------------------------------------------------
# Element groups

"""
    abstract type EleParameterGroup

Base type for all element parameter groups.
""" EleParameterGroup

abstract type EleParameterGroup end

"""
Element length and s-positions.
"""

@kwdef mutable struct LengthGroup <: EleParameterGroup
  L = 0.0::Number
  s = 0.0::Number
  s_downstream::Number = 0.0
  orientation::Int = 1
end

"""
    struct MasterGroup <: EleParameterGroup

## Components

 - `field_master::Bool`  The `field_master` setting matters when there is a change in reference energy.
In this case, if `field_master` = true, B-multipoles and BendGroup `bend_field` will be held constant
and K-multipols and bend `g` will be varied. Vice versa when `field_master = false.
""" MasterGroup

@kwdef mutable struct MasterGroup <: EleParameterGroup
  field_master::Bool = false         # Does field or normalized field stay constant with energy changes?
end

@kwdef mutable struct LordSlaveGroup <: EleParameterGroup
  lord_status::LordStatusSwitch = NotALord
  slave_status::SlaveStatusSwitch = NotASlave
end

"""
Position and orientation in global coordinates.
The FloorPositionGroup in a lattice element gives the coordinates at the entrance end of an element
ignoring misalignments.

Note: Rotations.jl is currently not compatible with using dual numbers so `q` is defined with `Float64`.
"""
@kwdef mutable struct FloorPositionGroup <: EleParameterGroup
  r::Vector = [0.0, 0.0, 0.0]                    # (x,y,z) in Global coords
  q::Quat64 = Quat64(1.0, 0.0, 0.0, 0.0)         # Quaternion orientation.
  theta::Number = 0.0
  phi::Number = 0.0
  psi::Number = 0.0
end

"""
Patch element parameters
"""
@kwdef mutable struct PatchGroup <: EleParameterGroup
  offset::Vector = [0.0, 0.0, 0.0]            # [x, y, z] offsets
  t_offset::Number = 0.0                      # Time offset
  x_pitch::Number = 0.0                       # x pitch
  y_pitch::Number = 0.0                       # y pitch
  tilt::Number = 0.0                          # tilt
  E_tot_offset::Number = NaN
  E_tot_exit::Number = NaN                    # Reference energy at exit end
  pc_exit::Number = NaN                       # Reference momentum at exit end
  flexible::Bool = false
  user_sets_length::Bool = false
  ref_coords::BodyLocationSwitch = ExitEnd
end

"""
Reference energy, time and species.
"""
@kwdef mutable struct ReferenceGroup <: EleParameterGroup
  species_ref::Species = Species("NotSet")
  species_ref_exit::Species = Species("NotSet")
  pc_ref::Number = NaN
  pc_ref_exit::Number = NaN
  E_tot_ref::Number = NaN
  E_tot_ref_exit::Number = NaN
  time_ref::Number = 0.0
  time_ref_exit::Number = 0.0
end

"""
Single magnetic multipole of a given order.
See BMultipoleGroup.
To switch between integrated and non-integrated, remove old struct first.
"""
@kwdef mutable struct BMultipole1 <: EleParameterGroup  # A single multipole
  Kn::Number = 0.0                 # EG: "Kn2", "Kn2L" 
  Ks::Number = 0.0                 # EG: "Ks2", "Ks2L"
  Bn::Number = 0.0
  Bs::Number = 0.0  
  tilt::Number = 0.0
  order::Int   = -1         # Multipole order
  integrated = nothing  # Also determines what stays constant with length changes.
end

"""
  Vector of magnetic multipoles.

  This group is optional and will not appear in an element that does not have any multipoles.
"""
@kwdef mutable struct BMultipoleGroup <: EleParameterGroup
  vec::Vector{BMultipole1} = Vector{BMultipole1}([])         # Vector of multipoles.
end

"""
Single electric multipole of a given order.
See EMultipoleGroup.
""" EMultipole1

@kwdef mutable struct EMultipole1 <: EleParameterGroup
  En::Number = 0.0                    # EG: "En2", "En2L"
  Es::Number = 0.0                    # EG: "Es2", "Es2L"
  Etilt::Number = 0.0
  order::Int   = -1                   # Multipole order
  integrated::Bool = false
end

"""
  Vector of Electric multipoles.

  This group is optional and will not appear in an element that does not have any multipoles.
"""
@kwdef mutable struct EMultipoleGroup <: EleParameterGroup
  vec::Vector{EMultipole1} = Vector{EMultipole1}([])         # Vector of multipoles. 
end

"""
Orientation of an element (specifically, orientation of the body coordinates) with respect to the 
laboratory coordinates.
"""
@kwdef mutable struct AlignmentGroup <: EleParameterGroup
  offset::Vector = [0.0, 0.0, 0.0]       # [x, y, z] offsets
  offset_tot::Vector = [0.0, 0.0, 0.0]   # [x, y, z] offsets including Girder misalignment.
  x_pitch::Number = 0                    # x pitch
  x_pitch_tot::Number = 0                # x pitch including Girder misalignment.
  y_pitch::Number = 0                    # y pitch
  y_pitch_tot::Number = 0                # y pitch including Girder misalignment.
  tilt::Number = 0                       # Not used by Bend elements
  tilt_tot::Number = 0                   # Tilt including Girder misalignment
end


"""
Bend element parameters.

For tracking there is no distinction made between sector like (`SBend`) bends and
rectangular like (`RBend`) bends. The `bend_type` switch is only important when the
bend angle or length is varied. See the documentation for details.

Whether `bend_field` or `g` is held constant when the reference energy is varied is
determined by the `field_master` setting in the MasterGroup struct.
"""
@kwdef mutable struct BendGroup <: EleParameterGroup
  bend_type::BendTypeSwitch = SBend    # Is e or e_rect fixed? Also is len or len_chord fixed?
  angle::Number = 0.0
  rho::Number = Inf
  g::Number = 0.0                # Note: Old Bmad dg -> K0.
  bend_field::Number = 0.0       # Always a dependent parameter
  L_chord::Number = 0.0
  L_sagitta::Number = 0.0
  ref_tilt::Number = 0.0
  e1::Number = 0.0
  e2::Number = 0.0
  e1_rect::Number = 0.0          # Edge angle with respect to rectangular geometry.
  e2_rect::Number = 0.0          # Edge angle with respect to rectangular geometry.
  fint1::Number = 0.5
  fint2::Number = 0.5
  hgap1::Number = 0.0
  hgap2::Number = 0.0
end

"""
Vacuum chamber aperture.
"""
@kwdef mutable struct ApertureGroup <: EleParameterGroup
  x_limit::Vector = [NaN, NaN]
  y_limit::Vector = [NaN, NaN]
  aperture_type::ApertureTypeSwitch = Elliptical
  aperture_at::BodyLocationSwitch = EntranceEnd
  offset_moves_aperture::Bool = true
end

"""
Strings that can be set and used with element searches.

These strings have no affect on tracking.
"""
@kwdef mutable struct StringGroup <: EleParameterGroup
  type::String = ""
  alias::String = ""
  description::String = ""
end


"""
Girder parameters.
"""
@kwdef mutable struct GirderGroup <: EleParameterGroup
  origin_ele::Ele = NullEle
  origin_ele_ref_pt::StreamLocationSwitch = Center
  dr::Vector = [0.0, 0.0, 0.0]
  dtheta::Number = 0.0
  dphi::Number = 0.0
  dpsi::Number = 0.0
end

"""
RF parameters except for voltage and phase.
See also RFMasterGroup, RFFieldGroup, and LCavityGroup structures.
""" 
@kwdef mutable struct RFGroup <: EleParameterGroup
  multipass_phase::Number = 0.0
  frequency::Number = 0.0
  harmon::Number = 0.0
  cavity_type::CavityTypeSwitch = StandingWave
  n_cell::Int   = 1
end

"""
RF voltage parameters. Used by RFCavity element.
See also RFMasterGroup and RFGroup.
"""
@kwdef mutable struct RFFieldGroup <: EleParameterGroup
  voltage::Number = 0.0
  gradient::Number = 0.0
  phase::Number = 0.0
end

"""
Used by LCavity elements. 
See also RFMasterGroup and RFGroup.
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

"""
Solenoid 
"""

@kwdef mutable struct SolenoidGroup <: EleParameterGroup
  ks::Number = 0.0              # Notice lower case "k".
  bs_field::Number = 0.0
end

"""
RF autoscale and voltage_master
"""
@kwdef mutable struct RFMasterGroup <: EleParameterGroup
  voltage_master::Bool = false      # Voltage or gradient stay constant with length changes?
  do_auto_amp::Bool = true          # Will autoscaling set auto_amp?
  do_auto_phase::Bool = true        # Will autoscaling set auto_phase?
  auto_amp::Number = 1.0            # Auto amplitude scale value.
  auto_phase::Number = 0.0          # Auto phase value.
end

"""
Sets the nominal values for tracking prameters.
"""
@kwdef mutable struct TrackingGroup <: EleParameterGroup
  tracking_method::TrackingMethodSwitch = TrackingStandard
  field_calc::FieldCalcMethodSwitch = FieldStandard
  num_steps::Int   = -1
  ds_step::Number = NaN
end

"""
Vacuum chamber wall.
"""
@kwdef mutable struct ChamberWallGroup <: EleParameterGroup
end

#---------------------------------------------------------------------------------------------------
"""
Controller
"""

@kwdef mutable struct ControlVar
  name::Symbol = :NotSet
  value::Number = 0.0
  old_value::Number = 0.0
end

@kwdef mutable struct ControlVarGroup <: EleParameterGroup
  variable::Vector{ControlVar} = Vector{ControlVar}()
end

abstract type ControlSlave end

@kwdef mutable struct ControlSlaveExpression <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  exp_str::String = ""
  exp_parsed = nothing
  value::Number = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

@kwdef mutable struct ControlSlaveKnot  <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  x_knot::Vector = Vector()
  y_knot::Vector = Vector()
  interpolation::InterpolationSwitch = Spline
  value::Number = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

@kwdef mutable struct ControlSlaveFunction  <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  func = nothing
  value::Number = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

mutable struct ControlSlaveGroup  <: EleParameterGroup
  slave::Vector{T} where T <: ControlSlave
end
ControlSlaveGroup() = ControlSlaveGroup(Vector{ControlSlave}())

function var(sym::Symbol, val::Number = 0.0, old::Number = NaN) 
  isnan(old) ? (return ControlVar(sym, val, val)) : (return ControlVar(sym, val, old))
end

function ctrl(type::ControlSlaveTypeSwitch, eles, parameter, expr::AbstractString)
  if typeof(eles) == String; eles = [eles]; end
  return ControlSlaveExpression(eles = eles, slave_parameter = parameter, exp_str = expr, type = type)
end

function ctrl(type::ControlSlaveTypeSwitch, eles, parameter, x_knot::Vector, 
                                                      y_knot::Vector, interpolation = Spline)
  if typeof(eles) == String; eles = [eles]; end
  return ControlSlaveKnot(eles = eles, slave_parameter = parameter, x_knot = x_knot, y_knot = y_knot, type = type)
end

#function ctrl(custom::Type{Custom}, func::Function; eles = [], parameter = nothing)
#  if typeof(eles) == String; eles = [eles]; end
#  cs = ControlSlaveFunction(eles = eles, slave_parameter = parameter, func = func, type = Custom)
#end

#---------------------------------------------------------------------------------------------------
# Branch

"""
    mutable struct Branch <: BeamLineItem

Lattice branch structure. 

## Fields

    name::String
    ele::Vector{Ele}
    pdict::Dict{Symbol,Any}

## Notes
The constant NULL_BRANCH is defined as a placeholder for signaling the absense of a branch.
The test is_null(branch) will test if a branch is a NULL_BRANCH.
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

const NULL_BRANCH = Branch("NULL", Vector{Ele}(), Dict{Symbol,Any}(:ix_branch => -1))

#---------------------------------------------------------------------------------------------------
# Branch types

abstract type BranchType end
abstract type LordBranch <: BranchType end
abstract type TrackingBranch <: BranchType end

struct MultipassLordBranch <: LordBranch; end
struct SuperLordBranch <: LordBranch; end
struct GovernorBranch <: LordBranch; end

#---------------------------------------------------------------------------------------------------
# LatticeGlobal

"""
    LatticeGlobal

Struct holding "global" parameters used for tracking. 
Each Lat will store a `LatticeGlobal` in `Lat.pdict[:LatticeGlobal]`.
""" LatticeGlobal

mutable struct LatticeGlobal
  significant_length::Number
  pdict::Dict{Symbol,Any}
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#---------------------------------------------------------------------------------------------------
# Lat

"Abstract lattice from which Lat inherits"
abstract type AbstractLat end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{Branch}
  pdict::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
# BeamLine
# Rule: pdict Dict of BeamLineEle and BeamLine always define :orientation and :multipass keys.
# Rule: All instances a given Ele in beamlines are identical so that the User can easily 
# make a Change to all. When the lattice is expanded, deepcopyies of Eles will be done.

# Why wrap a Ele within a BeamLineEle? This allows multiple instances in a beamline of the same 
# identical Ele with some having orientation reversed or within multipass regions and some not.

mutable struct BeamLineEle <: BeamLineItem
  ele::Ele
  pdict::Dict{Symbol,Any}
end

mutable struct BeamLine <: BeamLineItem
  name::String
  line::Vector{BeamLineItem}
  pdict::Dict{Symbol,Any}
end

"Used when doing lattice expansion."
mutable struct LatConstructionInfo
  multipass_id::Vector{String}
  orientation_here::Int
  n_loop::Int
end
