#-------------------------------------------------------------------------------------
"Define a beamline"

BeamLineItem(x::LatEle) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = BeamLine(x.name, x.line, deepcopy(x.param))
BeamLineItem(x::BeamLineEle) = BeamLineEle(x.ele, deepcopy(x.param))


function beamline(name::String, line::Vector{T}; multipass::Bool = false, orientation::Int = +1) where T <: BeamLineItem
  bline = BeamLine(name, BeamLineItem.(line), Dict{Symbol,Any}(:multipass => multipass, :orientation => orientation))
  for (ix, item) in enumerate(bline.line)
    item.param[:ix_beamline] = ix
  end
  return bline
end

#-------------------------------------------------------------------------------------
"beamline orientation reversal"

function Base.reverse(latele::LatEle)
  item = BeamLineItem(latele)
  item.param[:orientation] = +1
  return item
end

function Base.reverse(x::BeamLineEle)
  y = BeamLineEle(x.LatEle, deepcopy(x.param))
  y.param[:orientation] = -y.param[:orientation]
  return y
end

"""
Rule: Reversal marks a beamline as reversed but not the line elements.
Line element reversal takes place during lattice expansion.
"""
function Base.reverse(beamline::BeamLine)
  bl = BeamLine(beamline.name, beamline.line, deepcopy(beamline.param))
  bl.param[:orientation] = -bl.param[:orientation]
  return bl
end

#-------------------------------------------------------------------------------------
"beamline reflection"

"reverse() here is the Julia intrinsic."
reflect(beamline::BeamLine) = BeamLine(beamline.name * "_mult-1", reverse(beamline.line), beamline.param)

Base.:-(beamline::BeamLine) = reflect(beamline)

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.name * "_mult" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.param)
                          
Base.:*(n::Int, ele::LatEle) = (if n < 0; throw(BoundsError("Negative multiplier does not make sense.")); end,
        BeamLine(ele.name * "_mult" * string(n), [BeamLineEle(ele) for i in 1:n], false, +1))

#-------------------------------------------------------------------------------------
"lat construction."

"LatEle constructor"
LatEle(ele::LatEle, branch::LatBranch, ix_ele::Int) = LatEle(ele.name, ele, branch, ix_ele, nothing)

function latele(type::Type{T}, name::String; kwargs...) where T <: LatEle
  return type(name, Dict{Symbol,Any}(kwargs))
end

"Adds a BeamLineEle to a LatBranch under construction."
function add_beamlineele_to_latbranch!(branch::LatBranch, bele::BeamLineEle, info = nothing)
  push!(branch.ele, deepcopy(bele.ele))
  ele = branch.ele[end]
  ele.param[:ix_ele] = length(branch.ele)
  ele.param[:branch] = branch
  if info isa LatConstructionInfo
    ele.param[:orientation] = bele.param[:orientation] * info.orientation_here
    ele.param[:multipass_id] = copy(info.multipass_id)
    if length(ele.param[:multipass_id]) > 0; push!(ele.param[:multipass_id], ele.name * ":" * string(bele.param[:ix_beamline])); end
  else
    ele.param[:orientation] = +1
    ele.param[:multipass_id] = []
  end
  return nothing
end

#--------------------
"Adds a single item of a BeamLine line to the LatBranch under construction."
function add_beamline_item_to_latbranch!(branch::LatBranch, item::BeamLineItem, info::LatConstructionInfo)
  if item isa BeamLineEle
    add_beamlineele_to_latbranch!(branch, item, info)
  elseif item isa BeamLine 
    add_beamline_to_latbranch!(branch, item, info)
  else
    throw(ArgumentError(f"Beamline item not recognized: {item}"))
  end
  return nothing
end

#--------------------
"Adds a beamline to a LatBranch under construction."
function add_beamline_to_latbranch!(branch::LatBranch, beamline::BeamLine, info::LatConstructionInfo)
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

  for item in line; add_beamline_item_to_latbranch!(branch, item, info); end

  return nothing
end

#--------------------
"Adds a BeamLine to the lattice creating a new LatBranch."
function new_latbranch!(lat::Lat, beamline::BeamLine)
  push!(lat.branch, LatBranch(beamline.name, Vector{LatEle}(), Dict{Symbol,Any}()))
  branch = lat.branch[end]
  branch.param[:lat] = lat
  branch.param[:ix_branch] = length(lat.branch)
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end
  info = LatConstructionInfo([], beamline.param[:orientation], 0)

  add_beamlineele_to_latbranch!(branch, BeamLineItem(beginning_Latele))
  add_beamline_to_latbranch!(branch, beamline, info)
  add_beamlineele_to_latbranch!(branch, BeamLineItem(end_Latele))

  # Beginning and end elements inherit orientation from neighbor elements.
  branch.ele[1].param[:orientation] = branch.ele[2].param[:orientation]
  branch.ele[end].param[:orientation] = branch.ele[end-1].param[:orientation]
  return nothing
end

#--------------------
"Lattice expansion"
function lat_expansion(root_line::Union{BeamLine,Vector{BeamLine}}, name::String = "")
  lat = Lat(name, Vector{LatBranch}(), LatBranch("lord", Vector{LatEle}(), Dict{Symbol,Any}()), LatParam())
  lat.lord.param[:lat] = lat
  if root_line == nothing; root_line = root_beamline end
  
  if root_line isa BeamLine
    new_latbranch!(lat, root_line)
  else
    for subline in root_line
      new_latbranch!(lat, subline)
    end
  end
  
  if lat.name == ""; lat.name = lat.branch[1].name; end

  # Multipass: Sort slaves
  mdict = Dict()
  for branch in lat.branch
    for ele in branch.ele
      id = ele.param[:multipass_id]
      delete!(ele.param, [:multipass_id])
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
    push!(lat.lord.ele, deepcopy(val[1]))
    lord = lat.lord.ele[end]
    lord.param[:branch] = lat.lord
    lord.param[:ix_ele] = length(lat.lord.ele)
    lord.param[:slave] = Vector{LatEle}()
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "_m" * string(ix)
      ele.param[:multipass_lord] = lord
      push!(lord.param[:slave], ele)
    end
  end
  return lat
end

