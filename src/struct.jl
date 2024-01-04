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

"Single element or vector of elemements."
Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}

#---------------------------------------------------------------------------------------------------
# construct_ele_type

"""
    macro construct_ele_type(type_name)

Constructor for element types. Also exports the name.
""" construct_ele_type

macro construct_ele_type(type_name)
  eval( Meta.parse("mutable struct $type_name <: Ele; pdict::Dict{Symbol,Any}; end") )
  str_type =  String("$type_name")
  eval( Meta.parse("export $str_type") )
  push!(ele_types_set, eval(Meta.parse("$str_type")))
  return nothing
end

#---------------------------------------------------------------------------------------------------
# Stuff used by construct_ele_type

ele_types_set = Set()

macro ele(expr)
  if expr.head != :(=); error("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\""); end
  name = expr.args[1]
  ### if isdefined(@__MODULE__, name); error(f"Element already defined: {name}. Use @ele_redef if you really want to redefine."); end
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :name, "$name"))))
  return esc(expr)   # This will call the constructor below
end

# Constructor called by `ele` macro.

function (::Type{T})(; kwargs...) where T <: Ele
  ele = T(Dict{Symbol,Any}())
  ele.pdict[:inbox] = Dict{Symbol,Any}(kwargs)
  ele.pdict[:name] = pop!(ele.pdict[:inbox], :name)
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
    ix_ele::Int64        Element index in branch.ele[] array.
    ix_branch::Int64     Branch index of branch containing the element in lat.branch[] array.
""" LatEleLocation

struct LatEleLocation
  ix_ele::Int64       # Element index in branch.ele array.
  ix_branch::Int64    # Branch index in lat.branch array.
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

@kwdef struct LengthGroup <: EleParameterGroup
  L::Float64 = 0
  s::Float64 = 0
  s_downstream::Float64 = 0
end

"""
    struct MasterGroup <: EleParameterGroup

## Components

 - `field_master::Bool`  The `field_master` setting matters when there is a change in reference energy.
In this case, if `field_master` = true, B-multipoles and BendGroup `bend_field` will be held constant
and K-multipols and bend `g` will be varied. Vice versa when `field_master = false.
""" MasterGroup

@kwdef struct MasterGroup <: EleParameterGroup
  field_master::Bool = false         # Does field or normalized field stay constant with energy changes?
end

"""
Position and orientation in global coordinates.
The FloorPositionGroup in a lattice element gives the coordinates at the entrance end of an element
ignoring misalignments.
"""
@kwdef struct FloorPositionGroup <: EleParameterGroup
  r_floor::Vector64 =[0, 0, 0]              # (x,y,z) in Global coords
  q_floor::Quat64 = Quat64(1.0, 0, 0, 0)    # Quaternion orientation
  theta::Float64 = 0
  phi::Float64 = 0
  psi::Float64 = 0
end

"""
Patch element parameters
"""
@kwdef struct PatchGroup <: EleParameterGroup
  offset::Vector64 = [0,0,0]    # [x, y, z] offsets
  t_offset::Float64 = 0         # Time offset.
  x_pitch::Float64 = 0          # x pitch
  y_pitch::Float64 = 0          # y pitch
  tilt::Float64 = 0             # tilt
  E_tot_offset::Float64 = NaN
  E_tot_exit::Float64 = NaN     # Reference energy at exit end
  pc_exit::Float64 = NaN        # Reference momentum at exit end
  flexible::Bool = false
  user_sets_length::Bool = false.
  ref_coords::EleBodyEndSwitch = ExitEnd
end

"""
Reference energy, time and species.
"""
@kwdef struct ReferenceGroup <: EleParameterGroup
  species_ref::Species = Species("NotSet")
  species_ref_exit::Species = Species("NotSet")
  pc_ref::Float64 = NaN
  pc_ref_exit::Float64 = NaN
  E_tot_ref::Float64 = NaN
  E_tot_ref_exit::Float64 = NaN
  time_ref::Float64 = 0
  time_ref_exit::Float64 = 0
end

"""
Single magnetic multipole of a given order.
See BMultipoleGroup.
"""
@kwdef struct BMultipole1 <: EleParameterGroup  # A single multipole
  K::Float64 = 0            # EG: "K2", "K2L" 
  Ks::Float64 = 0           # EG: "K2s", "K2sL"
  B::Float64 = 0
  Bs::Float64 = 0  
  tilt::Float64 = 0
  order::Int64 = -1         # Multipole order
  integrated::Bool = false  # Also determines what stays constant with length changes.
end

"""
  Vector of magnetic multipoles.

  This group is optional and will not appear in an element that does not have any multipoles.
"""
@kwdef struct BMultipoleGroup <: EleParameterGroup
  vec::Vector{BMultipole1} = Vector{BMultipole1}([])         # Vector of multipoles.
end

"""
Single electric multipole of a given order.
See EMultipoleGroup.
""" EMultipole1

@kwdef struct EMultipole1 <: EleParameterGroup
  E::Float64 = 0              # EG: "E2", "E2L"
  Es::Float64 = 0             # EG: "E2s", "E2sL"
  Etilt::Float64 = 0
  order::Int64 = -1           # Multipole order
  integrated::Bool = false
end

"""
  Vector of Electric multipoles.

  This group is optional and will not appear in an element that does not have any multipoles.
"""
@kwdef struct EMultipoleGroup <: EleParameterGroup
  vec::Vector{EMultipole1} = Vector{EMultipole1}([])         # Vector of multipoles. 
end

"""
Orientation of an element (specifically, orientation of the body coordinates) with respect to the 
laboratory coordinates.
"""
@kwdef struct AlignmentGroup <: EleParameterGroup
  offset::Vector64 = [0,0,0]       # [x, y, z] offsets
  offset_tot::Vector64 = [0,0,0]   # [x, y, z] offsets including Girder misalignment.
  x_pitch::Float64 = 0             # x pitch
  x_pitch_tot::Float64 = 0         # x pitch including Girder misalignment.
  y_pitch::Float64 = 0             # y pitch
  y_pitch_tot::Float64 = 0         # y pitch including Girder misalignment.
  tilt::Float64 = 0                # Not used by Bend elements
  tilt_tot::Float64 = 0            # Tilt including Girder misalignment
end


"""
Bend element parameters.

For tracking there is no distinction made between sector like (`SBend`) bends and
rectangular like (`RBend`) bends. The `bend_type` switch is only important when the
bend angle or length is varied. See the documentation for details.

Whether `bend_field` or `g` is held constant when the reference energy is varied is
determined by the `field_master` setting in the MasterGroup struct.
"""
@kwdef struct BendGroup <: EleParameterGroup
  bend_type::BendTypeSwitch = SBend    # Is e or e_rect fixed? Also is len or len_chord fixed?
  angle::Float64 = 0
  rho::Float64 = Inf
  g::Float64 = 0                # Note: Old Bmad dg -> K0.
  bend_field::Float64 = 0
  L_chord::Float64 = 0
  L_sagitta::Float64 = 0
  ref_tilt::Float64 = 0
  e1::Float64 = 0
  e2::Float64 = 0
  e1_rect::Float64 = 0          # Edge angle with respect to rectangular geometry.
  e2_rect::Float64 = 0          # Edge angle with respect to rectangular geometry.
  fint1::Float64 = 0.5
  fint2::Float64 = 0.5
  hgap1::Float64 = 0
  hgap2::Float64 = 0
end

"""
Vacuum chamber aperture.
"""
@kwdef struct ApertureGroup <: EleParameterGroup
  x_limit::Vector64 = [NaN, NaN]
  y_limit::Vector64 = [NaN, NaN]
  aperture_type::ApertureTypeSwitch = Elliptical
  aperture_at::EleBodyLocationSwitch = EntranceEnd
  offset_moves_aperture::Bool = true
end

"""
Strings that can be set and used with element searches.

These strings have no affect on tracking.
"""
@kwdef struct StringGroup <: EleParameterGroup
  type::String = ""
  alias::String = ""
  description::String = ""
end


"""
"""
@kwdef struct GirderGroup <: EleParameterGroup
  origin_ele::Ele = NullEle
  origin_ele_ref_pt::EleBodyRefSwitch = Center
  dr_girder::Vector{Float64} = [0.0, 0.0, 0.0]
  dtheta_girder::Float64 = 0.0
  dphi_girder::Float64 = 0.0
  dpsi_girder::Float64 = 0.0
end

"""
RF parameters except for voltage and phase.
See also RFMasterGroup, RFFieldGroup, and LCavityGroup structures.
""" 
@kwdef struct RFGroup <: EleParameterGroup
  auto_amp:: Float64 = 1        # See do_auto_amp in RFMasterGroup.
  auto_phase::Float64 = 0       # See do_auto_phase in RFMasterGroup.
  multipass_phase::Float64 = 0
  frequency::Float64 = 0
  harmon::Float64 = 0
  cavity_type::CavityTypeSwitch = StandingWave
  n_cell::Int64 = 1
end

"""
RF voltage parameters. Used by RFCavity element.
See also RFMasterGroup and RFGroup.
"""
@kwdef struct RFFieldGroup <: EleParameterGroup
  voltage::Float64 = 0
  gradient::Float64 = 0
  phase::Float64 = 0
end

"""
Used by LCavity elements. 
See also RFMasterGroup and RFGroup.
"""
@kwdef struct LCavityGroup <: EleParameterGroup
  voltage_ref::Float64 = 0
  voltage_err::Float64 = 0
  voltage_tot::Float64 = 0
  gradient_ref::Float64 = 0
  gradient_err::Float64 = 0
  gradient_tot::Float64 = 0
  phase_ref::Float64 = 0
  phase_err::Float64 = 0
  phase_tot::Float64 = 0
end

"""
RF autoscale and voltage_master
"""
@kwdef struct RFMasterGroup <: EleParameterGroup
  voltage_master::Bool = false      # Voltage or gradient stay constant with length changes?
  do_auto_amp::Bool = true          # Will autoscaling set auto_amp in RFGroup?
  do_auto_phase::Bool = true        # Will autoscaling set auto_phase in RFGroup?
end

"""
Sets the nominal values for tracking prameters.
"""
@kwdef struct TrackingGroup <: EleParameterGroup
  tracking_method::TrackingMethodSwitch = BmadStandard
  field_calc::FieldCalcMethodSwitch = BmadStandard
  num_steps::Int64 = -1
  ds_step::Float64 = NaN
end

"""
Vacuum chamber wall.
"""
@kwdef struct ChamberWallGroup <: EleParameterGroup
end

#---------------------------------------------------------------------------------------------------
"""
Controller
"""

@kwdef mutable struct ControlVar
  name::Symbol = :NotSet
  value::Float64 = 0.0
  old_value::Float64 = 0.0
end

@kwdef struct ControlVarGroup <: EleParameterGroup
  vars::Vector{ControlVar} = Vector{ControlVar}()
end

abstract type ControlSlave end

@kwdef mutable struct ControlSlaveExpression <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  exp_str::String = ""
  exp_parsed = nothing
  value::Float64 = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

@kwdef mutable struct ControlSlaveKnot  <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  x_knot::Vector64 = Vector64()
  y_knot::Vector64 = Vector64()
  interpolation::InterpolationSwitch = Spline
  value::Float64 = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

@kwdef mutable struct ControlSlaveFunction  <: ControlSlave
  eles = []                  # Strings, and/or LatEleLocations
  ele_loc::Vector{LatEleLocation} = Vector{LatEleLocation}()
  slave_parameter = nothing
  func = nothing
  value::Float64 = 0.0
  type::ControlSlaveTypeSwitch = NotSet
end

@kwdef struct ControlSlaveGroup  <: EleParameterGroup
  slaves::Vector{ControlSlave} = Vector{ControlSlave}()
end

function var(sym::Symbol, val::Real = 0.0, old::Real = NaN) 
  isnan(old) ? (return ControlVar(sym, Float64(val), Float64(val))) : (return ControlVar(sym, Float64(val), Float64(old)))
end

function ctrl(type::ControlSlaveTypeSwitch, eles, parameter, expr::AbstractString)
  if typeof(eles) == String; eles = [eles]; end
  return ControlSlaveExpression(eles = eles, slave_parameter = parameter, exp_str = expr, type = type)
end

function ctrl(type::ControlSlaveTypeSwitch, eles, parameter, x_knot::Vector64, y_knot::Vector64, interpolation = Spline)
  if typeof(eles) == String; eles = [eles]; end
  return ControlSlaveKnot(eles = eles, slave_parameter = parameter, x_knot = x_knot, y_knot = y_knot, type = type)
end

#function ctrl(custom::Type{Custom}, func::Function; eles = [], parameter = nothing)
#  if typeof(eles) == String; eles = [eles]; end
#  cs = ControlSlaveFunction(eles = eles, slave_parameter = parameter, func = func, type = Custom)
#end

#---------------------------------------------------------------------------------------------------
# Superposition

@kwdef mutable struct Superimpose
  ele::String = ""
  ele_origin::RefLocationSwitch = Center
  ref_ele::String = ""
  ref_origin::RefLocationSwitch = Center
  offset::Float64 = 0.0
  wrap_superimpose::Bool = true
end

function Superimpose(list::Vector{Superimpose}; kwargs...)
  push!(list, Superimpose(kwargs))
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
# make a Change to all. At lattice expansion, deepcopyies of Eles will be done.

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
