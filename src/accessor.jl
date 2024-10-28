# Accessor functions to customize how things like `ele.XXX` where `ele` is an `Ele` instance.

#---------------------------------------------------------------------------------------------------
# Base.getproperty(lat::Lat, sym::Symbol) for lat.XXX dot operator overload

"""
    Base.getproperty(lat::Lat, sym::Symbol)
    Base.getproperty(branch::Branch, sym::Symbol)
    Base.getproperty(bl::BeamLine, sym::Symbol)

Overloads the dot struct component selection operator so something like `lat.XXX` returns the value 
of `lat.pdict[:XXX]`. 

## Exceptions

- For `Lat`: `lat.name`, `lat.branch`, and `lat.pdict` which do not get redirected. \\
- For `Branch`: `branch.name`, `branch.ele`, and `branch.pdict` which do not get redirected.
- For `BeamLine`: `bl.name`, `bl.ele`, and `bl.pdict` which do not get redirected.

""" Base.getproperty

function Base.getproperty(lat::Lat, sym::Symbol)
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
not exist (parameter is stored in `ele.pdict[BMultipoleGroup].vec(N).Kn` where `N` is some integer).

Also: If `XXX` corresponds to a vector, create `ele.changed[:XXX]` to signal that the vector may have 
been modified. This is necessary due to how something like `ele.pdict[:GGG].XXX[2] = ...` is evaluated.

Also see: `get_elegroup_param`
""" Base.getproperty(ele::Ele, sym::Symbol)

function Base.getproperty(ele::Ele, sym::Symbol)
  if sym == :pdict; return getfield(ele, :pdict); end
  pdict::Dict{Symbol,Any} = getfield(ele, :pdict)
  branch = lat_branch(ele)
  
  # Does ele.pdict[sym] exist? 
  if haskey(pdict, sym)   
    # Do bookkeeping but only if element is in a lattice.
    if !isnothing(branch) && branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
    return pdict[sym]
  end
  
  # Look for `sym` as part of an ele group
  pinfo = ele_param_info(sym)
  parent = Symbol(pinfo.parent_group)
  if !haskey(pdict, parent); error(f"Cannot find {sym} in element {ele_name(ele)}"); end

  # Mark as changed just in case getproperty is called in a construct like "q.x_limit[2] = ..."
  if pinfo.kind <: Vector
    pdict[:changed][sym] = getfield(pdict[parent], pinfo.struct_sym)
  end

  # Do bookkeeping but only if element is in a lattice.
  if !isnothing(branch) && branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
  
  return get_elegroup_param(ele, pdict[parent], pinfo)
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
    Base.setproperty!(lat::Lat, sym::Symbol, value)
    Base.setproperty!(branch::Branch, sym::Symbol, value)
    Base.setproperty!(ele::Ele, sym::Symbol, value)

Overloads the dot struct component selection operator so something like `lat.XXX = ...` 
sets the appropriate component in the `lat` variable. 
See the Base.getproperty for documentation on what the appropriate property is.
""" Base.setproperty!

function Base.setproperty!(lat::Lat, sym::Symbol, value)
  if sym == :name;   return setfield!(lat, :name, value); end
  if sym == :branch; return setfield!(lat, :branch, value); end
  getfield(lat, :pdict)[sym] = value
end

function Base.setproperty!(branch::Branch, sym::Symbol, value)
  if sym == :name; return setfield!(branch, :name, value); end
  if sym == :ele;  return setfield!(branch, :ele, value); end
  getfield(branch, :pdict)[sym] = value
end

function Base.setproperty!(bl::BeamLine, sym::Symbol, value)
  if sym == :id; return setfield!(branch, :id, value); end
  if sym == :line; return setfield!(branch, :line, value); end
  getfield(branch, :pdict)[sym] = value
end

function Base.setproperty!(ele::Ele, sym::Symbol, value)
  pdict::Dict{Symbol,Any} = ele.pdict
  if haskey(pdict, sym); pdict[sym] = value; return pdict[sym]; end
  pinfo = ele_param_info(sym, ele)
  ## Currently is_settable() does not exist.
  ## if !is_settable(ele, sym); error(f"Parameter is not user settable: {sym}. For element: {ele.name}."); end

  parent = pinfo.parent_group
  # All parameters that do not have a parent struct are not "normal" and setting 
  # them does not have to be recorded in pdict[:changed]. 
  if parent == Nothing
    pdict[sym] = value
  else
    pdict[:changed][sym] = get_elegroup_param(ele, pdict[Symbol(parent)], pinfo)
    set_elegroup_param!(ele, pdict[Symbol(parent)], pinfo, value)

    # Record changes for bookkeeping.
    # There is no bookkeeping done for elements outside of a lattice.
    # Also if bookkeeping is in process, no need to record changes.
    branch = lat_branch(ele)
    if !isnothing(branch) && branch.lat.doing_bookkeeping == false
      if branch.type == TrackingBranch
        branch.ix_ele_min_changed = min(branch.ix_ele_min_changed, ele.ix_ele)
        branch.ix_ele_max_changed = max(branch.ix_ele_max_changed, ele.ix_ele)
      else
        push!(branch.changed_ele, ele)
      end
    end
  end
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(lat::Lat, name::AbstractString)

"""
  Base.getindex(lat::Lat}, name::AbstractString)

Match `lat[name]` to either a branch with name `name` or all lattice elements which
match. See `eles` function for more details on matching to lattice elements.
""" Base.getindex(lat::Lat, name::AbstractString)

function Base.getindex(lat::Lat, name::AbstractString)
  for br in lat.branch
    if br.name == name; return br; end
  end

  return eles(lat, name)
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
  return eles(branch, name)

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
  if !isnothing(pinfo.sub_struct)                       # Example see: ParamInfo(:a_beta)
    return getfield(pinfo.sub_struct(group), pinfo.struct_sym)
  elseif pinfo.parent_group == pinfo.kind               # Example see: ParamInfo(:twiss)
    return group
  else
    return getfield(group, pinfo.struct_sym)
  end
end

#-

function get_elegroup_param(ele::Ele, group::Union{BMultipoleGroup, EMultipoleGroup}, pinfo::ParamInfo)
  (mtype, order, group_type) = multipole_type(pinfo.user_sym)
  if group_type == Nothing; error("Internal error. Unknown multipole group type. Please report."); end

  #

  mul = multipole!(group, order)
  if isnothing(mul)
    if mtype[1] == 'K' || mtype[1] == 'B' || mtype[1] == 'E' || mtype[1] == 't'; return 0; end 
    if mtype[1] == 'i'; return false; end
    error("Internal error. Unknown multipole group component. Please report.")
  end

  #

  val =  getfield(mul, pinfo.struct_sym)

  if mtype == "tilt" || mtype == "Etilt"
    return val
  elseif mtype[1] == 'K' || mtype[1] == 'B' || mtype[1] == 'E'
    if mtype[end] == 'L' && !mul.integrated
      return val * ele.L
    elseif mtype[end] != 'L' && mul.integrated
      if ele.L == 0; error(f"Cannot compute non-integrated multipole value {pinfo.user_sym} for" *
                           f" integrated multipole of element with zero length: {ele_name(ele)}"); end
      return val / ele.L
    else
      return val
    end
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
    return setfield!(group, pinfo.struct_sym, value)
  end
end

function set_elegroup_param!(ele::Ele, group::Union{BMultipoleGroup, EMultipoleGroup}, pinfo::ParamInfo, value)
  (mtype, order, mgroup) = multipole_type(pinfo.user_sym)
  mul = multipole!(group, order, insert = true)

  if mtype[1] == 'K' || mtype[1] == 'B' || mtype[1] == 'E'
    if isnothing(mul.integrated)
      mul.integrated = (mtype[end] == 'L')
    elseif (mtype[end] == 'L') != mul.integrated
      error(f"Cannot set non-integrated multipole value for integrated multipole and " * 
            f"vice versa for {pinfo.user_sym} in {ele_name(ele)}.\n" *
            f"Use toggle_integrated! to change the integrated status.")
    end
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