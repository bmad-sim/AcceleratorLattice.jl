#-------------------------------------------------------------------------------------
# Ele

beginning_ele = Marker("beginning", Dict{Symbol,Any}(:s => 0, :len => 0))
end_ele       = Marker("end", Dict{Symbol,Any}())

#-------------------------------------------------------------------------------------
# branch

branch(lat::Lat, ix::Int) = lat.branch[ix]

function branch(lat::Lat, who) 
  for branch in lat.branch
    if branch.name == who; return branch; end
  end
  return nothing
end

#-------------------------------------------------------------------------------------
# BeamLineItem

BeamLineItem(x::Ele) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = BeamLine(x.name, x.line, deepcopy(x.param))
BeamLineItem(x::BeamLineEle) = BeamLineEle(x.ele, deepcopy(x.param))

#-------------------------------------------------------------------------------------
# beamline

function beamline(name::AbstractString, line::Vector{T}; geometry::Type{<:Geometry} = OpenGeom, 
                                    multipass::Bool = false, orientation::Int = +1) where T <: BeamLineItem
  bline = BeamLine(name, BeamLineItem.(line), Dict{Symbol,Any}(:geometry => geometry, 
                                                   :multipass => multipass, :orientation => orientation))
  for (ix, item) in enumerate(bline.line)
    item.param[:ix_beamline] = ix
  end
  return bline
end

#-------------------------------------------------------------------------------------
# Base.reverse

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
# beamline reflection

"reverse() here is the Julia intrinsic."
reflect(beamline::BeamLine) = BeamLine(beamline.name * "_mult-1", reverse(beamline.line), beamline.param)

Base.:-(beamline::BeamLine) = reflect(beamline)

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.name * "_mult" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.param)
                          
Base.:*(n::Int, ele::Ele) = (if n < 0; throw(BoundsError("Negative multiplier does not make sense.")); end,
        BeamLine(ele.name * "_mult" * string(n), [BeamLineEle(ele) for i in 1:n], false, +1))

#-------------------------------------------------------------------------------------
# add_beamlineele_to_branch!

"Adds a BeamLineEle to a Branch under construction."
function add_beamlineele_to_branch!(branch::Branch, bele::BeamLineEle, info = nothing)
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

#-------------------------------------------------------------------------------------#--------------------
# add_beamline_item_to_branch!

"Adds a single item of a BeamLine line to the Branch under construction."
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

"Adds a beamline to a Branch under construction."
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

"Adds a BeamLine to the lattice creating a new Branch."
function new_tracking_branch!(lat::Lat, beamline::BeamLine)
  push!(lat.branch, Branch(beamline.name, Vector{Ele}(), Dict{Symbol,Any}(:geometry => beamline.param[:geometry])))
  branch = lat.branch[end]
  branch.param[:lat] = lat
  branch.param[:ix_branch] = length(lat.branch)
  branch.param[:type] = TrackingBranch
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end
  info = LatConstructionInfo([], beamline.param[:orientation], 0)

  add_beamlineele_to_branch!(branch, BeamLineItem(beginning_ele))
  add_beamline_to_branch!(branch, beamline, info)
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

function lat_expansion(name::AbstractString, root_line::Union{BeamLine,Vector{BeamLine}})
  lat = Lat(name, Vector{Branch}(), Dict{Symbol,Any}(), BmadGlobal())

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
  mp_lord_branch = new_lord_branch(lat, "multipass_lord")

  # Multipass: Sort slaves
  mdict = Dict()
  for branch in lat.branch
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
    push!(mp_lord_branch.ele, deepcopy(val[1]))
    lord = mp_lord_branch.ele[end]
    delete!(lord.param, :multipass_id)
    lord.param[:branch] = mp_lord_branch
    lord.param[:ix_ele] = length(mp_lord_branch.ele)
    lord.param[:slave] = Vector{Ele}()
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "!mp" * string(ix)
      ele.param[:multipass_lord] = lord
      push!(lord.param[:slave], ele)
    end
  end

  lat_bookkeeper!(lat)
  return lat
end

# lat_expansion version without lattice name argument.
lat_expansion(root_line::Union{BeamLine,Vector{BeamLine}}) = lat_expansion("Lattice", root_line)

#-------------------------------------------------------------------------------------
# superimpose!

"""
"""
function superimpose!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref::Eles = NULL_ELE, 
           ref_origin::Type{<:EleBodyLocation} = Center, ele_origin::Type{<:EleBodyLocation} = Center)
  if typeof(ref) == Ele; ref = [ref]; end
  for ref_ele in ref
    superimpose1!(lat, super_ele, offset, ref_ele, offset, ref_origin, ele_origin)
  end
end

"Used by superimpose! for superimposing on on individual ref elements."
function superimpose!(lat::Lat, super_ele::Ele; offset::Float64 = 0, ref::Ele = NULL_ELE, 
           ref_origin::Type{<:EleBodyLocation} = Center, ele_origin::Type{<:EleBodyLocation} = Center)


end




