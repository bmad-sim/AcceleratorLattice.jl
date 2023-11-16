#+
# lat_construction.jl: Routines to construct a lattice.
#-

#-------------------------------------------------------------------------------------
# branch

"""
    branch(lat::Lat, ix::Int)
    branch(lat::Lat, who::AbstractString) 

Returns the branch in `lat` with index `ix` or name that matches `who`.

Returns `nothing` if no branch can be matched.
""" branch

function branch(lat::Lat, ix::Int) 
  if ix < 1 || ix > length(lat.branch); return nothing; end
  return lat.branch[ix]
end

function branch(lat::Lat, who::AbstractString) 
  for branch in lat.branch
    if branch.name == who; return branch; end
  end
  return nothing
end

#-------------------------------------------------------------------------------------
# BeamLineItem

"""
    BeamLineItem(x::Ele)
    BeamLineItem(x::BeamLine)
    BeamLineItem(x::BeamLineEle)

Creates a `BeamLineItem` that contains an `Ele`, `BeamLine`, or `BeamLineEle`.
"""
BeamLineItem(x::Ele) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = BeamLine(x.name, x.line, deepcopy(x.pdict))
BeamLineItem(x::BeamLineEle) = BeamLineEle(x.ele, deepcopy(x.pdict))

#-------------------------------------------------------------------------------------
# beamline

"""
    beamline(name::AbstractString, line::Vector{T}; kwargs...)

Creates a `beamline` from a vector of `BeamLineItem`s.

### Input

- `name`    Name of created beamline
- `line`    Vector of `BeamLineItem`s.
- `kwargs`  Beamline parameters. See below.

### Notes

Recognized beamline parameters:
- `geometry`      Branch geometry. Can be: `Open` (default) or `Closed`.
- `orientation`   Longitudinal orientation. Can be: `+1` (default) or `-1`.
- `multipass`     Multipass line? Default is `false`.
- `begin_ele`     Beginning element. Must be present and must be a `Marker` type. There is no default. 
                    The element parameters `species_ref` along with `pc_ref` or `E_tot_ref` must be present.
- `end_ele`       Ending element. If present, must be a `Marker` type or null_ele. Default is a `Marker`. 
All parameters are optional except for `begin_ele`.
""" beamline

function beamline(name::AbstractString, line::Vector{T}; kwargs...) where T <: BeamLineItem
  bline = BeamLine(name, BeamLineItem.(line), Dict{Symbol,Any}(kwargs))

  if !haskey(bline.pdict, :orientation); bline.pdict[:orientation] = +1; end
  if !haskey(bline.pdict, :geometry);    bline.pdict[:geometry]    = Open; end
  if !haskey(bline.pdict, :multipass);   bline.pdict[:multipass]   = false; end

  for (ix, item) in enumerate(bline.line)
    item.pdict[:ix_beamline] = ix
  end

  return bline
end

#-------------------------------------------------------------------------------------
# Base.reverse

"""
    reverse(ele::Ele)
    reverse(x::BeamLineEle)
    reverse(beamline::BeamLine)

Marks a `Ele`, `BeamLineEle`, or `beamline` as reversed.

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
  bl = BeamLine(beamline.name, beamline.line, deepcopy(beamline.pdict))
  bl.pdict[:orientation] = -bl.pdict[:orientation]
  return bl
end

#-------------------------------------------------------------------------------------
# beamline reflection and repetition

"""
    reflect(beamline::BeamLine)

Reflect the order of the elements in the `BeamLine` (not to be confused with element longitudinal 
orientation reversal).
""" reflect

# Note: Here Base.reverse is the Julia defined reversal of a vector and not any of the extended methods. 
reflect(beamline::BeamLine) = BeamLine(beamline.name * "_mult-1", Base.reverse(beamline.line), beamline.pdict)


"""
    (-)(beamline::BeamLine)
    (*)(n::Int, beamline::BeamLine) 
    (*)(n::Int, ele::Ele)

Beamline reflection (-) and repetition (*).
""" Base.:(*), Base.:(-)

Base.:-(beamline::BeamLine) = reflect(beamline)

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.name * "_mult" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.pdict)
                          
Base.:*(n::Int, ele::Ele) = (if n < 0; throw(BoundsError("Negative multiplier does not make sense.")); end,
        BeamLine(ele.name * "_mult" * string(n), [BeamLineEle(ele) for i in 1:n], false, +1))

#-------------------------------------------------------------------------------------
# add_beamline_ele_to_branch!

"""
    add_beamline_ele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatConstructionInfo, Nothing}  = nothing)

Adds a `BeamLineEle` to a `Branch` under construction. The `info` argument passes on parameters
from the beamline containing the `BeamLineEle`.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" add_beamline_ele_to_branch!

function add_beamline_ele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatConstructionInfo, Nothing}  = nothing)
  push!(branch.ele, deepcopy(bele.ele))
  ele = branch.ele[end]
  ele.pdict[:ix_ele] = length(branch.ele)
  ele.pdict[:branch] = branch
  if info isa LatConstructionInfo
    ele.pdict[:orientation] = bele.pdict[:orientation] * info.orientation_here
    ele.pdict[:multipass_id] = copy(info.multipass_id)
    if length(ele.pdict[:multipass_id]) > 0; push!(ele.pdict[:multipass_id], 
                                              ele.name * ":" * string(bele.pdict[:ix_beamline])); end
  else
    ele.pdict[:orientation] = +1
    ele.pdict[:multipass_id] = []
  end
  return nothing
end

#-------------------------------------------------------------------------------------#--------------------
# add_beamline_item_to_branch!

"""
    add_beamline_item_to_branch!(branch::Branch, item::BeamLineItem, info::LatConstructionInfo)

Adds a single item of a `BeamLine` line to the `Branch` under construction.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" add_beamline_item_to_branch!

function add_beamline_item_to_branch!(branch::Branch, item::BeamLineItem, info::LatConstructionInfo)
  if item isa BeamLineEle
    add_beamline_ele_to_branch!(branch, item, info)
  elseif item isa BeamLine 
    add_beamline_line_to_branch!(branch, item, info)
  else
    throw(ArgumentError(f"Beamline item not recognized: {item}"))
  end
  return nothing
end

#-------------------------------------------------------------------------------------
# add_beamline_line_to_branch!

"""
    add_beamline_line_to_branch!(branch::Branch, beamline::BeamLine, info::LatConstructionInfo)

Add the elements in a `BeamLine.line` to a `Branch` under construction.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" add_beamline_line_to_branch!

function add_beamline_line_to_branch!(branch::Branch, beamline::BeamLine, info::LatConstructionInfo)
  info.n_loop += 1
  if info.n_loop > 100; throw(InfiniteLoop("Infinite loop of beam lines calling beam lines detected.")); end

  info = deepcopy(info)
  info.orientation_here = info.orientation_here * beamline.pdict[:orientation]
  info.orientation_here == 1 ? line = beamline.line : line = reverse(beamline.line)

  if info.multipass_id == []
    if beamline.pdict[:multipass]
      info.multipass_id = [beamline.name]
    end
  else
    push!(info.multipass_id, beamline.name * ":" * string(beamline.pdict[:ix_beamline]))
  end

  for item in line
    add_beamline_item_to_branch!(branch, item, info)
  end

  return nothing
end

#-------------------------------------------------------------------------------------
# new_tracking_branch!

"""
    new_tracking_branch!(lat::Lat, beamline::BeamLine)

Adds a `BeamLine` to the lattice creating a new `Branch`.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" new_tracking_branch!

function new_tracking_branch!(lat::Lat, beamline::BeamLine)
  push!(lat.branch, Branch(beamline.name, Vector{Ele}(), Dict{Symbol,Any}(:geometry => beamline.pdict[:geometry])))
  branch = lat.branch[end]
  branch.pdict[:lat] = lat
  branch.pdict[:ix_branch] = length(lat.branch)
  branch.pdict[:type] = TrackingBranch
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end
  info = LatConstructionInfo([], beamline.pdict[:orientation], 0)

  if haskey(beamline.pdict, :begin_ele)
    add_beamline_ele_to_branch!(branch, BeamLineItem(beamline.pdict[:begin_ele]))
  else
    @ele begin_ele = BeginningEle(s = 0, L = 0)
    add_beamline_ele_to_branch!(branch, BeamLineItem(begin_ele))
  end

  if haskey(beamline.pdict, :species_ref); branch.ele[1].species_ref = beamline.pdict[:species_ref]; end
  if haskey(beamline.pdict, :pc_ref);      branch.ele[1].pc_ref      = beamline.pdict[:pc_ref]; end
  if haskey(beamline.pdict, :E_tot_ref);   branch.ele[1].E_tot_ref   = beamline.pdict[:E_tot_ref]; end

  add_beamline_line_to_branch!(branch, beamline, info)

  if haskey(beamline.pdict, :end_ele)
    add_beamline_ele_to_branch!(branch, BeamLineItem(beamline.pdict[:end_ele]))
  else
    @ele end_ele = Marker()
    add_beamline_ele_to_branch!(branch, BeamLineItem(end_ele))
  end

  # Beginning and end elements inherit orientation from neighbor elements.
  branch.ele[1].pdict[:orientation] = branch.ele[2].pdict[:orientation]
  branch.ele[end].pdict[:orientation] = branch.ele[end-1].pdict[:orientation]
  return nothing
end

function new_lord_branch!(lat::Lat, name::AbstractString)
  push!(lat.branch, Branch(name, Vector{Ele}(), Dict{Symbol,Any}()))
  branch = lat.branch[end]
  branch.pdict[:lat] = lat
  branch.pdict[:ix_branch] = length(lat.branch)
  branch.pdict[:type] = LordBranch
  lat.pdict[Symbol(name)] = branch
  return branch
end

#-------------------------------------------------------------------------------------
# lat_expansion

"""
    lat_expansion(name::AbstractString, root_line::Union{BeamLine,Vector{BeamLine}})
    lat_expansion(root_line::Union{BeamLine,Vector{BeamLine}})

Returns a `Lat` containing branches for the expanded beamlines and branches for the lord elements.

### Input

- `name`      Optional name put in `lat.name`. If not present or blank (""), `lat.name` will be set
                to the name of the first branch.
- root_line   Root beamline or lines.

### Output

- `Lat`       `Lat` instance with expanded beamlines.

""" lat_expansion

function expand(name::AbstractString, root_line::Union{BeamLine,Vector{BeamLine}};
            governors::Vector{T} = Vector{Ele}(), superimpose::Vector{W} = Vector{Ele}()) where {T <: Ele, W <: Ele}
  lat = Lat(name, Vector{Branch}(), Dict{Symbol,Any}(:LatticeGlobal => LatticeGlobal()))

  if root_line == nothing; root_line = root_beamline; end
  
  if root_line isa BeamLine
    new_tracking_branch!(lat, root_line)
  else
    for subline in root_line
      new_tracking_branch!(lat, subline)
    end
  end
  
  if lat.name == ""; lat.name = lat.branch[1].name; end

  # Lord branches

  new_lord_branch!(lat, "super_lord")
  new_lord_branch!(lat, "multipass_lord")
  new_lord_branch!(lat, "governor")

  init_bookkeeper!(lat, superimpose)
  init_governors!(lat, governors)
  bookkeeper!(lat)

  return lat
end

# expand version without lattice name argument.
function lat_expansion(root_line::Union{BeamLine,Vector{BeamLine}}; 
            governors::Vector{Ele} = Vector{Ele}(), superimpose::Vector{Ele} = Vector{Ele}())
  lat_expansion("", root_line; governors = governors, superimpose = superimpose)
end