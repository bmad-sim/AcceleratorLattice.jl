#---------------------------------------------------------------------------------------------------
# show_column2

"""
    show_column2 = Dict{Type{T} where T <: EleParameterGroup, Dict{Symbol,Symbol}}

Dict used by the `show(::ele)` command which contains the information as to what to put in the
second column when displaying the elements of an element parameter group using the two column format.

Example `show_column2` key/value pair:
```julia
  FloorPositionGroup => Dict{Symbol,Symbol}(
    :r                => :q,
    :phi              => :psi,
  )
```
In this example, when printing the `FloorPositionGroup`, in the line showing the `.r` component,
the `.r` component will be in the first column and the `.q` component will be in the
second column.

When defining custom parameter groups, key/value pairs can be added to `show_column2` as needed.
""" show_column2

show_column2 = Dict{Type{T} where T <: EleParameterGroup, Dict{Symbol,Symbol}}(
  LordSlaveGroup => Dict{Symbol,Symbol}(
    :lord_status      => :slave_status,
  ),

  LengthGroup => Dict{Symbol,Symbol}(
    :L                => :orientation,
    :s                => :s_downstream,
  ),

  FloorPositionGroup => Dict{Symbol,Symbol}(
    :r                => :q,
    :phi              => :psi,
  ),

  PatchGroup => Dict{Symbol,Symbol}(
    :offset           => :tilt,
    :x_pitch          => :y_pitch,
    :E_tot_offset     => :t_offset,
    :E_tot_exit       => :pc_exit,
    :flexible         => :User_sets_length,
  ),

  ReferenceGroup => Dict{Symbol,Symbol}(
    :species_ref      => :species_ref_exit,
    :pc_ref           => :pc_ref_exit,
    :E_tot_ref        => :E_tot_ref_exit,
    :time_ref         => :time_ref_exit,
  ),

  AlignmentGroup => Dict{Symbol,Symbol}(
    :offset           => :offset_tot,
    :x_pitch          => :x_pitch_tot,
    :y_pitch          => :y_pitch_tot,
    :tilt             => :tilt_tot,
  ),

  BendGroup => Dict{Symbol,Symbol}(
    :g                => :bend_field,
    :angle            => :rho,
    :L_chord          => :L_sagitta,
    :e1               => :e1_rect,
    :e2               => :e2_rect,
    :fint1            => :hgap1,
    :fint2            => :hgap2,
  ),

  ApertureGroup => Dict{Symbol,Symbol}(
    :x_limit          => :y_limit,
    :aperture_at      => :aperture_type,
  ),

  StringGroup => Dict{Symbol,Symbol}(
    :type             => :alias,
  ),

  GirderGroup => Dict{Symbol,Symbol}(
    :origin_ele       => :origin_ele_ref_pt,
    :dtheta           => :dr,
    :dphi             => :dpsi,
  ),

  RFFieldGroup => Dict{Symbol,Symbol}(
    :voltage          => :gradient,
    :phase            => :rad2pi,
  ),

  LCavityGroup => Dict{Symbol,Symbol}(
    :voltage_ref      => :gradient_ref,
    :voltage_err      => :gradient_err,
    :voltage_tot      => :gradient_tot,
  ),

  RFMasterGroup => Dict{Symbol,Symbol}(
    :do_auto_amp      => :do_auto_phase,
  ),

  TrackingGroup => Dict{Symbol,Symbol}(
    :tracking_method  => :field_calc,
    :num_steps        => :ds_step,
  ),
)

#---------------------------------------------------------------------------------------------------
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

If the `template` is blank (""), the `template` is taken to be "\"@N\" (!#)".

If the element is not associated with a lattice, just the element name is returned.

### Examples:

If `ele` has ele.name = "q02w", ele[:ix_ele] = 7 and the element lives in branch named "ring":
  template      output
  --------      ------
 @N             q02w
 !#             fodo>>7
 "@N" (!#)      "q02w" (fodo>>7)  
 &#             `7` if there is only one branch in the lattice.
 %#             `7` if fodo is branch 1.

""" ele_name

function ele_name(ele::Ele, template::AbstractString = "")
  if !haskey(ele.pdict, :ix_ele); return ele.name; end
  if template == ""; template = "\"@N\" (!#)"; end

  ix_ele = ele.pdict[:ix_ele]
  branch = ele.pdict[:branch]
  lat = branch.pdict[:lat]
  str = replace(template, "@N" => ele.name)
  str = replace(str, "%#" => (branch === lat.branch[1] ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "&#" => (lat.branch == 1 ? string(ix_ele) : branch.name * ">>" * string(ix_ele)))
  str = replace(str, "!#" => branch.name * ">>" * string(ix_ele))
  return str
end

#---------------------------------------------------------------------------------------------------
# ele_param_str

"""
    Internal: ele_param_str(pdict::Dict, key; default::AbstractString = "???")
    Internal: ele_param_str(vec_var::Vector{ControlVar}; default::AbstractString = "???")
    Internal: ele_param_str(ele::Ele, key::Symbol; default::AbstractString = "???", format = "")
    Internal: ... and others too numerous to mention ...

Routine to take a set of parameters and values and form a string with this information.
used by the `show` routines for showing element, branch, and lat info.
""" ele_param_str


function ele_param_str(pdict::Dict, key; default::AbstractString = "???")
  who = get(pdict, key, nothing)
  return ele_param_str(who, default = default)
end

function ele_param_str(vec_var::Vector{ControlVar}; default::AbstractString = "???")
  if length(vec_var) == 0; return "No Vars"; end
  str = ""
  for var in vec_var
    str = str * f", {var.name} = {var.value}"
    if var.old_value != var.value
      str = str * f" (old = {var.old_value})"
    end
  end
  return "[" * str[3:end] * "]"
end

function ele_param_str(who::Vector{T}; default::AbstractString = "???") where T <: ControlSlave
  if length(who) == 0; return "No Slave Parameters"; end
  return f"[{length(who)} ControlSlaves]"
end

function ele_param_str(ele::Ele, key::Symbol; default::AbstractString = "???", format = "")
  try
    val = Base.getproperty(ele, key)
    if format == ""
      return val
    else
      return eval(Meta.parse("f\"{($val):$format}\""))
    end
  catch
    return default
  end
end

ele_param_str(who::Nothing; default::AbstractString = "???") = default
ele_param_str(ele::Ele; default::AbstractString = "???") = ele_name(ele)
ele_param_str(vec_ele::Vector{Ele}; default::AbstractString = "???") = "[" * join([ele_name(ele) for ele in vec_ele], ", ") * "]"
ele_param_str(branch::Branch; default::AbstractString = "???") = f"Branch {branch.pdict[:ix_branch]}: {str_quote(branch.name)}"
ele_param_str(str::String; default::AbstractString = "???") = str_quote(str)
ele_param_str(who; default::AbstractString = "???") = string(who)


#---------------------------------------------------------------------------------------------------
# show_ele

"""
    function show_ele(io::IO, ele::Ele, docstring = false)

Prints lattice element info. This function is used to extend Base.show.
To simply print the element name use the `ele_name(ele)` function.
""" show_ele 

function show_ele(io::IO, ele::Ele, docstring = false)
  eletype = typeof(ele)
  println(io, f"Ele: {ele_name(ele)}   {eletype}")
  nn = 18

  pdict = ele.pdict
  if length(pdict) > 0   # Need test since will bomb on zero length dict
    # Print non-group, non-changed parameters first.
    for key in sort(collect(keys(pdict)))
      val = pdict[key]
      if typeof(val) <: EleParameterGroup || key == :changed; continue; end
      if key == :name; continue; end
      nn2 = max(nn, length(string(key)))
      kstr = rpad(string(key), nn2)
      vstr = ele_param_str(pdict, key)
      if docstring
        ele_print_line(io, f"  {kstr} {vstr} {units(key)}", description(key))
      else
        println(io, f"  {kstr} {vstr} {units(key)}")
      end
    end

    # Print element parameter groups (does not include changed)
    for key in sort(collect(keys(pdict)))
      group = pdict[key]
      if !(typeof(group) <: EleParameterGroup); continue; end
      show_elegroup(io, group, docstring)
    end

    # Finally print changed params.
    changed = pdict[:changed]
    if length(changed) > 0
      println(io, "  changed:")
      for (key, value) in changed
        nn2 = max(nn, length(string(key)))
        kstr = rpad(string(key), nn2)
        vstr = ele_param_str(changed, key)
        if docstring
          ele_print_line(io, f"    {kstr} {vstr} {units(key, eletype)}", description(key, eletype))
        else
          println(io, f"    {kstr} {vstr} {units(key, eletype)}")
        end
      end
    end
  end

  return nothing
end

Base.show(io::IO, ele::Ele) = show_ele(io, ele, false)
Base.show(ele::Ele, docstring::Bool) = show_ele(stdout, ele, docstring)
Base.show(io::IO, ::MIME"text/plain", ele::Ele) = show_ele(io, ele, false)

#---------------------------------------------------------------------------------------------------
# show_elegroup

"""
    Internal: show_elegroup(io::IO, group::T, docstring::Bool)

Prints lattice element group info. Used by `show_ele`.
""" show_elegroup

function show_elegroup(io::IO, group::T, docstring::Bool) where T <: EleParameterGroup
  if docstring
    show_elegroup_with_doc(io, group)
  else
    show_elegroup_wo_doc(io, group)
  end
end

function show_elegroup(io::IO, group::BMultipoleGroup, docstring::Bool)
  if length(group.vec) == 0
    println(io, f"  BMultipoleGroup: No magnetic multipoles")
    return
  end

  println(io, f"  BMultipoleGroup:")
  println(io, f"    Order Integrated{lpad(\"Tilt (rad)\",24)}")
  for v in group.vec
    ol = f"{v.order}"
    if !isnothing(v.integrated) && v.integrated; ol = ol * "L"; end
    uk = units(Symbol(f"Kn{ol}"));  ub = units(Symbol(f"Bn{ol}"))
    println(io, f"{lpad(v.order,9)}{lpad(v.integrated,11)}{lpad(v.tilt,24)}" *
                         f"{lpad(v.Kn,24)}  Kn{ol}{lpad(v.Ks,24)}  Ks{ol} ({uk})")
    println(io, " "^44 * f"{lpad(v.Bn,24)}  Bn{ol}{lpad(v.Bs,24)}  Bs{ol} ({ub})")
  end
end

function show_elegroup(io::IO, group::EMultipoleGroup, docstring::Bool)
  if length(group.vec) == 0
    println(io, f"  EMultipoleGroup: No electric multipoles")
    return
  end

  println(io, f"  EMultipoleGroup:")
  println(io, f"    Order Integrated{lpad(\"Tilt (rad)\",24)}{lpad(\"En\",24)}{lpad(\"Es\",24)}")
  for v in group.vec
    ol = f"{v.order}"
    if !isnothing(v.integrated) && v.integrated; ol = ol * "L"; end
    ue = units(Symbol(f"En{ol}"))
    println(io, f"{lpad(n,9)}      {lpad(v.integrated,5)}{lpad(v.tilt,24)}{lpad(v.En,24)}{lpad(v.Es,24)}    En{ol}  Es{ol} ({ue})")
  end
end

function show_elegroup(io::IO, group::Vector{ControlVar})
  println(f"This needs to be coded!")
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_with_doc

function show_elegroup_with_doc(io::IO, group::T) where T <: EleParameterGroup
  gtype = typeof(group)
  nn = max(18, maximum(length.(fieldnames(gtype))))
  println(io, f"  {gtype}:")

  for field in fieldnames(gtype)
    kstr = rpad(full_parameter_name(field, gtype), nn)
    vstr = ele_param_str(Base.getproperty(group, field))
    ele_print_line(io, f"    {kstr} {vstr} {units(field)}", description(field))
  end
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_wo_doc

function show_elegroup_wo_doc(io::IO, group::T) where T <: EleParameterGroup
  gtype = typeof(group)
  gtype in keys(show_column2) ? col2 = show_column2[gtype] : col2 = Dict{Symbol,Symbol}()
  nn = max(20, maximum(length.(fieldnames(gtype))))
  println(io, f"  {gtype}:")

  for field in fieldnames(gtype)
    if field in values(col2); continue; end
    if field in keys(col2)
      kstr = rpad(full_parameter_name(field, gtype), nn)
      vstr = ele_param_str(Base.getproperty(group, field))
      str = f"    {kstr} {vstr} {units(field)}"
      field2 = col2[field]
      kstr = rpad(full_parameter_name(field2, gtype), nn)
      vstr = ele_param_str(Base.getproperty(group, field2))
      str2 = f"    {kstr} {vstr} {units(field2)}"
      if length(str) > 50 || length(str2) > 50
        println(io, str)
        println(io, str2)
      else
        println(io, f"{rpad(str,50)}{str2}")
      end
    else
      kstr = rpad(full_parameter_name(field, gtype), nn)
      vstr = ele_param_str(Base.getproperty(group, field))
      println(io, f"    {kstr} {vstr} {units(field)}")
    end
  end
end

#---------------------------------------------------------------------------------------------------
# full_parameter_name

"""
For fields where the user name is different (EG: `r_floor` and `r` in a FloorPositionGroup), 
return the string `struct_name (user_name)` (EG: `r (r_floor)`).
""" full_parameter_name

function full_parameter_name(field, group::Type{T}) where T <: EleParameterGroup
  if field ∉ keys(struct_sym_to_user_sym); return String(field); end

  for sym in struct_sym_to_user_sym[field]
    info = ele_param_info(sym)
    if !has_parent_group(info, group); continue; end
    if info.parent_group != group; continue; end
    if sym == field; break; end
    return f"{field} ({sym})"
  end

  return String(field)
end

#---------------------------------------------------------------------------------------------------
# ele_print_line

function ele_print_line(io::IO, str::String, descrip::String; ix_descrip::Int = 50)
  if length(str) < ix_descrip - 1
    println(io, f"{rpad(str, ix_descrip)}{descrip}")
  else
    println(io, str)
    println(io, " "^ix_descrip * descrip)
  end
end

#---------------------------------------------------------------------------------------------------
# Show Vector{ele}

function Base.show(io::IO, eles::Vector{Ele})
  println(io, f"{length(eles)}-element Vector{{Ele}}:")
  for ele in eles
    println(io, " " * ele_name(ele))
  end
end

Base.show(io::IO, ::MIME"text/plain", eles::Vector{Ele}) = Base.show(io::IO, eles)

#---------------------------------------------------------------------------------------------------
# Show Lat

function Base.show(io::IO, lat::Lat)
  println(io, f"Lat: {str_quote(lat.name)}")
  for branch in lat.branch
    show(io, branch)
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", lat::Lat) = Base.show(stdout, lat)

#---------------------------------------------------------------------------------------------------
# Show Branch

function Base.show(io::IO, branch::Branch)
  g_str = ""
  if haskey(branch.pdict, :geometry); g_str = f"geometry => {branch.pdict[:geometry]}"; end
  println(io, f"Branch {branch.ix_branch}: {str_quote(branch.name)}  {g_str}")

  if length(branch.ele) == 0 
    println(io, "     --- No Elements ---")
  else
    n = maximum([12, maximum([length(e.name) for e in branch.ele])]) + 2
    for ele in branch.ele
      end_str = ""
      if branch.type == MultipassLordBranch
        end_str = f"{ele.L:12.6f}"
        if haskey(ele.pdict, :slaves); end_str = end_str * f"  {ele_param_str(ele.pdict, :slaves, default = \"\")}"; end
      elseif haskey(ele.pdict, :LengthGroup)
        s_str = ele_param_str(ele, :s, default = "    "*"-"^7, format = "11.6f")
        s_down_str = ele_param_str(ele, :s_downstream, default = "    "*"-"^7, format = "11.6f")
        end_str = f"{ele.L:12.6f}{s_str} -> {s_down_str}"
        if haskey(ele.pdict, :multipass_lord); end_str = end_str * f"  {ele_param_str(ele.pdict, :multipass_lord, default = \"\")}"; end
        if haskey(ele.pdict, :super_lords);  end_str = end_str * f"  {ele_param_str(ele.pdict, :super_lords, default = \"\")}"; end
        if haskey(ele.pdict, :slaves); end_str = end_str * f"  {ele_param_str(ele.pdict, :slaves, default = \"\")}"; end
        if ele.orientation == -1; end_str = end_str * "  orientation = -1"; end
      end
      println(io, f"  {ele.pdict[:ix_ele]:5i}  {rpad(str_quote(ele.name), n)} {rpad(typeof(ele), 16)}" * end_str)                    
    end
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", branch::Branch) = Base.show(stdout, branch)

#---------------------------------------------------------------------------------------------------
# Show Vector{Branch}

function Base.show(io::IO, branches::Vector{Branch})
  n = maximum([length(b.name) for b in branches]) + 4
  for branch in branches
    g_str = ""
    if haskey(branch.pdict, :geometry)
      g_str = f", length = {branch.ele[end].s_downstream:16.9f}, geometry => {branch.pdict[:geometry]}"
    end
    println(io, f"Branch {branch.ix_branch}: {rpad(str_quote(branch.name), n)} {lpad(length(branch.ele), 5)} Ele{g_str}")
  end
end

Base.show(io::IO, ::MIME"text/plain", branches::Vector{Branch}) = Base.show(stdout, branches)

#---------------------------------------------------------------------------------------------------
# Show Beamline

function Base.show(io::IO, bl::BeamLine)
  println(io, f"Beamline:  {str_quote(bl.name)}, multipass: {bl.pdict[:multipass]}, orientation: {bl.pdict[:orientation]}")
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
      println(io, f"{ix:5i}  {rpad(str_quote(item.ele.name), n)}  {rpad(typeof(item.ele), 12)}  {lpad(item.pdict[:orientation], 2)}")
    else  # BeamLine
      println(io, f"{ix:5i}  {rpad(str_quote(item.name), n)}  {rpad(typeof(item), 12)}  {lpad(item.pdict[:orientation], 2)}")
    end
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", bl::BeamLine) = Base.show(io, bl)

#---------------------------------------------------------------------------------------------------
# Show Dict{String, Vector{Ele}}

function Base.show(io::IO, eled::Dict{String, Vector{Ele}})
  println(io, f"Dict{{AbstractString, Vector{{Ele}}}} with {length(eled)} entries.")
end

Base.show(io::IO, ::MIME"text/plain", eled::Dict{String, Vector{Ele}}) = Base.show(stdout, eled)

#---------------------------------------------------------------------------------------------------
# list_abstract

"""
  list_abstract()

Print list of the most important abstract types.
Use the `subtypes(T)` to get a list of types inheriting from abstract type `T`.
""" list_abstract

function list_abstract
end

#---------------------------------------------------------------------------------------------------
# abstract_dict


abstract_dict = Dict{Any,String}(
  BeamLineItem      => "Base type for items that can be in a BeamLine.",
  Ele               => "Base type for lattice elements.",
  EleParameterGroup => "Base type for lattice element parameter groups.",
  ControlSlave      => "Base type for Controller control structs.",
  AbstractLat       => "Base type for the Lat struct.",
  Enum              => "Base type for switch group values.",
)
