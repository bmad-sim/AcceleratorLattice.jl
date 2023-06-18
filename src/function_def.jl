#-------------------------------------------------------------------------------------
"To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

#-------------------------------------------------------------------------------------
"Lattice"

LatEle(ele::LatEle, branch::LatBranch, ix_ele::Int) = LatEle(ele.name, ele, branch, ix_ele, nothing)

function latele(type::Type{T}, name::String; kwargs...) where T <: LatEle
  return type(name, Dict{Symbol,Any}(kwargs))
end

function show_branch(branch::LatBranch)
  print(f"{get(branch.param, :ix_branch, \"-\")} Branch: {branch.name}")
  n = maximum([6; [length(e.name) for e in branch.ele]])
  for (ix, ele) in enumerate(branch.ele)
    print(f"\n  {ix:5i}  {rpad(ele.name, n)} {rpad(typeof(ele), 16)}  {lpad(get(ele.param, :orientation, 1), 2)}")
  end  
  return nothing
end

function show_lat(lat::Lat)
  print(f"Lat: {lat.name}")
  for branch in lat.branch
    print("\n")
    show_branch(branch)
  end

  print("\n")
  show_branch(lat.lord)
  return nothing
end

#Base.show(io::IO, lb::LatBranch) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"Define a beamline"

function beamline(name::String, line_in::Vector{T}; multipass::Bool = false, orientation::Int = +1) where T <: LatBranchEleItem
  return LatBranch(name, line_in, Dict{Symbol,Any}(:multipass => multipass, :orientation => orientation))
end

#-------------------------------------------------------------------------------------
"beamline orientation reversal"

function Base.reverse(latele::LatEle)
  ele = deepcopy(latele)
  ele.param[:orientation] = -get(ele.param, :orientation, +1)
  return ele
end

"""
Rule: Reversal marks a beamline as reversed but not the line elements.
Line element reversal takes place during lattice expansion.
"""
function Base.reverse(beamline::LatBranch)
  line = deepcopy(beamline)
  line.param[:orientation] = -get(line.param, :orientation, +1)
  return line
end

#-------------------------------------------------------------------------------------
"beamline reflection"

"reverse() here is the Julia intrinsic."
reflect(beamline::LatBranch) = LatBranch(beamline.name * "_mult-1", reverse(beamline.ele), beamline.param)

Base.:-(beamline::LatBranch) = reflect(beamline)

Base.:*(n::Int, beamline::LatBranch) = LatBranch(beamline.name * "_mult" * string(n), 
                          [(n > 0 ? beamline : reflect(beamline)) for i in 1:abs(n)], beamline.param)
                          
Base.:*(n::Int, ele::LatEle) = (if n < 0; throw(BoundsError("Negative multiplier does not make sense.")); end,
        LatBranch(ele.name * "_mult" * string(n), [ele for i in 1:n], false, +1))

#-------------------------------------------------------------------------------------
"beamline show"

function show_beamline(beamline::LatBranch)
  print(f"Beamline:  {beamline.name}, multipass: {beamline.param[:multipass]}, orientation: {beamline.param[:orientation]}")
  n = maximum([6, maximum([length(e.name) for e in beamline.ele])])
  for (ix, item) in enumerate(beamline.ele)
    print(f"\n{ix:5i}  {rpad(item.name, n)}  {rpad(typeof(item), 12)}  {lpad(get(item.param[:orientation], 1), 2)}")
  end
  return nothing
end

#Base.show(io::IO, lb::LatBranch) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"lat construction."

function add_latele_to_latbranch!(branch::LatBranch, latele::LatEle, orientation::Int)
  push!(branch.ele, deepcopy(latele))
  ele = branch.ele[end]
  ele.param[:ix_ele] = length(branch.ele)
  ele.param[:orientation] = get(ele.param, :orientation, 1) * orientation
  return nothing
end

function add_beamline_item_to_branch!(branch::LatBranch, item::LatBranchEleItem, orientation::Int)
  if isa(item, LatEle)
    add_latele_to_latbranch!(branch, item, orientation)
  elseif isa(item, LatBranch) 
    add_beamline_to_latbranch!(branch, item, orientation)
  else
    throw(ArgumentError(f"LatBranch item not recognized: {item}"))
  end
  return nothing
end

function add_beamline_to_latbranch!(branch::LatBranch, beamline::LatBranch, orientation::Int)
  orientation = orientation * beamline.param[:orientation]
  orientation == 1 ? ele = beamline.ele : ele = reverse(beamline.ele)
  for item in ele; add_beamline_item_to_branch!(branch, item, orientation); end
  return nothing
end

function new_latbranch!(lat::Lat, beamline::LatBranch)
  push!(lat.branch, LatBranch(beamline.name, Vector{LatEle}(), beamline.param))
  branch = lat.branch[end]
  branch.param[:lat] = lat
  branch.param[:ix_branch] = length(lat.branch)
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end

  orientation = branch.param[:orientation]
  add_latele_to_latbranch!(branch, beginning_Latele, orientation)
  add_beamline_to_latbranch!(branch, beamline, orientation)
  add_latele_to_latbranch!(branch, end_Latele, orientation)
  return nothing
end

function make_lat(root_line::Union{LatBranch,Vector{LatBranch}}, name::String = "")
  lat = Lat(name, Vector{LatBranch}(), 
              LatBranch("lord", Vector{LatEle}(), Dict{Symbol,Any}()), LatParam())
  if root_line == nothing; root_line = root_beamline end
  
  if isa(root_line, LatBranch)
    new_latbranch!(lat, root_line)
  else
    for subline in root_line
      new_latbranch!(lat, subline)
    end
  end
  
  if lat.name == ""; lat.name = lat.branch[1].name; end
  return lat
end

