#-------------------------------------------------------------------------------------
"To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

#-------------------------------------------------------------------------------------
"LatEle"

function latele_name(ele::LatEle, template::String = "")
  if !haskey(ele.param, :ix_ele); return ele.name; end
  if template == ""; template = "@N (!#)"; end

  ix_ele = ele.param[:ix_ele]
  branch = ele.param[:branch]
  lat = branch.param[:lat]
  str = replace(template, "@N" => ele.name)
  str = replace(str, "%#" => (branch === lat.branch[1] ? ix_ele : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "&#" => (lat.branch == 1 ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "!#" => branch.name * ">>" * string(ix_ele))
  return str
end


function show_name(param, key, template::String = "")
  who = get(param, key, nothing)
  if who == nothing
    return ""
  elseif who isa LatEle
    return latele_name(who, template)
  elseif who isa Vector
    return "[" * join([latele_name(ele, template) for ele in who], ", ") * "]"
  else
    return "???"
  end
end


function show_latele(ele::LatEle)
  println(f"{latele_name(ele)}:   {typeof(ele)}")
  for (key, val) in ele.param
    kstr = rpad(repr(key), 16)
    if val isa LatEle
      println(f"  {kstr} {latele_name(val)}")
    elseif val isa LatBranch
      println(f"  {kstr} {val.name}")
    elseif val isa Vector{LatEle}
      println(f"  {kstr} [{join([latele_name(ele) for ele in val], \", \")}]")
    else
      println(f"  {kstr} {val}")
    end
  end
  return nothing
end

Base.show(io::IO, ele::LatEle) = show_latele(ele)

#-------------------------------------------------------------------------------------
"Lattice"

function show_lat(lat::Lat)
  println(f"Lat: {lat.name}")
  for branch in lat.branch
    show_branch(branch)
  end
  show_branch(lat.lord)
  return nothing
end

function show_branch(branch::LatBranch)
  println(f"{get(branch.param, :ix_branch, \"-\")} Branch: {branch.name}")
  if length(branch.ele) == 0 
    println("     --- No Elements ---")
  else
    n = maximum([6, maximum([length(e.name) for e in branch.ele])])
    for (ix, ele) in enumerate(branch.ele)
      println(f"  {ix:5i}  {rpad(ele.name, n)} {rpad(typeof(ele), 16)}" *
        f"  {lpad(ele.param[:orientation], 2)}  {show_name(ele.param, :multipass_lord)}{show_name(ele.param, :slave)}")
    end
  end
  return nothing
end

Base.show(io::IO, lb::LatBranch) = show_branch(lb)
Base.show(io::IO, lat::Lat) = show_lat(lat)

#-------------------------------------------------------------------------------------
"beamline show"

function show_beamline(beamline::BeamLine)
  println(f"Beamline:  {beamline.name}, multipass: {beamline.param[:multipass]}, orientation: {beamline.param[:orientation]}")
  n = 6
  for item in beamline.line
    if item isa BeamLineEle
      n = maximum([n, length(item.ele.name)])
    else  # BeamLine
      n = maximum([n, length(item.name)])
    end
  end

  for (ix, item) in enumerate(beamline.line)
    if item isa BeamLineEle
      println(f"{ix:5i}  {rpad(item.ele.name, n)}  {rpad(typeof(item.ele), 12)}  {lpad(item.param[:orientation], 2)}")
    else  # BeamLine
      println(f"{ix:5i}  {rpad(item.name, n)}  {rpad(typeof(item), 12)}  {lpad(item.param[:orientation], 2)}")
    end
  end
  return nothing
end

Base.show(io::IO, bl::BeamLine) = show_beamline(bl)

