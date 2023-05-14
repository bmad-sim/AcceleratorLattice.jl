

mutable struct FloorPositionStruct
  r::Vector{Float64}       # (x,y,z) in Global coords
  q::Vector{Float64}       # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end; export FloorPositionStruct

macro insert_standard_latele_fields()
  return :( name::String; length::Float64 )
end; export insert_standard_latele_fields

abstract type LatEle end; export LatEle

abstract type ThickMultipole <: LatEle
end; export ThickMultipole

mutable struct Bend <: LatEle
  @insert_standard_latele_fields
end; export Bmad

mutable struct Drift <: LatEle
  length::Float64
end; export Drift

mutable struct Quadrupole <: ThickMultipole
  length::Float64
end; export Quadrupole

mutable struct LatParseContainer
  ele::Dict{String, LatEle}   # Dict of elements
end; export LatParseContainer

#------------------------------------------------------------------------------------

function latele_def(lat_pc::LatParseContainer, name::String, ele_type::LatEle, kwargs...)
  lat_pc.ele[name] = ele_type()
end; export ele_def

