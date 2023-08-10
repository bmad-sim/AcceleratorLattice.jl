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

# Bend

"Bend lat element."
mutable struct Bend <: Ele
  name::String
  param::Dict{Symbol,Any}
end

function Bend(name::String; kwargs...) 
  eval( :($(Symbol(name)) = Bend($name, Dict{Symbol,Any}($kwargs...))) )
end

## Old way:
## Bend(name::String;kwargs...)= Bend(name, Dict{Symbol,Any}(kwargs))

# Drift

"Drift lat element"
mutable struct Drift <: Ele
  name::String
  param::Dict{Symbol,Any}
end

function Drift(name::String; kwargs...) 
  eval( :($(Symbol(name)) = Drift($name, Dict{Symbol,Any}($kwargs...))) )
end

# Quadrupole

"Quadrupole lat element"
mutable struct Quadrupole <: ThickMultipole
  name::String
  param::Dict{Symbol,Any}
end

function Quadrupole(name::String; kwargs...) 
  eval( :($(Symbol(name)) = Quadrupole($name, Dict{Symbol,Any}($kwargs...))) )
end

# Marker

"Marker lat element"
mutable struct Marker <: Ele
  name::String
  param::Dict{Symbol,Any}
end

function Marker(name::String; kwargs...) 
  eval( :($(Symbol(name)) = Marker($name, Dict{Symbol,Any}($kwargs...))) )
end

# NullEle
"""
Lattice element type used to indicate the absence of any valid element.
`NULL_ELE` is the instantiated element
"""
mutable struct NullEle <: Ele
  name::String
  param::Dict{Symbol,Any}
end

function NullEle(name::String; kwargs...) 
  eval( :($(Symbol(name)) = NullEle($name, Dict{Symbol,Any}($kwargs...))) )
end

NULL_ELE = NullEle("null", Dict{Symbol,Any}())

#-------------------------------------------------------------------------------------
# Ele parameters

abstract type EleParameterGroup end

struct FloorPosition <: EleParameterGroup
  r::Vector{Float64}       # (x,y,z) in Global coords
  q::Vector{Float64}       # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end

FloorPosition() = FloorPosition([0,0,0], [1,0,0,0], 0, 0, 0)

struct MultipoleArray <: EleParameterGroup
  k::OffsetVector{Float64}
  ks::OffsetVector{Float64}
  tilt::OffsetVector{Float64}
end

struct AlignmentParams <: EleParameterGroup
  x_offset::Float64
  y_offset::Float64
  z_offset::Float64
  x_pitch::Float64
  y_pitch::Float64
  tilt::Float64     # Not used by Bend elements
end

struct BendParams <: EleParameterGroup
  angle::Float64
  rho::Float64
  g::Float64
  dg::Float64
  e1::Float64
  e2::Float64
  e1r::Float64
  e2r::Float64
  len_chord::Float64
  ref_tilt::Float64
end

struct ChamberWall <: EleParameterGroup
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
