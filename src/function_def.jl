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

function show_branch(branch::LatBranch)
  print(f"Branch:  {branch.name}")
  length(branch.ele) > 0 ? n = maximum([6, maximum([length(e.name) for e in branch.ele])]) : n = 6
  for (ix, ele) in enumerate(branch.ele)
    print(f"\n{ix:5i}  {rpad(ele.name, n)}  {rpad(typeof(ele), 12)}  {lpad(ele.param[:orientation], 2)}")
  end
  return nothing
end

#Base.show(io::IO, lb::LatBranch) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"Define a beamline"

BeamLineItem(x::LatEle) = BeamLineEle(x, Dict{Symbol,Any}(:multipass => false, :orientation => +1))
BeamLineItem(x::BeamLine) = x
BeamLineItem(x::BeamLineEle) = x


function beamline(name::String, line::Vector{T}; multipass::Bool = false, orientation::Int = +1) where T <: ExtendedBeamLineItem
  return BeamLine(name, BeamLineItem.(line), Dict{Symbol,Any}(:multipass => multipass, :orientation => orientation))
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
"beamline show"

function show_beamline(beamline::BeamLine)
  print(f"Beamline:  {beamline.name}, multipass: {beamline.param[:multipass]}, orientation: {beamline.param[:orientation]}")
  n = maximum([6, maximum([length(e.name) for e in beamline.ele])])
  for (ix, item) in enumerate(beamline.ele)
    if isa(item, BeamLineEle)
      print(f"\n{ix:5i}  {rpad(item.ele.name, n)}  {rpad(typeof(item.ele), 12)}  {lpad(get(item.param[:orientation], 1), 2)}")
    else  # BeamLine
      print(f"\n{ix:5i}  {rpad(item.name, n)}  {rpad(typeof(item), 12)}  {lpad(get(item.param[:orientation], 1), 2)}")
    end
  end
  return nothing
end

#Base.show(io::IO, lb::BeamLine) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"lat construction."

"Adds a BeamLineEle to a LatBranch under construction."
function add_beamlineele_to_latbranch!(branch::LatBranch, bele::BeamLineEle, orientation::Int, multipass::Bool)
  push!(branch.ele, deepcopy(bele.ele))
  ele = branch.ele[end]
  ele.param[:ix_ele] = length(branch.ele)
  ele.param[:orientation] = bele.param[:orientation] * orientation
  return nothing
end

#--------------------
"Adds a single item of a BeamLine line to the LatBranch under construction."
function add_beamline_item_to_latbranch!(branch::LatBranch, item::BeamLineItem, orientation::Int, multipass::Bool, n_loop)
  if isa(item, BeamLineEle)
    add_beamlineele_to_latbranch!(branch, item, orientation, multipass)
  elseif isa(item, BeamLine) 
    add_beamline_to_latbranch!(branch, item, orientation, multipass, n_loop)
  else
    throw(ArgumentError(f"Beamline item not recognized: {item}"))
  end
  return nothing
end

#--------------------
"Adds a beamline to a LatBranch under construction."
function add_beamline_to_latbranch!(branch::LatBranch, beamline::BeamLine, orientation::Int, multipass::Bool, n_loop)
  n_loop[] += 1
  if n_loop[] > 100; throw(InfiniteLoop("Infinite loop of beam lines calling beam lines detected.")); end

  orientation = orientation * beamline.param[:orientation]
  orientation == 1 ? line = beamline.line : line = reverse(beamline.line)
  for item in line; add_beamline_item_to_latbranch!(branch, item, orientation, multipass, n_loop); end
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

  orientation = beamline.param[:orientation]
  multipass = false
  n_loop = Ref(0)   # Use Ref since called functions need to be able to modify the value
  add_beamlineele_to_latbranch!(branch, BeamLineItem(beginning_Latele), orientation, false)
  add_beamline_to_latbranch!(branch, beamline, orientation, multipass, n_loop)
  add_beamlineele_to_latbranch!(branch, BeamLineItem(end_Latele), orientation, false)
  return nothing
end

#--------------------
"Lattice expansion"
function make_lat(root_line::Union{BeamLine,Vector{BeamLine}}, name::String = "")
  lat = Lat(name, Vector{LatBranch}(), 
              LatBranch("lord", Vector{LatEle}(), Dict{Symbol,Any}()), LatParam())
  if root_line == nothing; root_line = root_beamline end
  
  if isa(root_line, BeamLine)
    new_latbranch!(lat, root_line)
  else
    for subline in root_line
      new_latbranch!(lat, subline)
    end
  end
  
  if lat.name == ""; lat.name = lat.branch[1].name; end
  return lat
end

