#---------------------------------------------------------------------------------------------------
# show_column2

"""
    show_column2 = Dict{Type{T} where T <: EleParams, Dict{Symbol,Symbol}}

Dict used by the `show(::ele)` command which contains the information as to what to put in the
second column when displaying the elements of an element parameter group using the two column format.

Example `show_column2` key/value pair:
```julia
  FloorParams => Dict{Symbol,Symbol}(
    :r                => :q,
    :phi              => :psi,
  )
```
In this example, when printing the `FloorParams`, in the line showing the `.r` component,
the `.r` component will be in the first column and the `.q` component will be in the
second column.

When defining custom parameter groups, key/value pairs can be added to `show_column2` as needed.

NOTE! For any show_column2[Params] dict, Output parameters may be a value (will appear in column 2)
but not a key. This restriction is not fundamental and could be remove with a little programming.
""" show_column2

show_column2 = Dict{Type{T} where T <: BaseEleParams, Dict{Symbol,Symbol}}(
  BodyShiftParams => Dict{Symbol,Symbol}(
    :offset_body     => :offset_body_tot,
    :x_rot_body      => :x_rot_body_tot,
    :y_rot_body      => :y_rot_body_tot,
    :z_rot_body      => :z_rot_body_tot,
  ),

  ApertureParams => Dict{Symbol,Symbol}(
    :x_limit          => :y_limit,
    :aperture_shape   => :aperture_shifts_with_body,
  ),

  BeginningParams => Dict{Symbol,Symbol}(
    :beta_a           => :beta_b,
    :alpha_a          => :alpha_b,
    :gamma_a          => :gamma_b,
    :phi_a            => :phi_b,
    :eta_x            => :eta_y,
    :etap_x           => :etap_y,
    :deta_ds_x        => :deta_ds_y,
  ),

  BendParams => Dict{Symbol,Symbol}(
    :bend_type        => :exact_multipoles,
    :g                => :norm_bend_field,
    :angle            => :rho,
    :e1               => :e2,
    :e1_rect          => :e2_rect,
    :edge_int1        => :edge_int2,
    :bend_field_ref   => :bend_field,
    :L_chord          => :L_sagitta,
  ),

  DescriptionParams => Dict{Symbol,Symbol}(
    :type             => :ID,
  ),

  Dispersion1 => Dict{Symbol,Symbol}(
    :eta              => :etap,
  ),

  DownstreamReferenceParams => Dict{Symbol,Symbol}(
    :pc_ref_downstream  => :E_tot_ref_downstream,
    :β_ref_downstream   => :γ_ref_downstream,
  ),

  GirderParams => Dict{Symbol,Symbol}(
    :origin_ele       => :origin_ele_ref_pt,
    :dr               => :dq,
  ),

  InitParticleParams => Dict{Symbol,Symbol}(
  ),

  LengthParams => Dict{Symbol,Symbol}(
    :L                => :orientation,
    :s                => :s_downstream,
  ),

  LordSlaveStatusParams => Dict{Symbol,Symbol}(
    :lord_status      => :slave_status,
  ),

  MasterParams => Dict{Symbol,Symbol}(
    :is_on            => :field_master
  ),

  FloorParams => Dict{Symbol,Symbol}(
    :r_floor          => :q_floor,
  ),

  PatchParams => Dict{Symbol,Symbol}(
    :E_tot_offset     => :t_offset,
    :E_tot_downstream => :pc_downstream,
    :flexible         => :L_user,
  ),

  PositionParams => Dict{Symbol,Symbol}(
    :offset           => :offset_tot,
    :x_rot            => :x_rot_tot,
    :y_rot            => :y_rot_tot,
    :z_rot            => :z_rot_tot,
  ),

  ReferenceParams => Dict{Symbol,Symbol}(
    :species_ref      => :extra_dtime_ref,
    :pc_ref           => :E_tot_ref,
    :time_ref         => :time_ref_downstream,
    :β_ref            => :γ_ref,
  ),

  RFParams => Dict{Symbol,Symbol}(
    :voltage          => :gradient,
    :phase            => :multipass_phase,
    :frequency        => :harmon,
    :n_cell           => :cavity_type,
  ),

  RFAutoParams => Dict{Symbol,Symbol}(
    :do_auto_amp      => :do_auto_phase,
    :auto_amp         => :auto_phase,
  ),

  SolenoidParams => Dict{Symbol,Symbol}(
    :Ksol             => :Bsol,
  ),

  TrackingParams => Dict{Symbol,Symbol}(
    :num_steps        => :ds_step,
  ),

  Twiss1 => Dict{Symbol,Symbol}(
    :beta             => :alpha,
    :gamma            => :phi,
    :eta              => :etap,
  ),
)

#---------------------------------------------------------------------------------------------------
# DO_NOT_SHOW_PARAMS_LIST

"""
    Vector{Symbol} DO_NOT_SHOW_PARAMS_LIST

List of parameters not to show when displaying the parameters of an element, branch, or lattice.
These parameters are redundant and are not shown to save space.
""" DO_NOT_SHOW_PARAMS_LIST

DO_NOT_SHOW_PARAMS_LIST = Vector{Symbol}([:q_body, :q_body_tot, :to_line,
                :x_rot_floor, :y_rot_floor, :z_rot_floor, :drift_master])

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
  lat = branch.lat
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

    if typeof(val) <: Number
      if format == ""
        return string(val)
      else
        return eval(Meta.parse("f\"{($val):$format}\""))
      end
    else
      ele_param_value_str(val, default = default)
    end

  catch
    return default
  end
end

ele_param_value_str(q::Quaternion; default::AbstractString = "???") = "[$(join([string(qi) for qi in q], ", "))]"
ele_param_value_str(wall2d::Wall2D; default::AbstractString = "???") = "Wall2D(...)"
ele_param_value_str(who::Nothing; default::AbstractString = "???") = default
ele_param_value_str(ele::Ele; default::AbstractString = "???") = ele_name(ele)
ele_param_value_str(species::Species; default::AbstractString = "???") = "Species($(str_quote(species.name)))"
ele_param_value_str(vec_ele::Vector{T}; default::AbstractString = "???") where T <: Ele = "[$(join([ele_name(ele) for ele in vec_ele], ", "))]"
ele_param_value_str(vec::Vector; default::AbstractString = "???") = "[" * join([string(v) for v in vec], ", ") * "]"
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
    # Print non-group, non-changed parameters first like the element index, branch ID, etc.
    for key in sort(collect(keys(pdict)))
      if key in DO_NOT_SHOW_PARAMS_LIST; continue; end
      val = pdict[key]
      if typeof(val) <: EleParams || key == :changed; continue; end
      if key == :name; continue; end
      nn2 = max(nn, length(string(key)))
      param_name = rpad(string(key), nn2)
      value_str = ele_param_value_str(pdict, key)
      if docstring
        ele_print_line(io, f"  {param_name} {value_str} {param_units(key)}", description(key))
      else
        println(io, f"  {param_name} {value_str} {param_units(key)}")
      end
    end

    # Print element parameter groups (does not include changed)
    for key in sort(collect(keys(pdict)))
      group = pdict[key]
      if !(typeof(group) <: EleParams); continue; end
      # Do not show if the group parameter values are the same as the ReferenceParams
      if key == :DownstreamReferenceParams
        rg = pdict[:ReferenceParams]
        if group.species_ref_downstream == rg.species_ref && group.pc_ref_downstream == rg.pc_ref
          println(io, "  DownstreamReferenceParams: Same energy and species values as ReferenceParams")
          continue
        end
      end
      show_elegroup(io, group, ele, docstring, indent = 2)
    end

    # Finally print changed params.
    changed = pdict[:changed]
    if length(changed) > 0
      println(io, "  changed:")
      for (key, value) in changed
        nn2 = max(nn, length(string(key)))
        param_name = rpad(repr(key), nn2)
        value_str = ele_param_value_str(changed, key)
        if docstring
          ele_print_line(io, f"    {param_name} {value_str} {param_units(key, eletype)}", description(key, eletype))
        else
          println(io, f"    {param_name} {value_str} {param_units(key, eletype)}")
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
    Internal: show_elegroup(io::IO, group::EleParams, ele::Ele, docstring::Bool; indent = 0)

Prints lattice element group info. Used by `show_ele`.
""" show_elegroup

function show_elegroup(io::IO, group::EleParams, ele::Ele, docstring::Bool; indent = 0)
  if docstring
    show_elegroup_with_doc(io, group, ele, indent = indent)
  else
    show_elegroup_wo_doc(io, group, ele, indent = indent)
  end
end

#---------

function show_elegroup(io::IO, group::BMultipoleParams, ele::Ele, docstring::Bool; indent = 0)
  off_str = " "^indent

  if length(group.pole) == 0
    println(io, "$(off_str)BMultipoleParams: No magnetic multipoles")
    return
  end

  println(io, "$(off_str)BMultipoleParams:")
  tilt = "tilt (rad)"
  println(io, "$(off_str)  Order integrated $(lpad(tilt,23))")
  for v in group.pole
    ol = "$(v.order)"
    if !isnothing(v.integrated) && v.integrated; ol = ol * "L"; end
    uk = param_units(Symbol("Kn$(ol)"));  ub = param_units(Symbol("Bn$(ol)"))
    Kn = "Kn$ol"
    Bn = "Bn$ol"
    println(io, "$(off_str)$(lpad(v.order,7))$(lpad(v.integrated,11))$(lpad(v.tilt,24))" *
                         "$(lpad(v.Kn,24)) $(rpad(Kn,6))$(lpad(v.Ks,24)) Ks$ol ($uk)")
    println(io, off_str * " "^42 * "$(lpad(v.Bn,24)) $(rpad(Bn,6))$(lpad(v.Bs,24)) Bs$ol ($ub)")
  end
end

#---------

function show_elegroup(io::IO, group::EMultipoleParams, ele::Ele, docstring::Bool; indent = 0)
  off_str = " "^indent

  if length(group.pole) == 0
    println(io, "$(off_str)EMultipoleParams: No electric multipoles")
    return
  end

  println(io, "$(off_str)EMultipoleParams:")
  println(io, "$(off_str)  Order Eintegrated $(lpad("Etilt (rad)",22))")
  for v in group.pole
    !isnothing(v.Eintegrated) && v.Eintegrated ? ol = "$(v.order)L" : ol = "$(v.order) "
    ue = param_units(Symbol("En$(ol)"))
    println(io, "$(off_str)$(lpad(v.order,7))$(lpad(v.Eintegrated,11))$(lpad(v.Etilt,24))$(lpad(v.En,24)) En$(ol)$(lpad(v.Es,24)) Es$(ol) ($ue)")
  end
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_with_doc

"""
    show_elegroup_with_doc(io::IO, group::T; ele::Ele, indent = 0) where T <: EleParams

Single column printing of an element group with a docstring printed for each parameter.
""" show_elegroup_with_doc

function show_elegroup_with_doc(io::IO, group::T; ele::Ele, indent = 0) where T <: EleParams
  gtype = typeof(group)
  nn = max(18, maximum(length.(fieldnames(gtype))))
  println(io, f"  {gtype}:")

  for field in associated_names(gtype, exclude_do_not_show = true)
    param_name = rpad(full_parameter_name(field, gtype), nn)
    value_str = ele_param_value_str(ele, field)
    ele_print_line(io, f"    {param_name} {value_str} {param_units(field)}", description(field))
  end
end

#---------------------------------------------------------------------------------------------------
# show_elegroup_wo_doc

"""
    show_elegroup_wo_doc(io::IO, group::BaseEleParams, ele::Ele; indent = 0, group_show_name::Symbol = :NONE)

Two column printing of an element group without any docstring.
""" show_elegroup_wo_doc

function show_elegroup_wo_doc(io::IO, group::BaseEleParams, ele::Ele; indent = 0, group_show_name::Symbol = :NONE)
  # If output field for column 1 or column 2 is wider than this, print the fields on two lines.
  col_width_cut = 55

  gtype = typeof(group)
  if gtype ∉ keys(show_column2)
    if group_show_name == :NONE
      println(io, " "^indent * "Show for field of type $gtype not yet implemented.")
    else
      println(io, " "^indent * "Show for this field `$group_show_name` of type $gtype not yet implemented.")
    end
    return
  end

  col2 = show_column2[gtype]
  n1 = 20
  n2 = 20
  for name in associated_names(gtype, exclude_do_not_show = true)
    if name in values(col2)
      n2 = max(n2, length(full_parameter_name(name, gtype)))
    else
      n1 = max(n1, length(full_parameter_name(name, gtype)))
    end
  end

  if group_show_name == :NONE
    println(io, " "^indent * "$(gtype):")
  else
    println(io, " "^indent * ".$group_show_name:")
  end

  for field_sym in associated_names(gtype, exclude_do_not_show = true)
    if field_sym in values(col2); continue; end         # Second column fields handled with first column ones.

    if field_sym in keys(col2)
      field_name = rpad(full_parameter_name(field_sym, gtype), n1)
      vstr = ele_param_value_str(ele, field_sym)
      str = "  $field_name $vstr $(param_units(field_sym))"   # First column entry

      field2_sym = col2[field_sym]
      # If field2_sym represents a output parameter then field2_sym will not be in fieldnames(group)
      field_name = rpad(full_parameter_name(field2_sym, gtype), n2)
      vstr = ele_param_value_str(ele, field2_sym)
      str2 = "  $field_name $vstr $(param_units(field2_sym))" # Second column entry.

      if length(str) > col_width_cut || length(str2) > col_width_cut        # If length is too big print in two lines.
        println(io, " "^indent * str)
        println(io, " "^indent * str2)
      else                                            # Can print as a single line.
        println(io, " "^indent * "$(rpad(str, col_width_cut))$str2")
      end

    else
      if field_sym in fieldnames(gtype) && typeof(getfield(group, field_sym)) <: EleParameterSubParams; continue; end
      field_name = rpad(full_parameter_name(field_sym, gtype), n1)
      vstr = ele_param_value_str(ele, field_sym)
      println(io, " "^indent * "  $field_name $vstr $(param_units(field_sym))")
    end

  end  # for field_sym in fieldnames(gtype)
end

#---------------------------------------------------------------------------------------------------
# full_parameter_name

"""
    full_parameter_name(field::Symbol, group::Type{T}) where T <: BaseEleParams

For fields where the user name is different (EG: `r_floor` and `r` in a FloorParams), 
return the string `struct_name (user_name)` (EG: `r (.r_floor)`). Also add `(output)` to 
names of output parameters.
""" full_parameter_name

function full_parameter_name(field::Symbol, group::Type{T}) where T <: BaseEleParams
  pinfo = ele_param_info(field, throw_error = false)
  if !isnothing(pinfo)
    if !isnothing(pinfo.output_group); return "$field (output)"; end
    if pinfo.struct_sym != field
      if isnothing(pinfo.sub_struct)
        return "$(pinfo.user_sym) (.$(pinfo.struct_sym))"
      else
        return "$(pinfo.user_sym) (.$(pinfo.sub_struct).$(pinfo.struct_sym))"
      end
    end
    return String(field)
  end

  if field ∉ keys(ele_param_struct_field_to_user_sym); return String(field); end

  for sym in ele_param_struct_field_to_user_sym[field]
    pinfo = ele_param_info(sym, throw_error = false)
    if !has_parent_group(pinfo, group); continue; end
    if sym == field; break; end
    return "$field ($sym)"
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
# Show Lattice

function Base.show(io::IO, lat::Lattice)
  println(io, "Lattice: $(str_quote(lat.name)),  lat.autobookkeeping = $(lat.autobookkeeping)")
  for branch in lat.branch
    show(io, branch)
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", lat::Lattice) = Base.show(stdout, lat)

#---------------------------------------------------------------------------------------------------
# Show Branch

function Base.show(io::IO, branch::Branch)
  length(branch.ele) == 0 ? n = 0 : n = maximum([18, maximum([length(e.name) for e in branch.ele])]) + 2
  g_str = f"Branch {branch.ix_branch}: {str_quote(branch.name)}"
  if haskey(branch.pdict, :geometry); g_str = g_str * f", geometry => {branch.pdict[:geometry]}"; end

  if n > 0
    g_str = rpad(g_str, 54) * "L"
    if branch.type != MultipassBranch; g_str = g_str * "           s      s_downstream"; end
  end

  println(io, "$g_str")

  if length(branch.ele) == 0 
    println(io, "     --- No Elements ---")
  else
    for ele in branch.ele
      end_str = ""
      if branch.type == MultipassBranch
        end_str = f"{ele.L:11.6f}"
        if haskey(ele.pdict, :slaves); end_str = end_str * " "^28 * f"  {ele_param_value_str(ele.pdict, :slaves, default = \"\")}"; end
      elseif haskey(ele.pdict, :LengthParams)
        s_str = ele_param_value_str(ele, :s, default = "    "*"-"^7, format = "12.6f")
        s_down_str = ele_param_value_str(ele, :s_downstream, default = "    "*"-"^7, format = "12.6f")
        end_str = f"{ele.L:12.6f}{s_str} ->{s_down_str}"
        if haskey(ele.pdict, :multipass_lord); end_str *= "  $(ele_param_value_str(ele.pdict, :multipass_lord, default = ""))"; end
        if haskey(ele.pdict, :super_lords);    end_str *= "  $(ele_param_value_str(ele.pdict, :super_lords, default = ""))"; end
        if haskey(ele.pdict, :slaves);         end_str *= "  $(ele_param_value_str(ele.pdict, :slaves, default = ""))"; end
        if haskey(ele.pdict, :ForkParams);     end_str *= "  Fork to: $(ele_param_value_str(ele.to_ele, default = "???"))"; end
        if haskey(ele.pdict, :from_forks);     end_str *= "  From fork: $(ele_param_value_str(ele.from_forks, default = "???"))"; end
        if ele.orientation == -1; end_str *= "  orientation = -1"; end
      end
      println(io, "  $(lpad(ele.pdict[:ix_ele], 5))  $(rpad(str_quote(ele.name), n)) $(rpad(typeof(ele), 16))" * end_str)                    
    end
  end
  return nothing
end

Base.show(io::IO, ::MIME"text/plain", branch::Branch) = Base.show(stdout, branch)

#---------------------------------------------------------------------------------------------------
# Show Vector{Branch}

function Base.show(io::IO, branches::Vector{Branch})
  if length(branches) == 0; return; end
  n = maximum([length(b.name) for b in branches]) + 4
  for branch in branches
    g_str = ""
    if length(branch.ele) > 0 && haskey(branch.pdict, :geometry)
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
    info(group::Type{T}) where T <: EleParams  # Info on element parameter group.

Prints information about:
  + The element parameter represented by `sym` or `str`.
  + A particular element type given by `ele_type` or the type of `ele`.
  + A particular element parameter group given by `group`.

## Examples
    info(:L)          # Prints information on parameter `L`.
    info("L")         # Same as above.
    info(LengthParams) # `LengthParams` info.
""" info

function info(sym::Symbol)
  if sym in keys(ele_param_struct_field_to_user_sym)
    first_info_printed = false
    for sym2 in ele_param_struct_field_to_user_sym[sym]
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

function info(group::Type{T}) where T <: EleParams
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
      str = "  " * rpad("$param::$(strip_AL(info.paramkind))", 30) * "  " * info.description
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
  println("  User name:       $(info.user_sym)")
  if isnothing(info.sub_struct)
    println("  Stored in:       $(info.parent_group).$(info.struct_sym)")
  else
    println("  Stored in:       $(info.parent_group).$(info.sub_struct).$(info.struct_sym)")
  end
  println("  Parameter type:  $(info.paramkind)")
  if info.units != ""; println("  Units:           $(info.units)"); end
  println("  Description:     $(info.description)")
  return nothing
end

#---------------------------------------------------------------------------------------------------
# Construct documentation for element types

for etype in subtypes(Ele)
  # Need to make ele_docstring global so the eval_str below will work (using $ele_docstring did not work).
  global ele_docstring = 
"""
      mutable struct $(strip_AL(etype)) <: Ele

Type of lattice element. $(ELE_TYPE_INFO[etype])

## Associated parameter groups
$(info(etype, output_str = true))
"""

  eval_str("@doc ele_docstring $etype")
end

#---------------------------------------------------------------------------------------------------
# show(::Region)


function Base.show(io::IO, er::Region)
  print(
"""
Region:
 start_ele: $(ele_name(er.start_ele))
 end_ele:   $(ele_name(er.end_ele))
 include_regionend: $(er.include_regionend)
""")
end

Base.show(io::IO, ::MIME"text/plain", er::Region) = Base.show(io::IO, er::Region)

#---------------------------------------------------------------------------------------------------
# show_changed

"""
    show_changed(lat::Lattice)

Show elements that have changed parameters.
This function is used for debugging.
"""
function show_changed(lat::Lattice)
  for branch in lat.branch
    for ele in branch.ele
      if !haskey(ele.pdict, :changed); continue; end
      if length(ele.changed) == 0; continue; end
      println("Changed: $(ele_name(ele))")
    end
  end
end