

mutable struct FloorPositionStruct
  r::Vector{Float64}       # (x,y,z) in Global coords
  q::Vector{Float64}       # Quaternion orientation
  theta::Float64;  phi::Float64;  psi::Float64  # Angular orientation consistant with q
end; export FloorPositionStruct

macro insert_standard_latele_fields()
  return esc(:( name::String; length::Float64 ))
end; export insert_standard_latele_fields

"Abstract lattice element from which all elements inherit"
abstract type LatEle end; export LatEle

"General thick multipole that is inherited by quadrupoles, sextupoles, etc."
abstract type ThickMultipole <: LatEle
end; export ThickMultipole

"Bend lattice element. Equivalent to SBend in Bmad."
mutable struct Bend <: LatEle
  ## @insert_standard_latele_fields
end; export Bmad

"Drift lattice element"
mutable struct Drift <: LatEle
  length::Float64
end; export Drift

"Quadrupole lattice element"
mutable struct Quadrupole <: ThickMultipole
  length::Float64
end; export Quadrupole

#-------------------------------------------------------------------------------------

"A single element in a beam line."
mutable struct BeamLineItem
  name::String
  rep_count::Integer   # EG "-5*q3" has rep_count = -5
  orientation::Bool
end; export BeamLineItem

"Abstract beam line."
abstract type AbstractLine end; export AbstractLine

"A simple beam line."
mutable struct BeamLine <: AbstractLine
  name::String
  line::Vector{BeamLineItem}
  multipass::Bool
end; export BeamLine

"A replacement beam line."
mutable struct ReplacementBeamLine <: AbstractLine
  name::String
  line::Vector{BeamLineItem}
  args::Vector{String}
end; export ReplacementBeamLine

"A beam line list."
mutable struct BeamLineList <: AbstractLine
  name::String
  line::Vector{BeamLineItem}
  index::Int
end; export BeamLineList

#-------------------------------------------------------------------------------------

"""
Dictionary of lines, lists, elements, etc.
Used for data storage when parsing a lattice.
"""
mutable struct LatParseContainer
  latele::Dict{String, LatEle}   # Dict of elements
  beam_line::Dict{String, AbstractLine}
end; export LatParseContainer

#-------------------------------------------------------------------------------------

function latele_def!(lat_pc::LatParseContainer, name::String, ele_type::LatEle, kwargs...)
  lat_pc.ele[name] = ele_type()
end; export ele_def


