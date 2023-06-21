using OffsetArrays
using PyFormattedStrings

#-------------------------------------------------------------------------------------
# Misc

struct InfiniteLoop <: Exception
  description::String
end


# A "lattice branch" is a branch in a lattice.
# A "beamline" is a line defined in a lattice file.

#-------------------------------------------------------------------------------------
# LatEle

"Define abstract type that represents a LatEle or sub BeamLine contained in a beamline."
abstract type BeamLineItem end

"Define abstract Lat element from which all lattice elements inherit"
abstract type LatEle <: BeamLineItem end

"General thick multipole that is inherited by quadrupoles, sextupoles, etc."
abstract type ThickMultipole <: LatEle end

"Bend lat element. Equivalent to SBend in Bmad."
mutable struct Bend <: LatEle
  name::String
  param::Dict{Symbol,Any}
end

"Drift lat element"
mutable struct Drift <: LatEle
  name::String
  param::Dict{Symbol,Any}
end

"Quadrupole lat element"
mutable struct Quadrupole <: ThickMultipole
  name::String
  param::Dict{Symbol,Any}
end

"Marker lat element"
mutable struct Marker <: LatEle
  name::String
  param::Dict{Symbol,Any}
end

beginning_Latele = Marker("beginning", Dict{Symbol,Any}())
end_Latele       = Marker("end", Dict{Symbol,Any}())

#-------------------------------------------------------------------------------------
# LatEle parameters

mutable struct FloorPosition
  r::Vector{Float64}       # (x,y,z) in Global coords
  q::Vector{Float64}       # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end

mutable struct MultipoleArray
  k::OffsetVector{Float64, Vector{Float64}}
  ks::OffsetVector{Float64, Vector{Float64}}
  tilt::OffsetVector{Float64, Vector{Float64}}
end

mutable struct LordSlave
  lord::Union{LatEle,Nothing}
  slave::Union{Vector{LatEle},Nothing}
  control_lord::Union{Vector{LatEle},Nothing}
end

#-------------------------------------------------------------------------------------
# Lattice

abstract type AbstractLat end

@enum Geometry open = 1 closed = 2

mutable struct LatParam
end

mutable struct LatBranch <: BeamLineItem
  name::String
  ele::Vector{LatEle}
  param::Dict{Symbol,Any}
end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{LatBranch}
  lord::LatBranch 
  param::LatParam
end

#-------------------------------------------------------------------------------------
# BeamLine
# Rule: param Dict of BeamLineEle and BeamLine always define :orientation and :multipass keys.
# Rule: All instances a given LatEle in beamlines are identical so that the User can easily 
# make a Change to all. At lattice expansion, deepcopyies of LatEles will be done.

# Why wrap a LatEle within a BeamLineEle? This allows multiple instances in a beamline of the same 
# identical LatEle with some having orientation reversed or within multipass regions and some not.

mutable struct BeamLineEle <: BeamLineItem
  ele::LatEle
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


