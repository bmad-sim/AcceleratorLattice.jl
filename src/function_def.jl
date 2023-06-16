#-------------------------------------------------------------------------------------
"Lattice"

LatEle(ele::LatEle, branch::AbstractBranch, ix_ele::Int) = LatEle(ele.name, ele, branch, ix_ele, nothing)

function show_branch(branch::LatBranch)
  print(f"{get(branch.param, \"ix_branch\", \"\")} Branch: {branch.name}")
  n = maximum([6, maximum([length(e.name) for e in branch.ele])])
  for (ix, ele) in enumerate(branch.ele)
    print(f"\n  {ix:5i}  {rpad(ele.name, n)}  {rpad(string(typeof(ele)), 16)}")
  end
  return nothing
end

function show_lat(lat::Lat)
  print(f"Lat: {lat.name}")
  for branch in lat.branch
    print("\n")
    show_branch(branch)
  end
  return nothing
end

#Base.show(io::IO, lb::LatBranch) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"beam line"

Base.:*(n::Int, beamline::BeamLine) = BeamLine(beamline.name * "_mult" * string(n), 
                          [beamline for i in 1:n], beamline.multipass, beamline.orientation)
                          
Base.:*(n::Int, ele::LatEle) = BeamLine(ele.name * "_mult" * string(n), 
                          [ele for i in 1:n], false, +1)


function show_beamline(beamline::BeamLine)
  print(f"Beamline:  {beamline.name}, multipass: {beamline.multipass}, orientation: {beamline.orientation}")
  n = maximum([6, maximum([length(e.name) for e in beamline.line])])
  for (ix, item) in enumerate(beamline.line)
    print(f"\n{ix:5i}  {rpad(item.name, n)}  {rpad(string(typeof(item)), 12)}")
  end
  return nothing
end

#Base.show(io::IO, lb::BeamLine) = print(io, "Hi!")

#-------------------------------------------------------------------------------------
"Functions to construct a lat."

function latele(type::Type{T}, name::String; kwargs...) where T <: LatEle
  # kwargs is a named tuple with Symbol keys. Want keys to be Strings.
  return type(name, Dict{String,Any}(string(k)=>v for (k,v) in kwargs))
end

function beamline(name::String, line_in::Vector{T}; multipass::Bool = false, orientation::Int = +1) where T <: BeamLineItem
  return BeamLine(name, line_in, multipass, orientation)
end

function latele_to_branch!(branch, latele)
  push!(branch.ele, deepcopy(latele))
  ele = branch.ele[end]
  ele.param["ix_ele"] = length(branch.ele)
  return nothing
end

function beamline_item_to_branch!(branch::LatBranch, item::BeamLineItem)
  if isa(item, LatEle)
    latele_to_branch!(branch, item)
  elseif isa(item, Vector{LatEle})
    for subitem in item; latele_to_branch!(branch, subitem); end
  elseif isa(item, BeamLine) 
    add_to_latbranch!(branch, item)
  elseif isa(item, Vector{BeamLine})
    for subitem in item; add_to_latbranch!(branch, subitem); end
  else
    print(f"BeamLine item not recognized: {item}")
  end
  return nothing
end

function add_to_latbranch!(branch::LatBranch, beamline::BeamLine)
  for item in beamline.line; beamline_item_to_branch!(branch, item); end
  return nothing
end

function new_latbranch!(lat::Lat, beamline::BeamLine)
  push!(lat.branch, LatBranch(beamline.name, Vector{LatEle}(),
                      Dict{String,Any}("lat" => lat, "ix_branch" => length(lat.branch)+1)))
  branch = lat.branch[end]
  if branch.name == ""; branch.name = "branch" * string(length(lat.branch)); end

  latele_to_branch!(branch, beginning_Latele)
  add_to_latbranch!(branch, beamline)
  latele_to_branch!(branch, end_Latele)
  return nothing
end

function make_lat(root_line::Union{BeamLine,Vector{BeamLine}}, name::String = "")
  lat = Lat(name, Vector{LatBranch}())
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

