# Accessor functions to customize how things like `ele.XXX` where `ele` is an `Ele` instance.

#---------------------------------------------------------------------------------------------------
# Base.getproperty(lat::Lattice, sym::Symbol) for lat.XXX dot operator overload

"""
    Base.getproperty(lat::Lattice, sym::Symbol)
    Base.getproperty(branch::Branch, sym::Symbol)
    Base.getproperty(bl::BeamLine, sym::Symbol)

Overloads the dot struct component selection operator so something like `lat.XXX` returns the value 
of `lat.pdict[:XXX]`. 

## Exceptions

- For `Lattice`: `lat.name`, `lat.branch`, and `lat.pdict` which do not get redirected. \\
- For `Branch`: `branch.name`, `branch.ele`, and `branch.pdict` which do not get redirected.
- For `BeamLine`: `bl.name`, `bl.ele`, and `bl.pdict` which do not get redirected.

""" Base.getproperty

function Base.getproperty(lat::Lattice, sym::Symbol)
  if sym == :name; return getfield(lat, :name); end
  if sym == :branch; return getfield(lat, :branch); end
  if sym == :pdict; return getfield(lat, :pdict); end

  return getfield(lat, :pdict)[sym]
end

#---------------------------------------------------------------------------------------------------
# Base.getproperty(branch::Branch, sym::Symbol) for branch.XXX dot operator overload

function Base.getproperty(branch::Branch, sym::Symbol)
  if sym == :name; return getfield(branch, :name); end
  if sym == :ele; return getfield(branch, :ele); end
  if sym == :lat; return getfield(branch, :lat); end
  if sym == :pdict; return getfield(branch, :pdict); end

  return getfield(branch, :pdict)[sym]
end

#---------------------------------------------------------------------------------------------------
# Base.getproperty(bl::BeamLine, sym::Symbol) for bl.XXX dot operator overload

function Base.getproperty(bl::BeamLine, sym::Symbol)
  if sym == :id; return getfield(bl, :id); end
  if sym == :line; return getfield(bl, :line); end
  if sym == :pdict; return getfield(bl, :pdict); end

  return getfield(bl, :pdict)[sym]
end

#---------------------------------------------------------------------------------------------------
# Base.getproperty(ele::Ele, sym::Symbol) for ele.XXX dot operator overload

"""
    Base.getproperty(ele::Ele, sym::Symbol) 

Overloads the dot struct component selection operator.

## Algorithm for what to return for `ele.XXX`: 
1. If `XXX` is `pdict`, return `ele.pdict`.
2. If `ele.pdict[:XXX]` exists, return `ele.pdict[:XXX]`.
3. If `XXX` is a *registered* component of the Element group `GGG`, return `ele.pdict[:GGG].XXX`.
4. If none of the above, throw an error.

## Notes

Exceptions: Something like `ele.Kn2L` is handled specially since storage for this parameter may
not exist (parameter is stored in `ele.pdict[:BMultipoleGroup].pole(N).Kn` where `N` is some integer).

Also see: `get_elegroup_param`
""" Base.getproperty(ele::Ele, sym::Symbol)

function Base.getproperty(ele::Ele, sym::Symbol)
  if sym == :pdict; return getfield(ele, :pdict); end
  pdict::Dict{Symbol,Any} = getfield(ele, :pdict)
  branch = lat_branch(ele)
  
  # Does ele.pdict[sym] exist? 
  if haskey(pdict, sym); return pdict[sym]; end
  
  # Look for `sym` as part of an ele group
  pinfo = ele_param_info(sym)
  if !isnothing(pinfo.output_group); return output_parameter(sym, ele, pinfo.output_group); end

  symparent = Symbol(pinfo.parent_group)
  if !haskey(pdict, symparent); error(f"Cannot find {sym} in element {ele_name(ele)}"); end

  return get_elegroup_param(ele, pdict[symparent], pinfo)
end

#---------------------------------------------------------------------------------------------------
# Base.get(ele::Ele, sym::Symbol, default)

"""
    Base.get(ele::Ele, sym::Symbol, default)

Element accessor with default. Useful for elements that are not part of a lattice.
""" Base.get_prop(ele::Ele, sym::Symbol, default)

function Base.get(ele::Ele, sym::Symbol, default)
  try
    return Base.getproperty(ele, sym)
  catch
    return default
  end
end

#---------------------------------------------------------------------------------------------------
# Base.setproperty for lat.XXX, branch.XXX, ele.XXX dot operator overload

"""
    Base.setproperty!(lat::Lattice, sym::Symbol, value)
    Base.setproperty!(branch::Branch, sym::Symbol, value)
    Base.setproperty!(ele::Ele, sym::Symbol, value)

Overloads the dot struct component selection operator so something like `lat.XXX = ...` 
sets the appropriate component in the `lat` variable. 
See the Base.getproperty for documentation on what the appropriate property is.
""" Base.setproperty!

function Base.setproperty!(lat::Lattice, sym::Symbol, value)
  if sym == :name;   return setfield!(lat, :name, value); end
  if sym == :branch; return setfield!(lat, :branch, value); end
  getfield(lat, :pdict)[sym] = value
end

#-----------------

function Base.setproperty!(branch::Branch, sym::Symbol, value)
  if sym == :name; return setfield!(branch, :name, value); end
  if sym == :lat; return setfield!(branch, :lat, value); end
  if sym == :ele;  return setfield!(branch, :ele, value); end
  getfield(branch, :pdict)[sym] = value
end

#-----------------

function Base.setproperty!(bl::BeamLine, sym::Symbol, value)
  if sym == :id; return setfield!(branch, :id, value); end
  if sym == :line; return setfield!(branch, :line, value); end
  getfield(branch, :pdict)[sym] = value
end

#-----------------

function Base.setproperty!(ele::Ele, sym::Symbol, value, check_settable = true)
  pdict::Dict{Symbol,Any} = ele.pdict
  if haskey(pdict, sym); pdict[sym] = value; return pdict[sym]; end
  pinfo = ele_param_info(sym, ele)
  if (check_settable); check_if_settable(ele, sym, pinfo); end

  # For parameters that are not part of an element parameter group struct (EG lord/slave info),
  # any changes do not have to be recorded in pdict[:changed]. 

  parent = pinfo.parent_group
  if parent == Nothing
    pdict[sym] = value

  else
    branch = lat_branch(ele)
    if isnothing(branch) || isnothing(branch.lat) || branch.lat.record_changes
      pdict[:changed][sym] = get_elegroup_param(ele, pdict[Symbol(parent)], pinfo)
    end

    set_elegroup_param!(ele, pdict[Symbol(parent)], pinfo, value)
    ele_parameter_has_changed!(ele)
  end
end

#---------------------------------------------------------------------------------------------------
# ele_parameter_has_changed!

"""
    ele_parameter_has_changed!(ele)

Record that an element parameter in `ele` has changed.
Also call the bookkeeper if the element is in a lattice and autobookkeeping is on.
""" ele_parameter_has_changed!

function ele_parameter_has_changed!(ele)
  branch = lat_branch(ele)
  if isnothing(branch) || isnothing(branch.lat); return; end

  if branch.lat.record_changes
    if branch.type == TrackingBranch
      branch.ix_ele_min_changed = min(branch.ix_ele_min_changed, ele.ix_ele)
      branch.ix_ele_max_changed = max(branch.ix_ele_max_changed, ele.ix_ele)
    else
      for slave in ele.slaves
        sbranch = slave.branch
        sbranch.ix_ele_min_changed = min(sbranch.ix_ele_min_changed, ele.ix_ele)
        sbranch.ix_ele_max_changed = max(sbranch.ix_ele_max_changed, ele.ix_ele)
      end
    end
  end

  branch.lat.parameters_have_changed = true
  if branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(lat::Lattice, name::AbstractString)

"""
  Base.getindex(lat::Lattice}, name::AbstractString)

If `lat[name]` matches a branch name, return the branch. No wild cards permitted here.
If `lat[name]` does not match a branch name, return list of matching lattice elements.
In this case the returned vector is equivalent to `eles_search(lat, name)`.
""" Base.getindex(lat::Lattice, name::AbstractString)

function Base.getindex(lat::Lattice, name::AbstractString)
  for br in lat.branch
    if br.name == name; return br; end
  end

  return eles_search(lat, name)
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(branch::Vector{Branch}, name::AbstractString)

"""
  Base.getindex(branch::Vector{Branch}, name::AbstractString)

Match `branch[name]` to branch in `branch[]` array using the names of the branches.
""" Base.getindex(branch::Vector{Branch}, name::AbstractString)

function Base.getindex(branch::Vector{Branch}, name::AbstractString)
  for br in branch
    if br.name == name; return br; end
  end

  error(f"No branch with name: {name}")
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(branch::Branch, name::AbstractString)

"""
  Base.getindex(branch::Branch}, name::AbstractString) -> Ele[]

Match `branch[name]` to all lattice elements in `branch.ele[]` array.
""" Base.getindex(branch::Branch, name::AbstractString)

function Base.getindex(branch::Branch, name::AbstractString)
  return eles_search(branch, name)

  error(f"No element with name: {name}")
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(ele::Vector{Ele}, ...)

"""
  Base.getindex(ele::Vector{Ele}, name::AbstractString)

Match `ele[name]` to element in `ele[]` array using the names of the elements.
""" Base.getindex(ele::Vector{Ele}, name::AbstractString)

function Base.getindex(ele::Vector{Ele}, name::AbstractString)
  for e in ele
    if e.name == name; return e; end
  end

  error("No element with name: $name")
end

#---------------------------------------------------------------------------------------------------
# get_elegroup_param

"""
    Internal: get_elegroup_param(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo)
    Internal: get_elegroup_param(ele::Ele, group::Union{BMultipoleGroup, EMultipoleGroup}, pinfo::ParamInfo)

Internal function used by Base.getproperty.

This function will return dependent values. 
EG: integrated multipole value even if stored value is not integrated.
""" get_elegroup_param

function get_elegroup_param(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo)
  if pinfo.parent_group == pinfo.paramkind               # Example see: ParamInfo(:twiss)
    return group
  else
    return getfield(base_field(group, pinfo), pinfo.struct_sym)
  end
end

#-

function get_elegroup_param(ele::Ele, group::Union{BMultipoleGroup, EMultipoleGroup}, pinfo::ParamInfo)
  (mtype, order, group_type) = multipole_type(pinfo.user_sym)
  if group_type == Nothing; error("Internal error. Unknown multipole group type. Please report."); end

  #

  mul = multipole!(group, order)
  if isnothing(mul)
    if mtype == "integrated" || mtype == "Eintegrated"; return false; end
    return 0
  end

  #

  val =  getfield(mul, pinfo.struct_sym)
  if mtype == "tilt" || mtype == "Etilt" || mtype == "integrated" || mtype == "Eintegrated"; return val; end

  group_type == BMultipoleGroup ? integrated = mul.integrated : integrated = mul.Eintegrated
  if mtype[end] == 'L' && !integrated
    return val * ele.L
  elseif mtype[end] != 'L' && integrated
    if ele.L == 0; error(f"Cannot compute non-integrated multipole value {pinfo.user_sym} for" *
                         f" integrated multipole of element with zero length: {ele_name(ele)}"); end
    return val / ele.L
  else
    return val
  end
end

#---------------------------------------------------------------------------------------------------
# set_elegroup_param!

"""
    Internal: set_elegroup_param!(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo, value)

""" set_elegroup_param

function set_elegroup_param!(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo, value)
  if !isnothing(pinfo.sub_struct)    # Example see: ParamInfo(:a_beta)  
    return setfield!(pinfo.sub_struct(group), pinfo.struct_sym, value)
  else
    return setfield!(base_field(group, pinfo), pinfo.struct_sym, value)
  end
end

function set_elegroup_param!(ele::Ele, group::BMultipoleGroup, pinfo::ParamInfo, value)
  (mtype, order, group_type) = multipole_type(pinfo.user_sym)
  mul = multipole!(group, order, insert = true)
  if mtype == "tilt" || mtype == "integrated"; return setfield!(mul, pinfo.struct_sym, value); end

  if isnothing(mul.integrated)
    mul.integrated = (mtype[end] == 'L')
  elseif (mtype[end] == 'L') != mul.integrated
    error(f"Cannot set non-integrated multipole value for integrated multipole and " * 
          f"vice versa for {pinfo.user_sym} in {ele_name(ele)}.\n" *
          f"Use toggle_integrated! to change the integrated status.")
  end
 
  return setfield!(mul, pinfo.struct_sym, value)
end

function set_elegroup_param!(ele::Ele, group::EMultipoleGroup, pinfo::ParamInfo, value)
  (mtype, order, group_type) = multipole_type(pinfo.user_sym)
  mul = multipole!(group, order, insert = true)
  if mtype == "Etilt" || mtype == "Eintegrated"; return setfield!(mul, pinfo.struct_sym, value); end

  if isnothing(mul.Eintegrated)
    mul.Eintegrated = (mtype[end] == 'L')
  elseif (mtype[end] == 'L') != mul.Eintegrated
    error(f"Cannot set non-integrated multipole value for integrated multipole and " * 
          f"vice versa for {pinfo.user_sym} in {ele_name(ele)}.\n" *
          f"Use toggle_integrated! to change the integrated status.")
  end

  return setfield!(mul, pinfo.struct_sym, value)
end

#---------------------------------------------------------------------------------------------------
# set_param!

"""
  Set ele parameter without recording the set by adding to `ele.pdict[:changed]`.
  Useful for bookkeeper routines to avoid double bookkeeping.
  Note: Does not check if parameter is officially settable.
"""

function set_param!(ele::Ele, sym::Symbol, value)
  pdict::Dict{Symbol,Any} = ele.pdict
  if haskey(pdict, sym); pdict[sym] = value; return; end
  pinfo = ele_param_info(sym, ele)
  set_elegroup_param!(ele, pdict[Symbol(pinfo.parent_group)], pinfo, value)
end

#---------------------------------------------------------------------------------------------------
# base_field(group, pinfo)

"""
    base_field(group::EleParameterGroup, pinfo::ParamInfo) -> BaseEleParameterGroup

Return group containing parameter described by `pinfo`. For most parameters this will be the `group`
itself. However, for example, for the parameter `eta_a`, `group` will be a `TwissGroup` instance
and returned is the sub group `group.a`.
""" base_field(group::EleParameterGroup, pinfo::ParamInfo) 

function base_field(group::EleParameterGroup, pinfo::ParamInfo)
  if isnothing(pinfo.sub_struct) 
    return group           
  else                 # Example see: ParamInfo(:a_beta)
    return getfield(group, pinfo.sub_struct)
  end
end

#---------------------------------------------------------------------------------------------------
# output_parameter

"""
  output_parameter(sym::Symbol, ele::Ele, output_group::Type{T}) where T <: BaseOutput

""" output_parameter

function output_parameter(sym::Symbol, ele::Ele, output_group::Type{T}) where T <: BaseOutput
  if sym == :rho
    if :BendGroup ∉ keys(ele.pdict); return NaN; end
    ele.g == 0 ? (return NaN) : return 1/ele.g

  elseif sym == :L_sagitta
    if :BendGroup ∉ keys(ele.pdict); return NaN; end
    ele.g == 0 ? (return 0.0) : return -cos_one(ele.angle/2) / ele.g

  elseif sym == :bend_field
    if :BendGroup ∉ keys(ele.pdict); return NaN; end
    norm_bend_field = ele.g + cos(ele.tilt0) * ele.Kn0 + sin(ele.tilt0) * ele.Ks0
    return norm_bend_field * ele.pc_ref / (C_LIGHT * charge(ele.species_ref))

  elseif sym == :norm_bend_field
    if :BendGroup ∉ keys(ele.pdict); return NaN; end
    return ele.g + cos(ele.tilt0) * ele.Kn0 + sin(ele.tilt0) * ele.Ks0

  elseif sym == :β_ref
    if :ReferenceGroup ∉ keys(ele.pdict); return NaN; end
    return ele.pc_ref / ele.E_tot_ref

  elseif sym == :γ_ref
    if :ReferenceGroup ∉ keys(ele.pdict); return NaN; end
    return ele.E_tot_ref / massof(ele.species_ref)

  elseif sym == :β_ref_downstream
    if :DownstreamReferenceGroup ∉ keys(ele.pdict); return NaN; end
    return ele.pc_ref_downstream / ele.E_tot_ref_downstream

  elseif sym == :γ_ref_downstream
    if :DownstreamReferenceGroup ∉ keys(ele.pdict); return NaN; end
    return ele.E_tot_ref_downstream / massof(ele.species_ref_downstream)

  elseif sym == :q_align
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    ag = ele.pdict[:AlignmentGroup]
    return Quaternion(ag.x_rot, ag.y_rot, ag.z_rot)

  elseif sym == :offset_tot
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    if isnothing(girder(ele)); return ele.offset; end
    ag = ele.pdict[:AlignmentGroup]
    orient_girder = FloorPositionGroup(girder(ele).offset_tot, girder(ele).q_align_tot)
    orient_ele = FloorPositionGroup(ele.offset, ele.q_align)
    return floor_transform(orient_ele, orient_girder).r

  elseif sym == :x_rot_tot
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    if isnothing(girder(ele)); return ele.x_rot; end
    ag = ele.pdict[:AlignmentGroup]
    orient_girder = FloorPositionGroup(girder(ele).offset_tot, girder(ele).q_align_tot)
    orient_ele = FloorPositionGroup(ele.offset, ele.q_align)
    return rot_angles(floor_transform(orient_ele, orient_girder).q)[1]

  elseif sym == :y_rot_tot
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    if isnothing(girder(ele)); return ele.y_rot; end
    ag = ele.pdict[:AlignmentGroup]
    orient_girder = FloorPositionGroup(girder(ele).offset_tot, girder(ele).q_align_tot)
    orient_ele = FloorPositionGroup(ele.offset, ele.q_align)
    return rot_angles(floor_transform(orient_ele, orient_girder).q)[2]

  elseif sym == :z_rot_tot
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    if isnothing(girder(ele)); return ele.z_rot; end
    ag = ele.pdict[:AlignmentGroup]
    orient_girder = FloorPositionGroup(girder(ele).offset_tot, girder(ele).q_align_tot)
    orient_ele = FloorPositionGroup(ele.offset, ele.q_align)
    return rot_angles(floor_transform(orient_ele, orient_girder).q)[3]

  elseif sym == :q_align_tot
    if :AlignmentGroup ∉ keys(ele.pdict); return NaN; end
    if isnothing(girder(ele)); return ele.q_align; end
    ag = ele.pdict[:AlignmentGroup]
    orient_girder = FloorPositionGroup(girder(ele).offset_tot, girder(ele).q_align_tot)
    orient_ele = FloorPositionGroup(ele.offset, ele.q_align)
    return floor_transform(orient_ele, orient_girder).q
  end

  error("Parameter $sym is not in the output group $output_group.")
end
