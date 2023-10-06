#---------------------------------------------------------------------------------------------------
# Base abstract types

"Abstract type that represents a Ele or sub BeamLine contained in a beamline."
abstract type BeamLineItem end

"Abstract lattice element from which all lattice elements inherit."
abstract type Ele <: BeamLineItem end

"Single element or vector of elemements."
Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}

#---------------------------------------------------------------------------------------------------
# Ele

macro ele(expr)
  if expr.head != :(=); throw("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\""); end
  name = expr.args[1]
  ### if isdefined(@__MODULE__, name); throw(f"Element already defined: {name}. Use @ele_redef if you really want to redefine."); end
  insert!(expr.args[2].args, 2, :($(Expr(:kw, :name, "$name"))))
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

#---------------------------------------------------------------------------------------------------
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

#---------------------------------------------------------------------------------------------------
# Species

const notset_name = "Not Set!"

@kwdef struct Species
  name::String = notset_name
end

function species(name::AbstractString)
  return Species(name)
end

"""
mass in eV / c^2
"""

function mass(species::Species)
  return 1e3
end

function E_tot(pc::Float64, species::Species)
  return sqrt(pc^2 + mass(species)^2)
end

function pc(E_tot::Float64, species::Species)
  return sqrt(E_tot^2 - mass(species)^2)
end

#---------------------------------------------------------------------------------------------------
# Ele parameters

abstract type EleParameterGroup end

@kwdef struct LengthGroup <: EleParameterGroup
  len::Float64 = 0
end

@kwdef struct FloorPositionGroup <: EleParameterGroup
  r::Vector64 =[0, 0, 0]               # (x,y,z) in Global coords
  q::Quat64 = Quat64(1.0, 0, 0, 0)    # Quaternion orientation
  theta::Float64 = 0
  phi::Float64 = 0
  psi::Float64 = 0
end

@kwdef struct ReferenceGroup <: EleParameterGroup
  species_ref::Species = Species("NotSet")
  pc_ref::Float64 = NaN
  E_tot_ref::Float64 = NaN
  time_ref::Float64 = 0
  pc_ref_exit::Float64 = NaN
  E_tot_ref_exit::Float64 = NaN
  time_ref_exit::Float64 = 0
end

@kwdef struct BMultipole1 <: EleParameterGroup  # A single multipole
  K::Float64 = NaN
  Ks::Float64 = NaN
  B::Float64 = NaN
  Bs::Float64 = NaN  
  tilt::Float64 = 0
  n::Int64 = -1             # Multipole order
  integrated::Bool = false
end

@kwdef struct BMultipoleGroup <: EleParameterGroup
  vec::Vector{BMultipole1} = Vector{BMultipole1}([])         # Vector of multipoles.
end

@kwdef struct EMultipole1 <: EleParameterGroup
  E::Float64 = NaN
  Es::Float64 = NaN
  Etilt::Float64 = 0
  n::Int64 = -1           # Multipole order
  integrated::Bool = false
end

@kwdef struct EMultipoleGroup <: EleParameterGroup
  vec::Vector{EMultipole1} = Vector{EMultipole1}([])         # Vector of multipoles. 
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
  g::Float64 = NaN                # Old Bmad dg -> K0.
  bend_field::Float64 = NaN
  len_chord::Float64 = NaN
  ref_tilt::Float64 = 0
  e::Vector64 = [NaN, NaN]        # Edge angles
  e_rect::Vector64 = [NaN, NaN]   # Edge angles with respect to rectangular geometry.
  fint::Vector64 = [0.5, 0.5]
  hgap::Vector64 = [0, 0]
  type::BendTypeSwitch = SBend
  field_master::Bool = false      # If ref energy changes does bend_field or g stay constant?
end

@kwdef struct ApertureGroup <: EleParameterGroup
  x_limit::Vector64 = [NaN, NaN]
  y_limit::Vector64 = [NaN, NaN]
  aperture_type::ApertureTypeSwitch = Elliptical
  aperture_at::EleBodyLocationSwitch = EntranceEnd
  offset_moves_aperture::Bool = true
end

@kwdef struct StringGroup <: EleParameterGroup
  type::String = ""
  alias::String = ""
  description::String = ""
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

#---------------------------------------------------------------------------------------------------

"""
Possible kind values: String, Int, Real, Vector{Real}, Bool, Switch, Struct, Pointer

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

A Struct is a struct. For example, the :floor parameter holds a FloorPosition struct
"""


abstract type Struct end
abstract type Pointer end

@kwdef struct ParamInfo
  parent_group::T where T <: DataType
  kind::Union{T, Union} where T <: DataType  # Something like ApertureTypeSwitch is a Union.
  description::String = ""
  units::String = ""
  private::Bool = false
end

ParamInfo(parent::DataType, kind::Union{DataType, Union}, description::String) = ParamInfo(parent, kind, description, "", false)
ParamInfo(parent::DataType, kind::Union{DataType, Union}, description::String, units::String) = ParamInfo(parent, kind, description, units, false)

"""
Dictionary of parameters in the Ele.param dict.
"""

ele_param_dict = Dict(
  :name             => ParamInfo(Nothing,        String,    "Name of the element."),
  :type             => ParamInfo(Nothing,        String,    "Type of element. Set by User and ignored the code."),
  :alias            => ParamInfo(Nothing,        String,    "Alias name. Set by User and ignored by the code."),
  :description      => ParamInfo(Nothing,        String,    "Descriptive info. Set by User and ignored by the code."),

  :ix_ele           => ParamInfo(Nothing,        Int,       "Index of element in containing branch.ele array."),
  :field_master     => ParamInfo(Nothing,        Bool,      "Used when varying ref energy. True -> fields are fixed and normalized fields vary."),
  :orientation      => ParamInfo(Nothing,        Int,       "Longitudinal orientation of element. May be +1 or -1."),
  :branch           => ParamInfo(Nothing,        Pointer,   "Pointer to branch element is in."),

  :s                => ParamInfo(Nothing,        Real,      "Longitudinal s-position.", "m"),
  :s_exit           => ParamInfo(Nothing,        Real,      "Longitudinal s-position at exit end.", "m"),

  :len              => ParamInfo(LengthGroup,    Real,      "Element length.", "m"),

  :species_ref      => ParamInfo(ReferenceGroup, Species,   "Reference species."),
  :pc_ref           => ParamInfo(ReferenceGroup, Real,      "Reference momentum * c.", "eV"),
  :E_tot_ref        => ParamInfo(ReferenceGroup, Real,      "Reference total energy.", "eV"),
  :time_ref         => ParamInfo(ReferenceGroup, Real,      "Reference time.", "sec"),
  :pc_ref_exit      => ParamInfo(ReferenceGroup, Real,      "Reference momentum * c at exit end.", "eV"),
  :E_tot_ref_exit   => ParamInfo(ReferenceGroup, Real,      "Reference total energy at exit end.", "eV"),
  :time_ref_exit    => ParamInfo(ReferenceGroup, Real,      "Reference total energy at exit end.", "eV"),

  :angle            => ParamInfo(BendGroup,      Real,      "Design bend angle", "rad"),
  :bend_field       => ParamInfo(BendGroup,      Real,      "Design bend field corresponding to g bending", "T"),
  :rho              => ParamInfo(BendGroup,      Real,      "Design bend radius", "m"),
  :g                => ParamInfo(BendGroup,      Real,      "Design bend strength (1/rho)", "1/m"),
  :e                => ParamInfo(BendGroup,      Vector{Real},   "2-Vector of bend entrance and exit face angles.", "rad"),
  :e_rec            => ParamInfo(BendGroup,      Vector{Real},   
                                  "2-Vector of bend entrance and exit face angles relative to a rectangular geometry.", "rad"),
  :len_chord        => ParamInfo(BendGroup,      Real,      "Bend chord length.", "m"),
  :ref_tilt         => ParamInfo(BendGroup,      Real,      "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint             => ParamInfo(BendGroup,      Vector{Real},   "2-Vector of bend [entrance, exit] edge field integrals.", ""),
  :hgap             => ParamInfo(BendGroup,      Vector{Real},   "2-Vector of bend [entrance, exit] edge pole gap heights.", "m"),

  :offset           => ParamInfo(AlignmentGroup, Vector{Real},   "3-Vector of [x, y, z] element offsets.", "m"),
  :x_pitch          => ParamInfo(AlignmentGroup, Real,      "X-pitch element orientation.", "rad"),
  :y_pitch          => ParamInfo(AlignmentGroup, Real,      "Y-pitch element orientation.", "rad"),
  :tilt             => ParamInfo(AlignmentGroup, Real,      "Element tilt.", "rad"),

  :voltage          => ParamInfo(RFGroup,        Real,      "RF voltage.", "volt"),
  :gradient         => ParamInfo(RFGroup,        Real,      "RF gradient.", "volt/m"),
  :auto_amp_scale   => ParamInfo(RFGroup,        Real,      
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :phase            => ParamInfo(RFGroup,        Real,      "RF phase.", "rad"),
  :auto_phase       => ParamInfo(RFGroup,        Real,      "Correction RF phase calculated by the auto scale code.", "rad"),
  :multipass_phase  => ParamInfo(RFGroup,        Real,      
                                  "RF phase which can differ from multipass element to multipass element.", "rad"),
  :frequency        => ParamInfo(RFGroup,        Real,      "RF frequency.", "Hz"),
  :harmon           => ParamInfo(RFGroup,        Real,      "RF frequency harmonic number.", ""),
  :cavity_type      => ParamInfo(RFGroup,        CavityTypeSwitch, "Type of cavity."),
  :n_cell           => ParamInfo(RFGroup,        Int,       "Number of RF cells."),

  :tracking_method  => ParamInfo(TrackingGroup,  TrackingMethodSwitch,  "Nominal method used for tracking."),
  :field_calc       => ParamInfo(TrackingGroup,  FieldCalcMethodSwitch, "Nominal method used for calculating the EM field."),
  :num_steps        => ParamInfo(TrackingGroup,  Int,                   "Nominal number of tracking steps."),
  :ds_step          => ParamInfo(TrackingGroup,  Real,                  "Nominal distance between tracking steps.", "m"),

  :aperture_type    => ParamInfo(ApertureGroup,  ApertureTypeSwitch, "Type of aperture."),
  :aperture_at      => ParamInfo(ApertureGroup,  EleBodyLocationSwitch, "Where the aperture is."),
  :offset_moves_aperture 
                    => ParamInfo(ApertureGroup,  Bool, "Does moving the element move the aperture?"),
  :x_limit          => ParamInfo(ApertureGroup,  Vector{Real},   "2-Vector of horizontal aperture limits.", "m"),
  :y_limit          => ParamInfo(ApertureGroup,  Vector{Real},   "2-Vector of vertical aperture limits.", "m"),

  :r_floor          => ParamInfo(FloorPositionGroup, Vector{Real},   "3-vector of floor position.", "m"),
  :q_floor          => ParamInfo(FloorPositionGroup, Vector{Real},   "Quaternion orientation.", ""),
  :theta_floor      => ParamInfo(FloorPositionGroup, Real,           "Floor theta angle orientation", "rad"),
  :phi_floor        => ParamInfo(FloorPositionGroup, Real,           "Floor phi angle orientation", "rad"),
  :psi_floor        => ParamInfo(FloorPositionGroup, Real,           "Floor psi angle orientation", "rad"),
)

function units(key)
  param_info = ele_param_info(key)
  if param_info == nothing; return "???"; end
  return param_info.units
end

function description(key)
  param_info = ele_param_info(key)
  if param_info == nothing; return "???"; end
  return param_info.description
end

#---------------------------------------------------------------------------------------------------
# ele_group_field_to_param

"""
Given the field of an element parameter group return the associated symbol at the ele.param[] level.
""" ele_group_field_to_param

function ele_group_field_to_param(sym::Symbol, group::EleParameterGroup)
  if typeof(group) == FloorPositionGroup
    if sym == :r; return :r_floor; end
    if sym == :q; return :q_floor; end
    if sym == :theta; return :theta_floor; end
    if sym == :phi; return :phi_floor; end
    if sym == :psi; return :psi_floor; end
  end
  return sym
end

#---------------------------------------------------------------------------------------------------
# Branch

mutable struct Branch <: BeamLineItem
  name::String
  ele::Vector{Ele}
  param::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
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

#---------------------------------------------------------------------------------------------------
# LatticeGlobal

"""
Global parameters used for tracking
"""
mutable struct LatticeGlobal
  significant_length::Float64
  other::Dict{Any,Any}                      # For user defined stuff.
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#---------------------------------------------------------------------------------------------------
# Lat

"Abstract lattice from which Lat inherits"
abstract type AbstractLat end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{Branch}
  param::Dict{Symbol,Any}
  global_param::LatticeGlobal
end

#---------------------------------------------------------------------------------------------------
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

#---------------------------------------------------------------------------------------------------
# ele.XXX overload

"""
Get from param queue. 
If not in param queue, get from ele group.
If cannot find parameter associated with symbol, throw an error.
""" Base.getproperty

function Base.getproperty(ele::T, s::Symbol) where T <: Ele
  if s == :param; return getfield(ele, :param); end
  param = getfield(ele, :param)
  if haskey(param, s); return param[s]; end

  # If not at the top level then look for the parameter as part of an ele group
  pinfo = ele_param_info(s)
  parent = Symbol(pinfo.parent_group)
  if !haskey(param, parent); error(f"Cannot find {s} in element {param[:name]}"); end

  if pinfo.kind <: Vector
    param[s] = copy(getfield(param[parent], s))
    return param[s]
  else
    return ele_group_value(param[parent], s)
  end
end

"""
Set param queue unless symbol explicitly involves ele group. 
""" Base.setproperty!

function Base.setproperty!(ele::T, s::Symbol, value) where T <: Ele
  if !has_param(ele, s); throw(f"Not a registered parameter: {s}. For element: {ele.name}."); end
  if !is_settable(ele, s); throw(f"Parameter is not user settable: {s}. For element: {ele.name}."); end
  getfield(ele, :param)[s] = value
end
