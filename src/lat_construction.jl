#+
# lat_construction.jl: Routines to construct a lattice.
#-

#---------------------------------------------------------------------------------------------------
# LatticeConstructionInfo

"""
    Internal: mutable struct LatticeConstructionInfo

Internal struct to hold information during lattice construction.

### Components
- `multipass_id::Vector{String}`
- `orientation_here::Int`
- `n_loop::Int`
"""
mutable struct LatticeConstructionInfo
  multipass_id::Vector{String}
  orientation_here::Int
  n_loop::Int
end

#---------------------------------------------------------------------------------------------------
# BeamLineItem

"""
    BeamLineItem(x::Ele)
    BeamLineItem(x::BeamLine)
    BeamLineItem(x::BeamLineEle)

Creates a `BeamLineItem` that contains an `Ele`, `BeamLine`, or `BeamLineEle`.
"""
BeamLineItem(x::Ele) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = BeamLine(x.id, x.line, deepcopy(x.pdict))
BeamLineItem(x::BeamLineEle) = BeamLineEle(x.ele, deepcopy(x.pdict))

#---------------------------------------------------------------------------------------------------
# BeamLine

"""
    BeamLine(name::AbstractString, line::Vector{T}; kwargs...) where T <: BeamLineItem
    BeamLine(line::Vector{T}; kwargs...) where T <: BeamLineItem

Creates a `BeamLine` from a vector of `BeamLineItem`s.

### Input

- `name`    Name of created `BeamLine`
- `line`    Vector of `BeamLineItem`s.
- `kwargs`  Beamline parameters. See below.

### Notes

Recognized `BeamLine` parameters:
- `geometry`      Branch geometry. Can be: `BranchGeom.OPEN` (default) or `BranchGeom.CLOSED`.
- `orientation`   Longitudinal orientation. Can be: `+1` (default) or `-1`.
- `multipass`     Multipass line? Default is `false`.
All parameters are optional.
"""
function BeamLine(line::Vector{T}; kwargs...) where T <: BeamLineItem
  bline = BeamLine(randstring(20), BeamLineItem.(line), Dict{Symbol,Any}(kwargs))
  if !haskey(bline.pdict, :orientation); bline.pdict[:orientation] = +1; end
  if !haskey(bline.pdict, :geometry);    bline.pdict[:geometry]    = OPEN; end
  if !haskey(bline.pdict, :multipass);   bline.pdict[:multipass]   = false; end
  if !haskey(bline.pdict, :name);        bline.pdict[:name] = ""; end

  for (ix, item) in enumerate(bline.line)
    item.pdict[:ix_beamline] = ix
  end

  return bline
end

#---------------------------------------------------------------------------------------------------
# Base.reverse

"""
    reverse(ele::Ele)
    reverse(x::BeamLineEle)
    reverse(beamline::BeamLine)

Marks a `Ele`, `BeamLineEle`, or `BeamLine` as reversed.

!! Note:
    For `BeamLine` reversal the `BeamLine` is marked as reversed but not the contained line elements.  
    Actual reversal of the line elements takes place during lattice expansion.
""" Base.reverse

function Base.reverse(ele::Ele)
  item = BeamLineItem(ele)
  item.pdict[:orientation] = +1
  return item
end

function Base.reverse(x::BeamLineEle)
  y = BeamLineEle(x.Ele, deepcopy(x.pdict))
  y.pdict[:orientation] = -y.pdict[:orientation]
  return y
end

function Base.reverse(beamline::BeamLine)
  bl = BeamLine(beamline.id, beamline.line, deepcopy(beamline.pdict))
  bl.pdict[:orientation] = -bl.pdict[:orientation]
  return bl
end

#---------------------------------------------------------------------------------------------------
# beamline reflection and repetition

"""
    reflect(beamline::BeamLine)

Reflect the order of the elements in the `BeamLine` (not to be confused with element longitudinal 
orientation reversal).
""" reflect

# Note: Here Base.reverse is the Julia defined reversal of a vector and not any of the extended methods. 
reflect(beamline::BeamLine) = BeamLine(beamline.id * "_m1", Base.reverse(beamline.line), beamline.pdict)


"""
    (-)(beamline::BeamLine)
    (*)(n::Int, beamline::BeamLine) 
    (*)(n::Int, ele::Ele)

Beamline reflection (-) and repetition (*).
""" Base.:(*), Base.:(-)

Base.:-(beamline::BeamLine) = reflect(beamline)

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.id * "_m" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.pdict)
                          
function Base.:*(n::Int, ele::Ele)
  if n < 0; error(f"BoundsError: Negative multiplier does not make sense."); end
  BeamLine(ele.id * "_m" * string(n), [BeamLineEle(ele) for i in 1:n], false, +1)
end

#---------------------------------------------------------------------------------------------------
# add_beamline_ele_to_branch!

"""
    Internal: add_beamline_ele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatticeConstructionInfo, Nothing}  = nothing)

Adds a `BeamLineEle` to a `Branch` under construction. The `info` argument passes on parameters
from the beamline containing the `BeamLineEle`.

This routine is used by the `Lattice` function.
""" add_beamline_ele_to_branch!

function add_beamline_ele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatticeConstructionInfo, Nothing}  = nothing)
  push!(branch.ele, copy(bele.ele))
  ele = branch.ele[end]
  ele.pdict[:ix_ele] = length(branch.ele)
  ele.pdict[:branch] = branch
  if info isa LatticeConstructionInfo
    ele.pdict[:LengthGroup].orientation = bele.pdict[:orientation] * info.orientation_here
    ele.pdict[:multipass_id] = copy(info.multipass_id)
    if length(ele.pdict[:multipass_id]) > 0; push!(ele.pdict[:multipass_id], 
                                              ele.name * ":" * string(bele.pdict[:ix_beamline])); end
  else
    ele.pdict[:LengthGroup].orientation = +1
    ele.pdict[:multipass_id] = []
  end
  return nothing
end

#---------------------------------------------------------------------------------------------------
# add_beamline_item_to_branch!

"""
    Internal: add_beamline_item_to_branch!(branch::Branch, item::BeamLineItem, info::LatticeConstructionInfo)

Adds a single item of a `BeamLine` line to the `Branch` under construction.

Used by Lattice() call chain and is not of general interest.
""" add_beamline_item_to_branch!

function add_beamline_item_to_branch!(branch::Branch, item::BeamLineItem, info::LatticeConstructionInfo)
  if item isa BeamLineEle
    add_beamline_ele_to_branch!(branch, item, info)
  elseif item isa BeamLine 
    add_beamline_line_to_branch!(branch, item, info)
  else
    error(f"ArgumentError: Beamline item not recognized: {item}")
  end
  return nothing
end

#---------------------------------------------------------------------------------------------------
# add_beamline_line_to_branch!

"""
    Internal: add_beamline_line_to_branch!(branch::Branch, beamline::BeamLine, info::LatticeConstructionInfo)

Add the elements in a `BeamLine.line` to a `Branch` under construction.

Used by the `Lattice` function.
""" add_beamline_line_to_branch!

function add_beamline_line_to_branch!(branch::Branch, beamline::BeamLine, info::LatticeConstructionInfo)
  info.n_loop += 1
  if info.n_loop > 100; error(f"InfiniteLoop: Infinite loop of beam lines calling beam lines detected."); end

  info = deepcopy(info)
  info.orientation_here = info.orientation_here * beamline.pdict[:orientation]
  info.orientation_here == 1 ? line = beamline.line : line = reverse(beamline.line)

  if info.multipass_id == []
    if beamline.pdict[:multipass]
      info.multipass_id = [beamline.id]
    end
  else
    push!(info.multipass_id, beamline.id * ":" * string(beamline.pdict[:ix_beamline]))
  end

  for item in line
    add_beamline_item_to_branch!(branch, item, info)
  end

  return nothing
end

#---------------------------------------------------------------------------------------------------
# new_tracking_branch!

"""
    Internal: new_tracking_branch!(lat::Lattice, beamline::Union{BeamLine, Tuple})

Adds a `BeamLine` to the lattice creating a new `Branch`.

Used by the `Lattice` function.
""" new_tracking_branch!

function new_tracking_branch!(lat::Lattice, bline::BeamLine)
  push!(lat.branch, Branch(name = bline.pdict[:name], lat = lat, pdict = Dict{Symbol,Any}(:geometry => bline.pdict[:geometry])))
  branch = lat.branch[end]
  branch.pdict[:ix_branch] = length(lat.branch)
  branch.pdict[:type] = TrackingBranch
  if branch.name == ""; branch.name = "b" * string(length(lat.branch)); end
  info = LatticeConstructionInfo([], bline.pdict[:orientation], 0)

  if haskey(bline.pdict, :species_ref); branch.ele[1].species_ref = bline.pdict[:species_ref]; end
  if haskey(bline.pdict, :pc_ref);      branch.ele[1].pc_ref      = bline.pdict[:pc_ref]; end
  if haskey(bline.pdict, :E_tot_ref);   branch.ele[1].E_tot_ref   = bline.pdict[:E_tot_ref]; end

  add_beamline_line_to_branch!(branch, bline, info)

  if haskey(bline.pdict, :end_ele)
    add_beamline_ele_to_branch!(branch, BeamLineItem(bline.pdict[:end_ele]))
  else
    @ele end_ele = Marker()
    add_beamline_ele_to_branch!(branch, BeamLineItem(end_ele))
  end

  # Beginning and end elements inherit orientation from neighbor elements.
  branch.ele[1].pdict[:LengthGroup].orientation = branch.ele[2].pdict[:LengthGroup].orientation
  branch.ele[end].pdict[:LengthGroup].orientation = branch.ele[end-1].pdict[:LengthGroup].orientation

  branch.ix_ele_min_changed = 1
  branch.ix_ele_max_changed = length(branch.ele)
  index_and_s_bookkeeper!(branch)

  return nothing
end

function new_lord_branch!(lat::Lattice, name::AbstractString, branch_type::Type{T}) where T <: BranchType
  push!(lat.branch, Branch(name = name, lat = lat, pdict = Dict{Symbol,Any}()))
  branch = lat.branch[end]
  branch.pdict[:ix_branch] = length(lat.branch)
  branch.pdict[:type] = branch_type
  branch.changed_ele = Set{Ele}()
  return branch
end

#---------------------------------------------------------------------------------------------------
# Lattice

"""
    Lattice(root_lines::Vector{BeamLine}; name = "lat") -> Lattice
    Lattice(root_line::BeamLine; name = "lat") -> Lattice

Returns a `Lattice` containing branches for the expanded beamlines and branches for the lord elements.

### Input

- root_line   Root beamline(s). 
- `name`      Optional name put in `lat.name`. If not present or blank (""), `lat.name` will be set
                to the name of the first branch.

### Output

- `Lattice`      - `Lattice` instance with expanded beamlines.

""" Lattice(root_line::BeamLine), Lattice(root_lines::Vector{BeamLine})

Lattice(root_line::BeamLine; name = "lat") = Lattice([root_line], name = name)

function Lattice(root_lines::Vector{BeamLine}; name::AbstractString = "lat") 
  lat = Lattice(name, Branch[], Dict{Symbol,Any}(:LatticeGlobal => LatticeGlobal(),
                                             :record_changes => false,
                                             :autobookkeeping => false,
                                             :parameters_have_changed => true
  ))
  
  for root in root_lines
    new_tracking_branch!(lat, root)
  end
  
  # Lord branches

  new_lord_branch!(lat, "super_lord", SuperLordBranch)
  new_lord_branch!(lat, "multipass_lord", MultipassLordBranch)
  new_lord_branch!(lat, "girder_lord", GirderBranch)

  init_multipass_bookkeeper!(lat)
  bookkeeper!(lat)
  lat_sanity_check(lat)

  lat.record_changes = true
  lat.autobookkeeping = true
  return lat
end
