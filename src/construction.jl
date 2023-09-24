#-------------------------------------------------------------------------------------
# branch

"""
    branch(lat::Lat, ix::Int)
    branch(lat::Lat, who::AbstractString) 

Returns the branch in `lat` with index `ix` or name that matches `who`.

Returns `nothing` if no branch can be matched.
"""   branch

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
""" BeamLineItem

BeamLineItem(x::Ele) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = BeamLine(x.name, x.line, deepcopy(x.param))
BeamLineItem(x::BeamLineEle) = BeamLineEle(x.ele, deepcopy(x.param))

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

The beamline parameters can include:
- `geometry`      Branch geometry. Can be: `OpenGeom` (default) or `ClosedGeom`.
- `orientaiton`   Longitudinal orientation. Can be: `+1` (default) or `-1`.
- `multipass`     Multipass line? Default is `false`.

""" beamline

function beamline(name::AbstractString, line::Vector{T}; kwargs...) where T <: BeamLineItem
  bline = BeamLine(name, BeamLineItem.(line), Dict{Symbol,Any}(kwargs))

  if !haskey(bline.param, :orientation); bline.param[:orientation] = +1; end
  if !haskey(bline.param, :geometry);    bline.param[:geometry]    = OpenGeom; end
  if !haskey(bline.param, :multipass);   bline.param[:multipass]   = false; end

  for (ix, item) in enumerate(bline.line)
    item.param[:ix_beamline] = ix
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

!!! Note:
    For `BeamLine` reversal the `BeamLine` is marked as reversed but not the contained line elements.  
    Actual reversal of the line elements takes place during lattice expansion.
""" Base.reverse

function Base.reverse(ele::Ele)
  item = BeamLineItem(ele)
  item.param[:orientation] = +1
  return item
end

function Base.reverse(x::BeamLineEle)
  y = BeamLineEle(x.Ele, deepcopy(x.param))
  y.param[:orientation] = -y.param[:orientation]
  return y
end

function Base.reverse(beamline::BeamLine)
  bl = BeamLine(beamline.name, beamline.line, deepcopy(beamline.param))
  bl.param[:orientation] = -bl.param[:orientation]
  return bl
end

#-------------------------------------------------------------------------------------
# beamline reflection and repetition

"""
    reflect(beamline::BeamLine)

Reverse the order of the elements in the `BeamLine` (not to be confused with element longitudinal 
orientation reversal).
""" reflect

# Notice that Base.reverse is the Julia defined reversal of a vector and not any of the extended methods. 
reflect(beamline::BeamLine) = BeamLine(beamline.name * "_mult-1", Base.reverse(beamline.line), beamline.param)


"""
    (-)(beamline::BeamLine)
    (*)(n::Int, beamline::BeamLine) 
    (*)(n::Int, ele::Ele)

Beamline reflection (-) and repetition (*).
""" Base.:(*), Base.:(-)

Base.:-(beamline::BeamLine) = reflect(beamline)

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.name * "_mult" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.param)
                          
Base.:*(n::Int, ele::Ele) = (if n < 0; throw(BoundsError("Negative multiplier does not make sense.")); end,
        BeamLine(ele.name * "_mult" * string(n), [BeamLineEle(ele) for i in 1:n], false, +1))

#-------------------------------------------------------------------------------------
# add_beamlineele_to_branch!

"""
    add_beamlineele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatConstructionInfo, Nothing}  = nothing)

Adds a `BeamLineEle` to a `Branch` under construction. The `info` argument passes on parameters
from the beamline containing the `BeamLineEle`.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" add_beamlineele_to_branch!

function add_beamlineele_to_branch!(branch::Branch, bele::BeamLineEle, 
                                                 info::Union{LatConstructionInfo, Nothing}  = nothing)
  push!(branch.ele, deepcopy(bele.ele))
  ele = branch.ele[end]
  ele.param[:ix_ele] = length(branch.ele)
  ele.param[:branch] = branch
  if info isa LatConstructionInfo
    ele.param[:orientation] = bele.param[:orientation] * info.orientation_here
    ele.param[:multipass_id] = copy(info.multipass_id)
    if length(ele.param[:multipass_id]) > 0; push!(ele.param[:multipass_id], 
                                              ele.name * ":" * string(bele.param[:ix_beamline])); end
  else
    ele.param[:orientation] = +1
    ele.param[:multipass_id] = []
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
    add_beamlineele_to_branch!(branch, item, info)
  elseif item isa BeamLine 
    add_beamline_to_branch!(branch, item, info)
  else
    throw(ArgumentError(f"Beamline item not recognized: {item}"))
  end
  return nothing
end

#-------------------------------------------------------------------------------------
# add_beamline_to_branch!

"""
    add_beamline_to_branch!(branch::Branch, beamline::BeamLine, info::LatConstructionInfo)

Adds a `BeamLine` to a `Branch` under construction.

This routine is meant solely to be used in the lat_expansion call chain and is not of general interest.
""" add_beamline_to_branch!

function add_beamline_to_branch!(branch::Branch, beamline::BeamLine, info::LatConstructionInfo)
  info.n_loop += 1
  if info.n_loop > 100; throw(InfiniteLoop("Infinite loop of beam lines calling beam lines detected.")); end

  info = deepcopy(info)
  info.orientation_here = info.orientation_here * beamline.param[:orientation]
  info.orientation_here == 1 ? line = beamline.line : line = reverse(beamline.line)
  if info.multipass_id == []
    if beamline.param[:multipass]
      info.multipass_id = [beamline.name]
    end
  else
    push!(info.multipass_id, beamline.name * ":" * string(beamline.param[:ix_beamline]))
  end

  for item in line; add_beamline_item_to_branch!(branch, item, info); end

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
  push!(lat.branch, Branch(beamline.name, Vector{Ele}(), Dict{Symbol,Any}(:geometry => beamline.param[:geometry])))
  branch = lat.branch[end]
  branch.param[:lat] = lat
  branch.param[:ix_branch] = length(lat.branch)
  branch.param[:type] = TrackingBranch
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end
  info = LatConstructionInfo([], beamline.param[:orientation], 0)

  if haskey(branch.param, :begin_ele) 
    add_beamlineele_to_branch!(branch, BeamLineItem(branch.param[:begin_ele]))
  else
    @ele begin_ele = BeginningEle(s = 0, len = 0)
    add_beamlineele_to_branch!(branch, BeamLineItem(begin_ele))
  end

  add_beamline_to_branch!(branch, beamline, info)
  @ele end_ele = Marker()
  add_beamlineele_to_branch!(branch, BeamLineItem(end_ele))

  # Beginning and end elements inherit orientation from neighbor elements.
  branch.ele[1].param[:orientation] = branch.ele[2].param[:orientation]
  branch.ele[end].param[:orientation] = branch.ele[end-1].param[:orientation]
  return nothing
end

function new_lord_branch(lat::Lat, name::AbstractString)
  push!(lat.branch, Branch(name, Vector{Ele}(), Dict{Symbol,Any}()))
  branch = lat.branch[end]
  branch.param[:lat] = lat
  branch.param[:ix_branch] = length(lat.branch)
  branch.param[:type] = LordBranch
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

function lat_expansion(name::AbstractString, root_line::Union{BeamLine,Vector{BeamLine}})
  lat = Lat(name, Vector{Branch}(), Dict{Symbol,Any}(), LatticeGlobal())

  if root_line == nothing; root_line = root_beamline end
  
  if root_line isa BeamLine
    new_tracking_branch!(lat, root_line)
  else
    for subline in root_line
      new_tracking_branch!(lat, subline)
    end
  end
  
  if lat.name == ""; lat.name = lat.branch[1].name; end

  # Lord branches

  new_lord_branch(lat, "super_lord")
  new_lord_branch(lat, "controller_lord")
  new_lord_branch(lat, "multipass_lord")

  lat_init_bookkeeper!(lat)

  lat_bookkeeper!(lat)
  return lat
end

# lat_expansion version without lattice name argument.
lat_expansion(root_line::Union{BeamLine,Vector{BeamLine}}) = lat_expansion("", root_line)

#-------------------------------------------------------------------------------------
# lat_init_bookkeeper

function lat_init_bookkeeper!(lat::Lat)
  # Multipass: Sort slaves
  mdict = Dict()
  for branch in lat.branch
    if branch.name == "multipass_lord"; global multipass_branch = branch; end
    for ele in branch.ele
      id = ele.param[:multipass_id]
      delete!(ele.param, :multipass_id)
      if length(id) == 0; continue; end
      if haskey(mdict, id)
        push!(mdict[id], ele)
      else
        mdict[id] = [ele]
      end
    end
  end

  # Multipass: Create multipass lords

  for (key, val) in mdict
    push!(multipass_branch.ele, deepcopy(val[1]))
    lord = multipass_branch.ele[end]
    delete!(lord.param, :multipass_id)
    lord.param[:branch] = multipass_branch
    lord.param[:ix_ele] = length(multipass_branch.ele)
    lord.param[:slave] = Vector{Ele}()
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "!mp" * string(ix)
      ele.param[:multipass_lord] = lord
      push!(lord.param[:slave], ele)
    end
  end

  # Ele parameter groups

  for branch in lat.branch
    for ele in branch.ele
      for group in ele_param_groups[typeof(ele)]
        ele_param_group_init!(ele, group)
      end
    end
  end

  #

  for branch in lat.branch
    for ele in branch.ele
      ele.map_params_to_groups = true
      ele.bookkeeping_on = true
    end
  end
end

#-------------------------------------------------------------------------------------
# ele_param_group_init!

"""
    ele_param_group_init!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

""" ele_param_group_init!

function ele_param_group_init!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  if group != AlignmentGroup; return; end   # Temp for testing
  param = ele.param
  transfer_params!(param, group)
end

function ele_param_group_init!(ele::Ele, group::Type{BMultipoleGroup})
  vec::Vector{Union{BMultipole1,Nothing}} = []

  for (p, value) in ele.param
    mstr, order = multipole_type(p)
    if mstr == nothing || (mstr[1] != 'K' && mstr[1] != 'B' && mstr[1] != 't') ; continue; end
    pop!(ele.param, p)

    if length(vec) < order
      resize!(vec,order)
      for ix = length(vec):order-1
        vec[ix] = nothing
      end
      vec[order] = BMultipole1(n = order)
    end

    v_ord = vec[order]
    if mstr == "tilt"
      vec[order] = @set v_ord.tilt = value
    elseif occursin("l", mstr)
      if vec[order].K == NaN && vec[order].Ks == NaN && vec[order].B == NaN && vec[order].Bs == NaN
        vec[order] = @set v_ord.integrated = true
      elseif !vec[order].integrated
        throw("Combining integrated and non-integrated multipole values for a given order not permitted.")
      end
      mstr = mstr[1:end-1]

    else
      if vec[order].K == NaN && vec[order].Ks == NaN && vec[order].B == NaN && vec[order].Bs == NaN
        vec[order] = @set vec[order].integrated = false
      elseif vec[order].integrated
        throw("Combining integrated and non-integrated multipole values for a given order not permitted.")
      end
    end

    if mstr == "K";      vec[order] = @set v_ord.K  = value
    elseif mstr == "Ks"; vec[order] = @set v_ord.Ks = value
    elseif mstr == "B";  vec[order] = @set v_ord.B  = value
    elseif mstr == "Bs"; vec[order] = @set v_ord.Bs = value
    end
  end

  for (n, mp) in enumerate(vec)
    if (!isnan(mp.K) || !isnan(mp.Ks)) && (!isnan(mp.B) || !isnan(mp.Bs))
      println(mp)
      throw("Setting K or Ks for a multipole of a given order along with B or Bs is not permitted.")
    end

    if !isnan(mp.K) || !isnan(mp.Ks)
      if isnan(mp.K);  vec[n] = @set mp.K  = 0; end
      if isnan(mp.Ks); vec[n] = @set mp.Ks = 0; end
    end

    if !isnan(mp.B) || !isnan(mp.Bs)
      if isnan(mp.B);  vec[n] = @set mp.B  = 0; end
      if isnan(mp.Bs); vec[n] = @set mp.Bs = 0; end
    end
  end

  if length(vec) > 0; ele.param[:BMultipoleGroup] = BMultipoleGroup(vec); end
end

#-------------------------------------------------------------------------------------

"""
    transfer_params!(param::Dict, group::Type{T}) where T <: EleParameterGroup

""" transfer_params!

function transfer_params!(param::Dict, group::Type{T}) where T <: EleParameterGroup
  gsym = Symbol(group)
  str = ""
  for field in fieldnames(group)
    if !haskey(param, field); continue; end
    str = str * ", $field = $(param[field])"
    pop!(param, field)
  end
  # Take advantage of the fact that the group has been defined using @kwargs.
  param[gsym] = eval(Meta.parse("$group($(str[3:end]))"))
end

#-------------------------------------------------------------------------------------
# superimpose!

"""
    superimpose!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref::Eles = NULL_ELE, 
           ref_origin::EleBodyLocationSwitch = Center, ele_origin::EleBodyLocationSwitch = Center)


""" superimpose!

function superimpose!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref::Eles = NULL_ELE, 
           ref_origin::EleBodyLocationSwitch = Center, ele_origin::EleBodyLocationSwitch = Center)
  if typeof(ref) == Ele; ref = [ref]; end
  for ref_ele in ref
    superimpose1!(lat, super_ele, offset, ref_ele, offset, ref_origin, ele_origin)
  end
end

"Used by superimpose! for superimposing on on individual ref elements."
function superimpose1!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref::Ele = NULL_ELE, 
           ref_origin::EleBodyLocationSwitch = Center, ele_origin::EleBodyLocationSwitch = Center)


end




