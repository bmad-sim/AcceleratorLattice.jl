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

"General thick multipole that is inherited by quadrupoles, sextupoles, etc."
abstract type ThickMultipole <: Ele end

# NullEle
"""
Lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is the instantiated element
"""

mutable struct Bend <: Ele; name::String; param::Dict{Symbol,Any}; end
Bend(name::String; kwargs...) = eval( :($(Symbol(name)) = Bend($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Drift <: Ele; name::String; param::Dict{Symbol,Any}; end
Drift(name::String; kwargs...) = eval( :($(Symbol(name)) = Drift($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Quadrupole <: ThickMultipole; name::String; param::Dict{Symbol,Any}; end
Quadrupole(name::String; kwargs...) = eval( :($(Symbol(name)) = Quadrupole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Sextupole <: ThickMultipole; name::String; param::Dict{Symbol,Any}; end
Sextupole(name::String; kwargs...) = eval( :($(Symbol(name)) = Sextupole($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Marker <: Ele; name::String; param::Dict{Symbol,Any}; end
Marker(name::String; kwargs...) = eval( :($(Symbol(name)) = Marker($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Lcavity <: ThickMultipole; name::String; param::Dict{Symbol,Any} end
Lcavity(name::String; kwargs...) = eval( :($(Symbol(name)) = Lcavity($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct RFcavity <: Ele; name::String; param::Dict{Symbol,Any}; end
RFcavity(name::String; kwargs...) = eval( :($(Symbol(name)) = RFcavity($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct Fork <: Ele; name::String; param::Dict{Symbol,Any}; end
Fork(name::String; kwargs...) = eval( :($(Symbol(name)) = Fork($name, Dict{Symbol,Any}($kwargs...))) )

mutable struct NullEle <: Ele; name::String; param::Dict{Symbol,Any}; end
NullEle(name::String; kwargs...) = eval( :($(Symbol(name)) = NullEle($name, Dict{Symbol,Any}($kwargs...))) )
NULL_ELE = NullEle("null", Dict{Symbol,Any}())

#-------------------------------------------------------------------------------------
# Ele parameters

abstract type ParameterGroup end

struct FloorPositionGroup <: ParameterGroup
  r::Vector{Float64}       # (x,y,z) in Global coords
  q::Vector{Float64}       # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end

FloorPositionGroup() = FloorPositionGroup([0,0,0], [1,0,0,0], 0, 0, 0)

struct KMultipole1 <: ParameterGroup  # A single multipole
  k::Float64
  ks::Float64
  tilt::Float64
  n::Int64
end

struct KMultipoleGroup <: ParameterGroup
  n_vec::Vector{Int64}          # Vector of multipole order.
  mp_vec::Vector{KMultipole1}    # Vector of multipoles.
end

struct FieldMultipole1 <: ParameterGroup  # A single multipole
  F::Float64
  Fs::Float64
  tilt::Float64
  n::Int64
end

struct FieldMultipoleGroup <: ParameterGroup
  n_vec::Vector{Int64}              # Vector of multipole order.
  mp_vec::Vector{FieldMultipole1}    # Vector of multipoles. 
end

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

struct AlignmentGroup <: ParameterGroup
  x_offset::Float64
  y_offset::Float64
  z_offset::Float64
  x_pitch::Float64
  y_pitch::Float64
  tilt::Float64     # Not used by Bend elements
end

struct BendGroup <: ParameterGroup
  angle::Float64
  rho::Float64
  g::Float64
  dg::Float64
  e::Vector{Float64}    # Edge angles
  e_rect::Vector{Float64}   # Edge angles with respect to rectangular geometry.
  len_chord::Float64
  ref_tilt::Float64
  fint::Vector{Float64}
  hgap::Vector{Float64}
end

struct ApertureGroup <: ParameterGroup
  x_limit::Vector{Float64}
  y_limit::Vector{Float64}
  aperture_type::ApertureTypeSwitch
  aperture_at::EleBodyLocationSwitch
  offset_moves_aperture::Bool
end

struct StringGroup <: ParameterGroup
  type::String
  alias::String
  description::String
end

struct RF <: ParameterGroup
  voltage::Float64
  gradient::Float64
  rf_phase::Float64
  rf_frequency::Float64
  harmon::Float64
  cavity_type::CavityTypeSwitch
  n_cell::Int64
end

struct TrackingGroup <: ParameterGroup
  tracking_method::TrackingMethodSwitch
  field_calc::FieldCalcMethodSwitch
  num_steps::Int64
  ds_step::Int64
end

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
# BmadGlobal

"""
Global parameters used for tracking
"""
mutable struct BmadGlobal
  significant_length::Float64
  other::Dict{Any,Any}                      # For user defined stuff.
end

BmadGlobal() = BmadGlobal(1.0e-10, Dict())

#-------------------------------------------------------------------------------------
# Lat

"Abstract lattice from which Lat inherits"
abstract type AbstractLat end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{Branch}
  param::Dict{Symbol,Any}
  bmad_global::BmadGlobal
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
