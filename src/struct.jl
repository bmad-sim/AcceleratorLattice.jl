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

mutable struct BeamBeam <: Ele; name::String; param::Dict{Symbol,Any}; end
BeamBeam(name::String; kwargs...) = eval( :($(Symbol(name)) = BeamBeam($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct BeginningEle <: Ele; name::String; param::Dict{Symbol,Any}; end
BeginningEle(name::String; kwargs...) = eval( :($(Symbol(name)) = BeginningEle($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Bend <: Ele; name::String; param::Dict{Symbol,Any}; end
Bend(name::String; kwargs...) = eval( :($(Symbol(name)) = Bend($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Controller <: Ele; name::String; param::Dict{Symbol,Any}; end
Controller(name::String; kwargs...) = eval( :($(Symbol(name)) = Controller($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct CrabCavity <: Ele; name::String; param::Dict{Symbol,Any}; end
CrabCavity(name::String; kwargs...) = eval( :($(Symbol(name)) = CrabCavity($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Drift <: Ele; name::String; param::Dict{Symbol,Any}; end
Drift(name::String; kwargs...) = eval( :($(Symbol(name)) = Drift($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct EGun <: Ele; name::String; param::Dict{Symbol,Any}; end
EGun(name::String; kwargs...) = eval( :($(Symbol(name)) = EGun($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct EMField <: Ele; name::String; param::Dict{Symbol,Any}; end
EMField(name::String; kwargs...) = eval( :($(Symbol(name)) = EMField($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Fork <: Ele; name::String; param::Dict{Symbol,Any}; end
Fork(name::String; kwargs...) = eval( :($(Symbol(name)) = Fork($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Kicker <: Ele; name::String; param::Dict{Symbol,Any}; end
Kicker(name::String; kwargs...) = eval( :($(Symbol(name)) = Kicker($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct LCavity <: Ele; name::String; param::Dict{Symbol,Any} end
LCavity(name::String; kwargs...) = eval( :($(Symbol(name)) = LCavity($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Marker <: Ele; name::String; param::Dict{Symbol,Any}; end
Marker(name::String; kwargs...) = eval( :($(Symbol(name)) = Marker($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Mask <: Ele; name::String; param::Dict{Symbol,Any}; end
Mask(name::String; kwargs...) = eval( :($(Symbol(name)) = Mask($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Match <: Ele; name::String; param::Dict{Symbol,Any}; end
Match(name::String; kwargs...) = eval( :($(Symbol(name)) = Match($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Multipole <: Ele; name::String; param::Dict{Symbol,Any}; end
Multipole(name::String; kwargs...) = eval( :($(Symbol(name)) = Multipole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Patch <: Ele; name::String; param::Dict{Symbol,Any}; end
Patch(name::String; kwargs...) = eval( :($(Symbol(name)) = Patch($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Octupole <: Ele; name::String; param::Dict{Symbol,Any}; end
Octupole(name::String; kwargs...) = eval( :($(Symbol(name)) = Octupole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Quadrupole <: Ele; name::String; param::Dict{Symbol,Any}; end
Quadrupole(name::String; kwargs...) = eval( :($(Symbol(name)) = Quadrupole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct RFCavity <: Ele; name::String; param::Dict{Symbol,Any}; end
RFCavity(name::String; kwargs...) = eval( :($(Symbol(name)) = RFCavity($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Sextupole <: Ele; name::String; param::Dict{Symbol,Any}; end
Sextupole(name::String; kwargs...) = eval( :($(Symbol(name)) = Sextupole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Taylor <: Ele; name::String; param::Dict{Symbol,Any}; end
Taylor(name::String; kwargs...) = eval( :($(Symbol(name)) = Taylor($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Undulator <: Ele; name::String; param::Dict{Symbol,Any}; end
Undulator(name::String; kwargs...) = eval( :($(Symbol(name)) = Undulator($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Wiggler <: Ele; name::String; param::Dict{Symbol,Any}; end
Wiggler(name::String; kwargs...) = eval( :($(Symbol(name)) = Wiggler($name, Dict{Symbol,Any}($kwargs...))) )


"""
NullEle lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is the instantiated element
"""

mutable struct NullEle <: Ele; name::String; param::Dict{Symbol,Any}; end
NullEle(name::String; kwargs...) = eval( :($(Symbol(name)) = NullEle($name, Dict{Symbol,Any}($kwargs...))) )
const NULL_ELE = NullEle("null", Dict{Symbol,Any}())

#-------------------------------------------------------------------------------------
# Element traits

"General thick multipole. Returns a Bool."
function thick_multipole_ele(ele::Ele)
  if ele <: Union{Drift, Quadrupole, Sextupole}; return true; end
  return false
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

abstract type ParameterGroup end

struct FloorPositionGroup <: ParameterGroup
  r::Vector{Float64}         # (x,y,z) in Global coords
  q::Quat64                  # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end

FloorPositionGroup() = FloorPositionGroup([0,0,0], QuatRotation{Float64}(1,0,0,0), 0, 0, 0)

struct KMultipole1 <: ParameterGroup  # A single multipole
  k::Float64
  ks::Float64
  tilt::Float64
  n::Int64
  integrated::Bool
end

struct KMultipoleGroup <: ParameterGroup
  n_vec::Vector{Int64}           # Vector of multipole order.
  mp_vec::Vector{KMultipole1}    # Vector of multipoles.
end

KMultipoleGroup() = KMultipoleGroup(Vector{Int64}(), Vector{KMultipole1})

struct BMultipole1 <: ParameterGroup  # A single multipole
  B::Float64
  Bs::Float64
  tilt::Float64
  n::Int64
  integrated::Bool
end

struct BMultipoleGroup <: ParameterGroup
  n_vec::Vector{Int64}               # Vector of multipole order.
  mp_vec::Vector{BMultipole1}    # Vector of multipoles. 
end

FieldMultipoleGroup() = FieldMultipoleGroup(Vector{Int64}(), Vector{FieldMultipole1})

struct EMultipole1 <: ParameterGroup
  E::Float64
  Es::Float64
  tilt::Float64
  n::Int64
end

struct EMultipoleGroup <: ParameterGroup
  n_vec::Vector{Int64}          # Vector of multipole order.
  mp_vec::Vector{EMultipole1}    # Vector of multipoles. 
end

EMultipoleGroup() = EMultipoleGroup(Vector{Int64}(), Vector{EMultipole1})

struct AlignmentGroup <: ParameterGroup
  x_offset::Float64
  y_offset::Float64
  z_offset::Float64
  x_pitch::Float64
  y_pitch::Float64
  tilt::Float64     # Not used by Bend elements
end

AlignmentGroup() = AlignmentGroup(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

struct BendGroup <: ParameterGroup
  angle::Float64
  rho::Float64
  g::Float64
  bend_field::Float64
  len_chord::Float64
  ref_tilt::Float64
  e::Vector{Float64}    # Edge angles
  e_rect::Vector{Float64}   # Edge angles with respect to rectangular geometry.
  fint::Vector{Float64}
  hgap::Vector{Float64}
end

BendGroup() = BendGroup(NaN, NaN, NaN, NaN, NaN, 0.0, [NaN, NaN], [NaN, NaN], [0.5, 0.5], [0.0, 0.0])

struct ApertureGroup <: ParameterGroup
  x_limit::Vector{Float64}
  y_limit::Vector{Float64}
  aperture_type::ApertureTypeSwitch
  aperture_at::EleBodyLocationSwitch
  offset_moves_aperture::Bool
end

ApertureGroup() = ApertureGroup([NaN, NaN], [NaN, NaN], Elliptical, EntranceEnd, true)

struct StringGroup <: ParameterGroup
  type::String
  alias::String
  description::String
end

StringGroup() = StringGroup("", "", "")

struct RFGroup <: ParameterGroup
  voltage::Float64
  gradient::Float64
  rf_phase::Float64
  rf_frequency::Float64
  harmon::Float64
  cavity_type::CavityTypeSwitch
  n_cell::Int64
end

RFGroup() = RFGroup(0.0, 0.0, 0.0, 0.0, 0.0, StandingWave, 1)

struct TrackingGroup <: ParameterGroup
  tracking_method::TrackingMethodSwitch
  field_calc::FieldCalcMethodSwitch
  num_steps::Int64
  ds_step::Int64
end

TrackingGroup() = TrackingGroup(BmadStandard, BmadStandard, NaI, NaI)

struct ChamberWallGroup <: ParameterGroup
end

#-------------------------------------------------------------------------------------
# Branch

mutable struct Branch <: BeamLineItem
  name::String
  ele::Vector{Ele}
  param::Dict{Symbol,Any}
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
  lattice_global::LatticeGlobal
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
