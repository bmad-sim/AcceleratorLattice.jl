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

show_column2 = Dict{Type{T} where T <: BaseEleParameterGroup, Dict{Symbol,Symbol}}(
  AlignmentGroup => Dict{Symbol,Symbol}(
    :offset           => :offset_tot,
    :x_rot            => :x_rot_tot,
    :y_rot            => :y_rot_tot,
    :tilt             => :tilt_tot,
  ),

  ApertureGroup => Dict{Symbol,Symbol}(
    :x_limit          => :y_limit,
    :aperture_shape   => :misalignment_moves_aperture,

  ),

  BendGroup => Dict{Symbol,Symbol}(
    :bend_type        => :exact_multipoles,
    :g                => :g_tot,
    :angle            => :rho,
    :L_chord          => :L_rectangle,
    :e1               => :e1_rect,
    :e2               => :e2_rect,
    :fint1            => :hgap1,
    :fint2            => :hgap2,
    :bend_field       => :bend_field_tot,
    :L_sagitta        => :fiducial_pt,
  ),

  Dispersion1 => Dict{Symbol,Symbol}(
    :eta              => :etap,
  ),

  FloorPositionGroup => Dict{Symbol,Symbol}(
    :r                => :q,
  ),

  GirderGroup => Dict{Symbol,Symbol}(
    :origin_ele       => :origin_ele_ref_pt,
    :dr               => :dq,
  ),

  LCavityGroup => Dict{Symbol,Symbol}(
    :voltage_ref      => :gradient_ref,
    :voltage_err      => :gradient_err,
    :voltage_tot      => :gradient_tot,
    :phase_ref        => :phase_err
  ),

  LengthGroup => Dict{Symbol,Symbol}(
    :L                => :orientation,
    :s                => :s_downstream,
  ),

  LordSlaveStatusGroup => Dict{Symbol,Symbol}(
    :lord_status      => :slave_status,
  ),

  MasterGroup => Dict{Symbol,Symbol}(
    :is_on            => :field_master
  ),

  PatchGroup => Dict{Symbol,Symbol}(
    :offset           => :tilt,
    :x_rot            => :y_rot,
    :E_tot_offset     => :t_offset,
    :E_tot_downstream => :pc_downstream,
    :flexible         => :L_user,
  ),

  ReferenceGroup => Dict{Symbol,Symbol}(
    :species_ref      => :species_ref_exit,
    :pc_ref           => :pc_ref_downstream,
    :E_tot_ref        => :E_tot_ref_downstream,
    :time_ref         => :time_ref_downstream,
    :β_ref            => :β_ref_downstream,
  ),

  RFCavityGroup => Dict{Symbol,Symbol}(
    :voltage          => :gradient,
    :phase            => :rad2pi,
  ),

  RFCommonGroup => Dict{Symbol,Symbol}(
    :frequency        => :harmon,
    :n_cell           => :cavity_type,
  ),

  RFAutoGroup => Dict{Symbol,Symbol}(
    :do_auto_amp      => :do_auto_phase,
    :auto_amp         => :auto_phase,
  ),

  SolenoidGroup => Dict{Symbol,Symbol}(
    :Ksol             => :Bsol,
  ),

  StringGroup => Dict{Symbol,Symbol}(
    :type             => :alias,
  ),

  TrackingGroup => Dict{Symbol,Symbol}(
    :num_steps        => :ds_step,
  ),

  Twiss1 => Dict{Symbol,Symbol}(
    :beta             => :alpha,
    :gamma            => :phi,
    :eta              => :etap,
  ),

  TwissGroup => Dict{Symbol,Symbol}(
  ),

  InitParticleGroup => Dict{Symbol,Symbol}(
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
# ele_param_value_str

"""
    Internal: ele_param_value_str(pdict::Dict, key; default::AbstractString = "???")
    Internal: ele_param_value_str(ele::Ele, key::Symbol; default::AbstractString = "???", format = "")
    Internal: ... and others too numerous to mention ...

Routine to take a set of parameters and values and form a string with this information.
used by the `show` routines for showing element, branch, and lat info.
""" ele_param_value_str


function ele_param_value_str(pdict::Dict, key; default::AbstractString = "???")
  who = get(pdict, key, nothing)
  return ele_param_value_str(who, default = default)
end

function ele_param_value_str(ele::Ele, key::Symbol; default::AbstractString = "???", format = "")
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

ele_param_value_str(who::Nothing; default::AbstractString = "???") = default
ele_param_value_str(ele::Ele; default::AbstractString = "???") = ele_name(ele)
ele_param_value_str(species::Species; default::AbstractString = "???") = "Species(\"" * full_name(species) * "\")"
ele_param_value_str(vec_ele::Vector{T}; default::AbstractString = "???") where T <: Ele = "[" * join([ele_name(ele) for ele in vec_ele], ", ") * "]"
ele_param_value_str(branch::Branch; default::AbstractString = "???") = f"Branch {branch.pdict[:ix_branch]}: {str_quote(branch.name)}"
ele_param_value_str(str::String; default::AbstractString = "???") = str_quote(str)
ele_param_value_str(who; default::AbstractString = "???") = string(who)


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
      vstr = ele_param_value_str(pdict, key)
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
      show_elegroup(io, group, docstring, indent = 2)
    end

    # Finally print changed params.
    changed = pdict[:changed]
    if length(changed) > 0
      println(io, "  changed:")
      for (key, value) in changed
        nn2 = max(nn, length(string(key)))
        kstr = rpad(string(key), nn2)
        vstr = ele_param_value_str(changed, key)
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
    Internal: show_elegroup(io::IO, group::T, docstring::Bool; indent = 0)

Prints lattice element group info. Used by `show_ele`.
""" show_elegroup

function show_elegroup(io::IO, group::T, docstring::Bool; indent = 0) where T <: EleParameterGroup
  if docstring
    show_elegroup_with_doc(io, group, indent = indent)
  else
    show_elegroup_wo_doc(io, group, indent = indent)
  end
end

#---------

function show_elegroup(io::IO, group::BMultipoleGroup, docstring::Bool; indent = 0)
  off_str = " "^indent

  if length(group.vec) == 0
    println(io, f"{off_str}BMultipoleGroup: No magnetic multipoles")
    return
  end

  println(io, f"{off_str}BMultipoleGroup:")
  println(io, f"{off_str}  Order integrated{lpad(\"tilt (rad)\",24)}")
  for v in group.vec
    ol = f"{v.order}"
    if !isnothing(v.integrated) && v.integrated; ol = ol * "L"; end
    uk = units(Symbol(f"Kn{ol}"));  ub = units(Symbol(f"Bn{ol}"))
    println(io, f"{off_str}{lpad(v.order,7)}{lpad(v.integrated,11)}{lpad(v.tilt,24)}" *
                         f"{lpad(v.Kn,24)}  Kn{ol}{lpad(v.Ks,24)}  Ks{ol} ({uk})")
    println(io, off_str * " "^42 * f"{lpad(v.Bn,24)}  Bn{ol}{lpad(v.Bs,24)}  Bs{ol} ({ub})")
  end
end

#---------

function show_elegroup(io::IO, group::EMultipoleGroup, docstring::Bool; indent = 0)
  off_str = " "^indent

  if length(group.vec) == 0
    println(io, f"{off_str}EMultipoleGroup: No electric multipoles")
    return
  end

  println(io, f"{off_str}EMultipoleGroup:")
  println(io, f"{off_str}  Order Eintegrated{lpad(\"Etilt (rad)\",23)}")
  for v in group.vec
    ol = f"{v.order}"
    if !isnothing(v.Eintegrated) && v.Eintegrated; ol = ol * "L"; end
    ue = units(Symbol(f"En{ol}"))
    println(io, f"{off_str}{lpad(v.order,7)}{lpad(v.Eintegrated,11)}{lpad(v.Etilt,24)}{lpad(v.En,24)}  En{ol}{lpad(v.Es,24)}  Es{ol} ({ue})")
  end
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_with_doc

function show_elegroup_with_doc(io::IO, group::T; indent = 0) where T <: EleParameterGroup
  gtype = typeof(group)
  nn = max(18, maximum(length.(fieldnames(gtype))))
  println(io, f"  {gtype}:")

  for field in fieldnames(gtype)
    kstr = rpad(full_parameter_name(field, gtype), nn)
    vstr = ele_param_value_str(Base.getproperty(group, field))
    ele_print_line(io, f"    {kstr} {vstr} {units(field)}", description(field))
  end
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_wo_doc

function show_elegroup_wo_doc(io::IO, group::T; indent = 0, field_sym::Symbol = :NONE) where T <: BaseEleParameterGroup
  gtype = typeof(group)
  if gtype ∉ keys(show_column2)
    if field_sym == :NONE
      println(io, " "^indent * "Show for field of type $gtype not yet implemented.")
    else
      println(io, " "^indent * "Show for this field `$field_sym` of type $gtype not yet implemented.")
    end
    return
  end

  col2 = show_column2[gtype]
  n1 = 20
  n2 = 20
  for name in fieldnames(gtype)
    if name in values(col2)
      n2 = max(n2, length(name))
    else
      n1 = max(n1, length(name))
    end
  end

  if field_sym == :NONE
    println(io, " "^indent * "$(gtype):")
  else
    println(io, " "^indent * ".$field_sym:")
  end

  for field_sym in fieldnames(gtype)
    field = Base.getproperty(group, field_sym)
    if typeof(field) ∈ keys(show_column2)
      show_elegroup_wo_doc(io, field, indent = indent + 2, field_sym = field_sym)
      continue
    end

    if field_sym in values(col2); continue; end         # Second column fields handled with first column ones.

    if field_sym in keys(col2)
      kstr = rpad(full_parameter_name(field_sym, gtype), n1)
      vstr = ele_param_value_str(field)
      str = f"  {kstr} {vstr} {units(field_sym)}"   # First column entry
      field2_sym = col2[field_sym]
      kstr = rpad(full_parameter_name(field2_sym, gtype), n2)
      vstr = ele_param_value_str(Base.getproperty(group, field2_sym))
      str2 = f"  {kstr} {vstr} {units(field2_sym)}" # Second column entry.
      if length(str) > 50 || length(str2) > 50        # If length is too big print in two lines.
        println(io, " "^indent * str)
        println(io, " "^indent * str2)
      else                                            # Can print as a single line.
        println(io, " "^indent * f"{rpad(str, 50)}{str2}")
      end

    else
      kstr = rpad(full_parameter_name(field_sym, gtype), n1)
      vstr = ele_param_value_str(field)
      println(io, " "^indent * f"  {kstr} {vstr} {units(field_sym)}")
    end

  end  # for field_sym in fieldnames(gtype)
end

#---------------------------------------------------------------------------------------------------
# full_parameter_name

"""
For fields where the user name is different (EG: `r_floor` and `r` in a FloorPositionGroup), 
return the string `struct_name (user_name)` (EG: `r (r_floor)`).
""" full_parameter_name

function full_parameter_name(field, group::Type{T}) where T <: BaseEleParameterGroup
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
# Show Vector{Ele}

function Base.show(io::IO, eles::Vector{T}) where T <: Ele
  println(io, f"{length(eles)}-element {typeof(eles)}:")
  for ele in eles
    println(io, " " * ele_name(ele))
  end
end

Base.show(io::IO, ::MIME"text/plain", eles::Vector{T}) where T <: Ele = Base.show(io::IO, eles)

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
  length(branch.ele) == 0 ? n = 0 : n = maximum([18, maximum([length(e.name) for e in branch.ele])]) + 2
  g_str = f"Branch {branch.ix_branch}: {str_quote(branch.name)}"
  if haskey(branch.pdict, :geometry); g_str = g_str * f", geometry => {branch.pdict[:geometry]}"; end

  if n > 0
    g_str = rpad(g_str, 54) * "L"
    if branch.type != MultipassLordBranch; g_str = g_str * "           s      s_downstream"; end
  end

  println(io, "$g_str")

  if length(branch.ele) == 0 
    println(io, "     --- No Elements ---")
  else
    for ele in branch.ele
      end_str = ""
      if branch.type == MultipassLordBranch
        end_str = f"{ele.L:11.6f}"
        if haskey(ele.pdict, :slaves); end_str = end_str * " "^28 * f"  {ele_param_value_str(ele.pdict, :slaves, default = \"\")}"; end
      elseif haskey(ele.pdict, :LengthGroup)
        s_str = ele_param_value_str(ele, :s, default = "    "*"-"^7, format = "12.6f")
        s_down_str = ele_param_value_str(ele, :s_downstream, default = "    "*"-"^7, format = "12.6f")
        end_str = f"{ele.L:12.6f}{s_str} ->{s_down_str}"
        if haskey(ele.pdict, :multipass_lord); end_str = end_str * f"  {ele_param_value_str(ele.pdict, :multipass_lord, default = \"\")}"; end
        if haskey(ele.pdict, :super_lords);  end_str = end_str * f"  {ele_param_value_str(ele.pdict, :super_lords, default = \"\")}"; end
        if haskey(ele.pdict, :slaves); end_str = end_str * f"  {ele_param_value_str(ele.pdict, :slaves, default = \"\")}"; end
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
  str = ""
  for (key, value) in bl.pdict
    typeof(value) == String ? str = str * "$key => $(str_quote(value)), " : str = str * "$key => $value, "
  end
  println(io, f"BeamLine: [{str[1:end-2]}]")
  n = 6
  for item in bl.line
    if item isa BeamLineEle
      n = maximum([n, length(item.ele.name)]) 
    else  # BeamLine
      n = maximum([n, length(item.name)])
    end
  end

  for (ix, item) in enumerate(bl.line)
    orient = ""
    if item.pdict[:orientation] == -1; orient = "orientation = -1"; end

    if item isa BeamLineEle
      out = f"{ix:5i}  {rpad(str_quote(item.ele.name), n+2)}  {rpad(typeof(item.ele), 20)}  {orient}"
    else  # BeamLine
      out = f"{ix:5i}  {rpad(str_quote(item.name), n+2)}  {rpad(typeof(item), 20)}  {orient}"
    end
    println(io, out)
  end

  return nothing
end

Base.show(io::IO, ::MIME"text/plain", bl::BeamLine) = Base.show(io, bl)

#---------------------------------------------------------------------------------------------------
# Show Dict{String, Vector{Ele}}

function Base.show(io::IO, eled::Dict{String, Vector{T}}) where T <: Ele
  println(io, f"Dict{{AbstractString, Vector{{T}}}} with {length(eled)} entries.")
end

Base.show(io::IO, ::MIME"text/plain", eled::Dict{String, Vector{T}}) where T <: Ele = Base.show(stdout, eled)

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
# info

"""
    info(sym::Symbol) -> nothing            # Info on element parameter symbol. EG: :angle, :Kn1, etc.
    info(str::AbstractString) -> nothing    # Info on element parameter string. EG: "angle", "Kn1", etc.
    info(ele_type::Type{T}) where T <: Ele  # Info on a given element type.
    info(ele::Ele)                          # Info on typeof(ele) element type.
    info(group::Type{T}) where T <: EleParameterGroup  # Info on element parameter group.

Prints information about:
  + The element parameter represented by `sym` or `str`.
  + A particular element type given by `ele_type` or the type of `ele`.
  + A particular element parameter group given by `group`.

## Examples
    info(:L)          # Prints information on parameter `L`.
    info("L")         # Same as above.
    info(LengthGroup) # `LengthGroup` info.
""" info

function info(sym::Symbol)
  if sym in keys(struct_sym_to_user_sym)
    first_info_printed = false
    for sym2 in struct_sym_to_user_sym[sym]
      if first_info_printed; println(""); end
      info1(ele_param_info(sym2))
      first_info_printed = true
    end
    return
  end

  info = ele_param_info(sym, throw_error = false)
  if !isnothing(info)
    info1(info)
    return
  end

  println(f"No information found on: {sym}")
end

#-----

info(str::AbstractString) = info(Symbol(str))

#-----

function info(ele_type::Type{T}; output_str::Bool = false) where T <: Ele
  if ele_type ∉ keys(PARAM_GROUPS_LIST)
    println("No information on $(ele_type)")
    return
  end

  if output_str
    lst = ""
    for group in sort(PARAM_GROUPS_LIST[ele_type])
      name = "`$(strip_AL(group))`"
      lst *= "•  $(rpad(name, 20)) -> $(ELE_PARAM_GROUP_INFO[group].description)\\\n"
    end
    return lst

  else
    for group in sort(PARAM_GROUPS_LIST[ele_type])
      println("  $(rpad(string(group), 20)) -> $(ELE_PARAM_GROUP_INFO[group].description)")
    end
  end
end

#----

#info(ele::Ele; output_str::Bool = false) = info(typeof(ele), output_str)

#----

function info(group::Type{T}) where T <: EleParameterGroup
  if group in keys(ELE_PARAM_GROUP_INFO)
    println("$(group): $(ELE_PARAM_GROUP_INFO[group].description)")
  else
    println("$group")
  end

  for param in fieldnames(group)
    info = ele_param_info(param, throw_error = false)
    if isnothing(info)
      println("  $param")
    else
      str = "  " * rpad("$param::$(strip_AL(info.kind))", 30) * "  " * info.description
      if info.units != ""; str *= " ($(info.units))"; end
      if info.user_sym != info.struct_sym  str  *= "  User sym = $(info.user_sym)"; end
      println(str)
    end
  end

  println("\nFound in:")
  for (ele_type, glist) in sort!(OrderedDict(PARAM_GROUPS_LIST))
    if group in glist; println("    " * string(ele_type)); end
  end

end

#---------------------------------------------------------------------------------------------------
# info1

"""
    Internal: info1(info::ParamInfo) -> nothing

Used by `info` function.
""" info1

function info1(info::ParamInfo)
  println(f"  User name:       {info.user_sym}")
  if isnothing(info.sub_struct)
    println(f"  Stored in:       {info.parent_group}.{info.struct_sym}")
  else
    println(f"  Stored in:       {info.sub_struct(info.parent_group)}.{info.struct_sym}")
  end
  println(f"  Parameter type:  {info.kind}")
  if info.units != ""; println(f"  Units:           {info.units}"); end
  println(f"  Description:     {info.description}")
  return nothing
end

#---------------------------------------------------------------------------------------------------
# Construct documentation for element types

for etype in subtypes(Ele)
  # Need to make ele_docstring global so the eval_str below will work (using $ele_docstring did not work).
  global ele_docstring = """
      mutable struct $(strip_AL(etype)) <: Ele

Type of lattice element. $(ELE_TYPE_INFO[etype])

## Associated parameter groups
$(info(etype, output_str = true))
"""

  eval_str("@doc ele_docstring $etype")
end
