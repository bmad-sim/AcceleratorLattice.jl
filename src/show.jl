#-------------------------------------------------------------------------------------
"To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

#-------------------------------------------------------------------------------------
# ele_name

"""
    function ele_name(ele::Ele, template::AbstractString = "")

Returns a string containing the element name. The `template` string determines the format
of the output string.

### Input:

- `ele`      -- Element whose name is to be outputted.
- `template` -- Output format.

### Output:

String containing the element name.

### Notes:

The output string is formed by starting with the `template` string.
The `template` string is scanned and all `token` sub-strings are replaced by the appropriate string.
Tokens are two character strings:
  "@N" is replaced by ele.name
  "!#" is replaced by `branch.name>>ix_ele` where `branch` = ele[:branch] is the branch that the 
          element is in and `ix_ele` = ele[:ix_ele] is the element index.
  "&#" is replaced by `ix_ele` if there is only one branch in the lattice 
        else the token is replaced the same as "!#".
  "%#" is replaced by `ix_ele` if the element is in branch 1 else the token is replaced the same as "!#".

If the `template` is blank (""), the `template` is taken to be "\"@N\" (!#)"

### Examples:

If `ele` has ele.name = "q02w", ele[:ix_ele] = 7 and the element lives in branch named "ring":
  template      output
  --------      ------
 @N             q02w
 !#             fodo>>7
 "@N" (!#)      "q02w" (fodo>>7)  
 &#             `7` if there is only one branch in the lattice.
 %#             `7` if fodo is branch 1.

"""
function ele_name(ele::Ele, template::AbstractString = "")
  if !haskey(ele.param, :ix_ele); return ele.name; end
  if template == ""; template = "\"@N\" (!#)"; end

  ix_ele = ele.param[:ix_ele]
  branch = ele.param[:branch]
  lat = branch.param[:lat]
  str = replace(template, "@N" => ele.name)
  str = replace(str, "%#" => (branch === lat.branch[1] ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "&#" => (lat.branch == 1 ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "!#" => branch.name * ">>" * string(ix_ele))
  return str
end

#-------------------------------------------------------------------------------------
# str_param_value

function str_param_value(param::Dict, key, default::AbstractString = "???")
  who = get(param, key, nothing)
  return str_param_value(who, default)
end

function str_param_value(who, default::AbstractString = "???")
  if who == nothing
    return default
  elseif who isa Ele
    return ele_name(who)
  elseif who isa Vector{Ele}
    return "[" * join([ele_name(ele) for ele in who], ", ") * "]"
  elseif who isa Branch
    return f"Branch {who.param[:ix_branch]}: {str_quote(who.name)}"
  elseif who isa String
    return str_quote(who)
  else
    return string(who)
  end
end

#-------------------------------------------------------------------------------------
# Show Ele

function Base.show(io::IO, ele::Ele)
  println(io, f"Ele: {ele_name(ele)}   {typeof(ele)}")

  param = ele.param
  if length(param) > 0   # Need test since will bomb on zero length dict
    n = maximum([length(key) for key in keys(param)]) + 4 

    # Print non-group, non-queued parameters first.
    # Bookkeeping: If queued param has same value as grouped param, remove queued param.
    queue = []
    for key in sort(collect(keys(param)))
      val = param[key]
      if typeof(val) <: EleParameterGroup; continue; end
      pinfo = ele_param_info(key)
      if pinfo.parent_group != Nothing
        parent = Symbol(pinfo.parent_group)
        if haskey(param, parent) && param[key] == ele_group_value(param[parent], key)
          pop!(param, key)
        else
          push!(queue, key); continue
        end
      end

      if key == :name; continue; end
      kstr = rpad(string(key), n)
      vstr = str_param_value(param, key)
      ele_print_line(io, f"  {kstr} {vstr} {units(key)}", 45, description(key))
    end

    # Print groups
    for key in sort(collect(keys(param)))
      group = param[key]
      if !(typeof(group) <: EleParameterGroup); continue; end
      show_elegroup(io, group)
    end

    # Print queued params.
    if length(queue) > 0
      println(io, "  Queued for Bookkeeping:")
      for key in queue
        kstr = rpad(string(key), n)
        vstr = str_param_value(param, key)
        ele_print_line(io, f"    {kstr} {vstr} {units(key)}", 45, description(key))
      end
    end
  end

  return nothing
end

function show_elegroup(io::IO, group::T) where T <: EleParameterGroup
  n = maximum(length(field) for field in fieldnames(typeof(group))) + 4
  println(io, f"  {typeof(group)}:")
  for field in fieldnames(typeof(group))
    kstr = rpad(string(field), n)
    vstr = str_param_value(Base.getproperty(group, field))
    ele_print_line(io, f"    {kstr} {vstr} {units(field)}", 45, description(field))
  end
end

function show_elegroup(io::IO, group::BMultipoleGroup)
  n = maximum(length(field) for field in fieldnames(typeof(group))) + 4
  println(io, f"  {typeof(group)}:")
  println(io, f"    Order Integrated{lpad(\"Tilt (rad)\",24)}{lpad(\"K/B\",24)}{lpad(\"Ks/Bs\",24)}")
  for v in group.vec
    v.integrated ? l = "l" : l = ""
    n = v.n
    if !isnan(v.K)
      println(io, f"{lpad(n,9)}      {lpad(v.integrated,5)}{lpad(v.tilt,24)}{lpad(v.K,24)}{lpad(v.Ks,24)}    K{n}{l}  K{n}s{l}")
    else
      println(io, f"{lpad(n,9)}      {lpad(v.integrated,5)}{lpad(v.tilt,24)}{lpad(v.B,24)}{lpad(v.Bs,24)}    B{n}{l}  B{n}s{l}")
    end
  end
end

function show_elegroup(io::IO, group::EMultipoleGroup)
  n = maximum(length(field) for field in fieldnames(typeof(group))) + 4
  println(io, f"  {typeof(group)}:")
  println(io, f"    Order{lpad(\"Tilt (rad)\",24)}{lpad(\"E\",24)}{lpad(\"Es\",24)}")
  for (n, v) in enumerate(group.vec)
    if v == nothing; continue; end
    println(io, f"{lpad(n,9)}{lpad(v.E,24)}{lpad(v.tilt,24)}{lpad(v.Es,24)}")
  end
end

function ele_print_line(io::IO, str::String, ix_des::Int, descrip::String)
  if length(str) < ix_des - 2
    println(io, f"{rpad(str, ix_des)}{descrip}")
  else
    println(io, str)
    println(io, " "^45 * descrip)
  end
end

Base.show(io::IO, ::MIME"text/plain", ele::Ele) = Base.show(io, ele::Ele)

#-------------------------------------------------------------------------------------
# Show Vector{ele}

function Base.show(io::IO, eles::Vector{Ele})
  println(io, f"{length(eles)}-element Vector{{Ele}}:")
  for ele in eles
    println(io, " " * ele_name(ele))
  end
end

Base.show(io::IO, ::MIME"text/plain", eles::Vector{Ele}) = Base.show(io::IO, eles)

#-------------------------------------------------------------------------------------
# Show Lat

function Base.show(io::IO, lat::Lat)
  println(io, f"Lat: {str_quote(lat.name)}")
  for branch in lat.branch
    show(io, branch)
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", lat::Lat) = Base.show(stdout, lat)

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
        f"  {lpad(ele.param[:orientation], 2)}  {str_param_value(ele.param, :multipass_lord, \"\")}{str_param_value(ele.param, :slave, \"\")}")
    end
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", branch::Branch) = Base.show(stdout, branch)

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
  println(io, f"Beamline:  {str_quote(bl.name)}, multipass: {bl.param[:multipass]}, orientation: {bl.param[:orientation]}")
  n = 6
  for item in bl.line
    if item isa BeamLineEle
      n = maximum([n, length(item.ele.name)]) + 2
    else  # BeamLine
      n = maximum([n, length(item.name)]) + 2
    end
  end

  for (ix, item) in enumerate(bl.line)
    if item isa BeamLineEle
      println(io, f"{ix:5i}  {rpad(str_quote(item.ele.name), n)}  {rpad(typeof(item.ele), 12)}  {lpad(item.param[:orientation], 2)}")
    else  # BeamLine
      println(io, f"{ix:5i}  {rpad(str_quote(item.name), n)}  {rpad(typeof(item), 12)}  {lpad(item.param[:orientation], 2)}")
    end
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", bl::BeamLine) = Base.show(io, bl)

#-----------------------------------------------------------------------------------------
# Show Dict{String, Vector{Ele}}

function Base.show(io::IO, eled::Dict{String, Vector{Ele}})
  println(io, f"Dict{{AbstractString, Vector{{Ele}}}} with {length(eled)} entries.")
end

Base.show(io::IO, ::MIME"text/plain", eled::Dict{String, Vector{Ele}}) = Base.show(stdout, eled)
