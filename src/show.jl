#-------------------------------------------------------------------------------------
"To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

#-------------------------------------------------------------------------------------
# ele_name

function ele_name(ele::Ele, template::AbstractString = "")
  if !haskey(ele.param, :ix_ele); return ele.name; end
  if template == ""; template = "\"@N\" (!#)"; end

  ix_ele = ele.param[:ix_ele]
  branch = ele.param[:branch]
  lat = branch.param[:lat]
  str = replace(template, "@N" => ele.name)
  str = replace(str, "%#" => (branch === lat.branch[1] ? ix_ele : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "&#" => (lat.branch == 1 ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "!#" => branch.name * ">>" * string(ix_ele))
  return str
end

#-------------------------------------------------------------------------------------
# str_param_value

function str_param_value(param::Dict, key, template::AbstractString = "")
  who = get(param, key, nothing)
  if who == nothing
    return "-"
  elseif who isa Ele
    return ele_name(who, template)
  elseif who isa Vector{Ele}
    return "[" * join([ele_name(ele, template) for ele in who], ", ") * "]"
  elseif who isa Branch
    return f"Branch {who.param[:ix_branch]}: {str_quote(who.name)}"
  elseif who isa String
    return str_quote(who)
  else
    return string(who)
  end
end

#-------------------------------------------------------------------------------------
# Show Vector{Ele}

function Base.show(io::IO, vec::Vector{Ele}) 
  print(f"[{join([v.name for v in vec], ',')}]")
end

Base.show(vec::Vector{Ele}) = Base.show(stdout, vec::Vector{Ele}) 

#-------------------------------------------------------------------------------------
# Show Ele

function Base.show(io::IO, ele::Ele)
  n = maximum([length(key) for key in keys(ele.param)]) + 4 
  println(io, f"Ele: {ele_name(ele)}   {typeof(ele)}")
  for (key, val) in ele.param
    kstr = rpad(repr(key), n)
    vstr = str_param_value(ele.param, key)
    println(io, f"  {kstr} {vstr}")
  end
  return nothing
end

Base.show(ele::Ele) = Base.show(stdout, ele::Ele)

#-------------------------------------------------------------------------------------
# Show Vector{ele}

function Base.show(io::IO, eles::Vector{Ele})
  println(io, f"{length(eles)}-element Vector{{Ele}}:")
  for ele in eles
    println(io, " " * ele_name(ele))
  end
end

Base.show(io::IO, ::MIME"text/plain", eles::Vector{Ele}) = Base.show(stdout, eles)
Base.show(eles::Vector{Ele}) = Base.show(stdout, eles)

#-------------------------------------------------------------------------------------
# Show Lat

function Base.show(io::IO, lat::Lat)
  println(io, f"Lat: {str_quote(lat.name)}")
  for branch in lat.branch
    show(io, branch)
  end
  return nothing
end

Base.show(lat::Lat) = Base.show(stdout, lat)

#-------------------------------------------------------------------------------------
# Show Branch

function Base.show(io::IO, branch::Branch)
  g_str = ""
  if haskey(branch.param, :geometry); g_str = f":geometry => {branch.param[:geometry]}"; end
  println(io, f"Branch {branch[:ix_branch]}: {str_quote(branch.name)}  {g_str}")

  if length(branch.ele) == 0 
    println(io, "     --- No Elements ---")
  else
    n = maximum([12, maximum([length(e.name) for e in branch.ele])]) + 2
    for ele in branch.ele
      println(io, f"  {ele.param[:ix_ele]:5i}  {rpad(str_quote(ele.name), n)} {rpad(typeof(ele), 16)}" *
        f"  {lpad(ele.param[:orientation], 2)}  {str_param_value(ele.param, :multipass_lord)}{str_param_value(ele.param, :slave)}")
    end
  end
  return nothing
end

Base.show(branch::Branch) = Base.show(stdout, branch)

#-------------------------------------------------------------------------------------
# Show Vector{Branch}

function Base.show(io::IO, branches::Vector{Branch})
  n = maximum([length(b.name) for b in branches]) + 4
  for branch in branches
    g_str = ""
    if haskey(branch.param, :geometry); g_str = f", :geometry => {branch.param[:geometry]}"; end
    println(io, f"{branch[:ix_branch]}: {rpad(str_quote(branch.name), n)} #Elements{lpad(length(branch.ele), 5)}{g_str}")
  end
end

Base.show(io::IO, ::MIME"text/plain", branches::Vector{Branch}) = Base.show(stdout, branches)

#-------------------------------------------------------------------------------------
# Show Beamline

function Base.show(io::IO, bl::BeamLine)
  println(io, f"Beamline:  {str_quote{beamline.name}}, multipass: {beamline.param[:multipass]}, orientation: {beamline.param[:orientation]}")
  n = 6
  for item in beamline.line
    if item isa BeamLineEle
      n = maximum([n, length(item.ele.name)]) + 2
    else  # BeamLine
      n = maximum([n, length(item.name)]) + 2
    end
  end

  for (ix, item) in enumerate(beamline.line)
    if item isa BeamLineEle
      println(io, f"{ix:5i}  {rpad(str_quote(item.ele.name), n)}  {rpad(typeof(item.ele), 12)}  {lpad(item.param[:orientation], 2)}")
    else  # BeamLine
      println(io, f"{ix:5i}  {rpad(str_quote(item.name), n)}  {rpad(typeof(item), 12)}  {lpad(item.param[:orientation], 2)}")
    end
  end
  return nothing
end

Base.show(bl::BeamLine) = Base.show(stdout, bl)

#-----------------------------------------------------------------------------------------
# Show Dict{String, Vector{Ele}}

function Base.show(io::IO, eled::Dict{String, Vector{Ele}})
  println(io, f"Dict{{AbstractString, Vector{{Ele}}}} with {length(eled)} entries.")
end

Base.show(io::IO, ::MIME"text/plain", eled::Dict{String, Vector{Ele}}) = Base.show(stdout, eled)
