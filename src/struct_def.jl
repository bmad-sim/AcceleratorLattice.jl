using OffsetArrays
using PyFormattedStrings

#-------------------------------------------------------------------------------------

"Abstract Item in a beam line."
abstract type BeamLineItem end

"Abstract Lat element from which all elements inherit"
abstract type LatEle <: BeamLineItem end

"General thick multipole that is inherited by quadrupoles, sextupoles, etc."
abstract type ThickMultipole <: LatEle end

"Bend lat element. Equivalent to SBend in Bmad."
mutable struct Bend <: LatEle
  name::String
  param::Dict{String,Any}
end

"Drift lat element"
mutable struct Drift <: LatEle
  name::String
  param::Dict{String,Any}
end

"Quadrupole lat element"
mutable struct Quadrupole <: ThickMultipole
  name::String
  param::Dict{String,Any}
end

"Marker lat element"
mutable struct Marker <: LatEle
  name::String
  param::Dict{String,Any}
end

beginning_Latele = Marker("beginning", Dict{String,Any}())
end_Latele       = Marker("end", Dict{String,Any}())

#-------------------------------------------------------------------------------------
"LatEle parameters"

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
"Lattice"

abstract type AbstractLat end

mutable struct LatParam
end

mutable struct LatBranch
  name::String
  ele::Vector{LatEle}
  param::Dict{String,Any}
end

mutable struct Lat <: AbstractLat
  name::String
  branch::Vector{LatBranch}
  lord::Vector{LatEle}
  param::LatParam
end

#-------------------------------------------------------------------------------------
"beam line"

"A simple beam line."
mutable struct BeamLine <: BeamLineItem
  name::String
  line::Vector{BeamLineItem}
  multipass::Bool
  orientation::Int
end


