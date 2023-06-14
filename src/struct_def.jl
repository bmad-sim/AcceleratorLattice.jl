using OffsetArrays
using PyFormattedStrings

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
  lord::Union{PhysicalEle,Nothing}
  slave::Union{Vector{PhysicalEle},Nothing}
  control_lord::Union{Vector{PhysicalEle},Nothing}
end

#-------------------------------------------------------------------------------------

macro insert_standard_PhysicalEle_fields()
  return esc(:( name::String; length::Float64 ))
end
  ## @insert_standard_PhysicalEle_fields


"Abstract physical element from which all elements inherit"
abstract type PhysicalEle end

"General thick multipole that is inherited by quadrupoles, sextupoles, etc."
abstract type ThickMultipole <: PhysicalEle
end

"Bend lattice element. Equivalent to SBend in Bmad."
mutable struct Bend <: PhysicalEle
  name::String
  lord_slave::Union{LordSlave,Nothing}
  param::Dict{String,Any}
end

"Drift lattice element"
mutable struct Drift <: PhysicalEle
  name::String
  lord_slave::Union{LordSlave,Nothing}
  param::Dict{String,Any}
end

"Quadrupole lattice element"
mutable struct Quadrupole <: ThickMultipole
  name::String
  lord_slave::Union{LordSlave,Nothing}
  param::Dict{String,Any}
end

"Marker lattice element"
mutable struct Marker <: PhysicalEle
  name::String
  lord_slave::Union{LordSlave,Nothing}
  param::Dict{String,Any}
end

beginning_physicalele = Marker('beginning', nothing, Dict{String,Any}())
end_physicalele       = Marker('end', nothing, Dict{String,Any}())

#-------------------------------------------------------------------------------------

abstract type AbstractLattice
abstract type AbstractBranch

mutable struct LatEle
  name::String
  physical_ele::PhysicalEle
  branch::Union{AbstractBranch,Nothing} 
  ix_ele::Int
  param::Dict{String,Any}  # Orientation, floor, floor_end => next ele
end

LatEle(ele::PhysicalEle, branch::AbstractBranch, ix_ele::Int) = LatEle(ele.name, ele, branch, ix_ele, nothing)

mutable struct LatBranch
  name::String
  ele::Vector{LatEle}
  lattice::Union{AbstractLattice, Nothing}      # Pointer to lattice containing branch
  ix_branch::Int    
  from_ele::Union{LatEle, Nothing}  # Creating fork element which forks to this branch.
  to_ele::Union{LatEle, Nothing}    # Element in this branch that creating fork element forks to.

mutable struct Lattice <: AbstractLattice
  branch::Vector{LatBranch}
end

function show_branch_layout(branch)
  print ("Branch: $branch.name")
  for ele in branch.ele
  
end


function show_lattice_layout

end

#-------------------------------------------------------------------------------------

abstract type BeamLineItem

mutable struct BeamLineEle <:BeamLineItem
  PhysicalEle::PhysicalEle
  forward_orientation::Bool
end

"A simple beam line."
mutable struct BeamLine <: BeamLineItem
  line::Vector{Union{BeamLineItem,Vector{BeamLineItem}}}
  multipass::Bool
end

#-------------------------------------------------------------------------------------
"Functions to construct a lattice."

function ele_def(type::Type{T}, name::String; kwargs...) where T <: PhysicalEle
  # kwargs is a named tuple with Symbol keys. Want keys to be Strings.
  return type(name, Dict{String,Any}(string(k)=>v for (k,v) in kwargs))
end

PhysicalEle_to_beamlineele(PhysicalEle::T) where T <: PhysicalEle
  return BeamLineEle(PhysicalEle, true)
end

function beamline_def(line_in::Vector{Union{PhysicalEle,BeamLine}}; multipass::Bool = false)
  return BeamLine(PhysicalEle_to_beamlineele.(line_in), mulitpass)
end

function push_beamline_item (lat::Lattice, branch::LatBranch, item::Union{BeamLineItem,Vector{BeamLineItem}})
  if isa(item, BeamLineEle)
    push!(branch.ele, LatEle(item, branch, size(branch.ele)+1)); end
  elseif isa(item, Vector{BeamLineEle})
    for subitem in item; push!(branch.ele, LatEle(subitem, branch, size(branch.ele)+1)); end
  elseif isa(item, BeamLine) 
    add_to_latbranch(lat, branch, item); end
  elseif isa(item, Vector{BeamLine})
    for subitem in item; add_to_latbranch(lat, branch, subitem); end
  end

  return nothing
end

function add_to_latbranch (lat::Lattice, branch::LatBranch, beamline::BeamLine)
  branch = lat.branch[end]
  push!(branch.ele, LatEle(deepcopy(beginning_physicalele), branch, 1))
  for item in beamline; push_beamline_item (lat, branch, item); end
end

function new_latbranch(lat::Lattice, beamline::BeamLine)
  push!(lat.branch, LatBranch(Vector{LatEle}(), lat, size(lat.branch)+1, nothing, nothing)
  add_to_latbranch(lat, lat.branch[end], beamline)
  push!(branch.ele, LatEle(deepcopy(end_physicalele), branch, size(branch.ele)+1))
end

function expand_beamline(root_line::Union{BeamLine,Vector{BeamLine}})
  if isa(root_line, BeamLine)
    new_latbranch(lat, root_line)
  else
    for rline in root_line; new_latbranch(lat, rline); end
  end
end