#-------------------------------------------------------------------------------------
# Base abstract types

"Abstract type that represents a Ele or sub BeamLine contained in a beamline."
abstract type BeamLineItem end

"Abstract lattice element from which all lattice elements inherit."
abstract type Ele <: BeamLineItem end

"Single element or vector of elemements."
Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}

#-------------------------------------------------------------------------------------
# Ele

macro ele(expr)
  if expr.head != :(=); throw("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\""); end
  name = expr.args[1]
  ### if isdefined(@__MODULE__, name); throw(f"Element already defined: {name}. Use @ele_redef if you really want to redefine."); end
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :name, "$name"))))
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :bookkeeping_on, false))))
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :map_params_to_groups, false))))
  return esc(expr)   # This will call the constructor below
end

"""Constructor called by `ele` macro."""

function (::Type{T})(; kwargs...) where T <: Ele
  return T(Dict{Symbol,Any}(kwargs))
end

"""Constructor for element types. Also exports the name.""" construct_ele_type

macro construct_ele_type(ele_type)
  eval( Meta.parse("mutable struct $ele_type <: Ele; param::Dict{Symbol,Any}; end") )
  str_type =  String("$ele_type")
  eval( Meta.parse("export $str_type") )
  return nothing
end

@construct_ele_type BeamBeam
@construct_ele_type BeginningEle
@construct_ele_type Bend
@construct_ele_type Controller
@construct_ele_type CrabCavity
@construct_ele_type Drift
@construct_ele_type EGun
@construct_ele_type EMField
@construct_ele_type Fork
@construct_ele_type Kicker
@construct_ele_type LCavity
@construct_ele_type Marker
@construct_ele_type Mask
@construct_ele_type Match
@construct_ele_type Multipole
@construct_ele_type Patch
@construct_ele_type Octupole
@construct_ele_type Quadrupole
@construct_ele_type RFCavity
@construct_ele_type Sextupole
@construct_ele_type Taylor
@construct_ele_type Undulator
@construct_ele_type Wiggler
@construct_ele_type NullEle

"""
NullEle lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is the instantiated element.
"""

const NULL_ELE = NullEle(Dict{Symbol,Any}(:name => "null"))

#-------------------------------------------------------------------------------------
# ele.XXX overload

function Base.getproperty(ele::T, s::Symbol) where T <: Ele
  if s == :param; return getfield(ele, :param); end

  if ele.param[:map_params_to_groups]
    pinfo = ele_param_info(s)
    if pinfo.parent_struct == Nothing
      return getfield(ele, :param)[s]
    else
      return getfield(getfield(ele, :param)[Symbol(pinfo.parent_struct)], s)
    end

  else
    return getfield(ele, :param)[s]
  end
end


function Base.setproperty!(ele::T, s::Symbol, value) where T <: Ele
  if !haskey(ele_param_by_struct[typeof(ele)], s); throw(f"Not a registered parameter: {s}. For element: {ele.name}."); end

  if ele.param[:bookkeeping_on]
    if !ele_param_by_struct[typeof(ele)][s].settable; throw(f"Parameter is not user settable: {s}. For element: {ele.name}."); end
  end

  if ele.param[:map_params_to_groups]
    pinfo = ele_param_info(s)
    if pinfo.parent_struct == Nothing
      getfield(ele, :param)[s] = value
    else
      optic = PropertyLens(s)   # See Accessors.jl experimental
      param = getfield(ele, :param)
      parent = Symbol(pinfo.parent_struct)
      old = param[parent]
      new = @set optic(old) = value
      param[parent] = new
    end

  else
    getfield(ele, :param)[s] = value
  end
end

#-------------------------------------------------------------------------------------
# Element traits

"General thick multipole. Returns a Bool."
function thick_multipole_ele(ele::Ele)
  ele <: Union{Drift, Quadrupole, Sextupole, Octupole} ? (return true) : (return false)
end

"Geometry type. Returns a EleGeometrySwitch"
function ele_geometry(ele::Ele)
  if ele isa Bend; return Circular; end
  if ele isa Patch; return PatchLike; end
  if ele <: Union{Marker, Mask, Multipole}; return ZeroLength; end
  if ele isa Girder; return GirderLike; end
  return Straight
end

#-------------------------------------------------------------------------------------
# Ele parameters

abstract type EleParameterGroup end

@kwdef struct FloorPositionGroup <: EleParameterGroup
  r::Vector64 =[0, 0, 0]               # (x,y,z) in Global coords
  q::Quat64 = Quat64(1.0, 0, 0, 0)    # Quaternion orientation
  theta::Float64 = 0
  phi::Float64 = 0
  psi::Float64 = 0
end

@kwdef struct BMultipole1 <: EleParameterGroup  # A single multipole
  K::Float64 = NaN
  Ks::Float64 = NaN
  B::Float64 = NaN
  Bs::Float64 = NaN  
  tilt::Float64 = 0
  n::Int64 = -1
  integrated::Bool = false
end

@kwdef struct BMultipoleGroup <: EleParameterGroup
  n_order::Vector{Int64} = []           # Vector of multipole order.
  vec::Vector{BMultipole1} = []         # Vector of multipoles.
end

@kwdef struct EMultipole1 <: EleParameterGroup
  E::Float64 = NaN
  Es::Float64 = NaN
  tilt::Float64 = 0
  n::Int64 = -1
end

@kwdef struct EMultipoleGroup <: EleParameterGroup
  n_order::Vector{Int64} = []           # Vector of multipole order.
  vec::Vector{EMultipole1} = []         # Vector of multipoles. 
end

@kwdef struct AlignmentGroup <: EleParameterGroup
  offset::Vector64 = [0,0,0]   # [x, y, z] offsets
  x_pitch::Float64 = 0         # x pitch
  y_pitch::Float64 = 0         # y pitch
  tilt::Float64 = 0            # Not used by Bend elements
end

@kwdef struct BendGroup <: EleParameterGroup
  angle::Float64 = NaN
  rho::Float64 = NaN
  g::Float64 = NaN
  bend_field::Float64 = NaN
  len_chord::Float64 = NaN
  ref_tilt::Float64 = 0
  e::Vector64 = [NaN, NaN]       # Edge angles
  e_rect::Vector64 = [NaN, NaN]  # Edge angles with respect to rectangular geometry.
  fint::Vector64 = [0.5, 0.5]
  hgap::Vector64 = [0, 0]
  type::BendTypeSwitch = SBend
  field_master::Bool = false
end

@kwdef struct ApertureGroup <: EleParameterGroup
  limit::Vector64 = [NaN, NaN]
  aperture_type::ApertureTypeSwitch = Elliptical
  aperture_at::EleBodyLocationSwitch = EntranceEnd
  offset_moves_aperture::Bool = true
end

@kwdef struct StringGroup <: EleParameterGroup
  type::String
  alias::String
  description::String
end

@kwdef struct RFGroup <: EleParameterGroup
  voltage::Float64 = 0
  gradient::Float64 = 0
  auto_scale:: Float64 = 1
  phase::Float64 = 0
  auto_phase::Float64 = 0
  multipass_phase::Float64 = 0
  frequency::Float64 = 0
  harmon::Float64 = 0
  cavity_type::CavityTypeSwitch = StandingWave
  n_cell::Int64 = 1
end

@kwdef struct TrackingGroup <: EleParameterGroup
  tracking_method::TrackingMethodSwitch = BmadStandard
  field_calc::FieldCalcMethodSwitch = BmadStandard
  num_steps::Int64 = -1
  ds_step::Float64 = NaN
end

struct ChamberWallGroup <: EleParameterGroup
end

#-------------------------------------------------------------------------------------
# Branch

mutable struct Branch <: BeamLineItem
  name::String
  ele::Vector{Ele}
  param::Dict{Symbol,Any}
end

#-------------------------------------------------------------------------------------
# branch.XXX overload

function Base.getproperty(branch::Branch, s::Symbol)
  if s == :ele; return getfield(branch, :ele); end
  if s == :param; return getfield(branch, :param); end
  if s == :name; return getfield(branch, :name); end
  return getfield(branch, :param)[s]
end


function Base.setproperty!(branch::Branch, s::Symbol, value)
  if s == :name; branch.name = value; end
  getfield(branch, :param)[s] = value
end

#-------------------------------------------------------------------------------------
# LatticeGlobal

"""
Global parameters used for tracking
"""
mutable struct LatticeGlobal
  significant_length::Float64
  other::Dict{Any,Any}                      # For user defined stuff.
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#-------------------------------------------------------------------------------------
# Lat

"Abstract lattice from which Lat inherits"
abstract type AbstractLat end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{Branch}
  param::Dict{Symbol,Any}
  global_param::LatticeGlobal
end

#-------------------------------------------------------------------------------------
# BeamLine
# Rule: param Dict of BeamLineEle and BeamLine always define :orientation and :multipass keys.
# Rule: All instances a given Ele in beamlines are identical so that the User can easily 
# make a Change to all. At lattice expansion, deepcopyies of Eles will be done.

# Why wrap a Ele within a BeamLineEle? This allows multiple instances in a beamline of the same 
# identical Ele with some having orientation reversed or within multipass regions and some not.

mutable struct BeamLineEle <: BeamLineItem
  ele::Ele
  param::Dict{Symbol,Any}
end

mutable struct BeamLine <: BeamLineItem
  name::String
  line::Vector{BeamLineItem}
  param::Dict{Symbol,Any}
end

"Used when doing lattice expansion."
mutable struct LatConstructionInfo
  multipass_id::Vector{String}
  orientation_here::Int
  n_loop::Int
end

#-------------------------------------------------------------------------------------
# Species

struct Species
end
