#---------------------------------------------------------------------------------------------------
# Base.getproperty(lat::Lat, sym::Symbol) for lat.XXX dot operator overload

"""
    Base.getproperty(lat::Lat, sym::Symbol)

Overloads the dot struct component selection operator so something like `lat.XXX` returns the value of `lat.pdict[:XXX]`. 
Exceptions are: `lat.name`, `lat.branch`, and `lat.pdict` which do not get redirected.

""" Base.getproperty(lat::Lat, sym::Symbol)

function Base.getproperty(lat::Lat, sym::Symbol)
  if sym == :name; return getfield(lat, :name); end
  if sym == :branch; return getfield(lat, :branch); end
  if sym == :pdict; return getfield(lat, :pdict); end
  return getfield(lat, :pdict)[sym]
end

#---------------------------------------------------------------------------------------------------
# Base.getproperty(branch::Branch, sym::Symbol) for branch.XXX dot operator overload

"""
    Base.getproperty(branch::Branch, sym::Symbol)

Overloads the dot struct component selection operator so something like `branch.XXX` returns the value of `branch.pdict[:XXX]`. 
Exceptions are: `branch.name`, `branch.ele`, and `branch.pdict` which do not get redirected.

""" Base.getproperty(branch::Branch, sym::Symbol)

function Base.getproperty(branch::Branch, sym::Symbol)
  if sym == :name; return getfield(branch, :name); end
  if sym == :ele; return getfield(branch, :ele); end
  if sym == :pdict; return getfield(branch, :pdict); end
  return getfield(branch, :pdict)[sym]
end

#---------------------------------------------------------------------------------------------------
# Base.getproperty(ele::Ele, sym::Symbol) for ele.XXX dot operator overload

"""
    Base.getproperty(ele::Ele, sym::Symbol) 

Overloads the dot struct component selection operator.

Algorithm for what to return for `ele.XXX`:
  1. If `XXX` is `pdict`, return `ele.pdict`.
  1. If `ele.pdict[:XXX]` exists, return `ele.pdict[:XXX]`.
  1. If `XXX` is a *registered* component of the Element group `GGG`, return `ele.pdict[:GGG].XXX`. 
  1. If none of the above, throw an error.

Exceptions: Something like `ele.K2L` is handled specially since storage for this parameter may
not exist (parameter is stored in `ele.pdict[BMultipoleGroup].vec(N).K2` where `N` is some integer).

Also: If `XXX` corresponds to a vector, create `ele.changed[:XXX]` to signal that the vector may have 
been modified. This is necessary due to how something like `ele.pdict[:GGG].XXX[2] = ...` is evaluated.

Also see: `get_elegroup_param`
""" Base.getproperty(ele::Ele, sym::Symbol)

function Base.getproperty(ele::Ele, sym::Symbol)
  if sym == :pdict; return getfield(ele, :pdict); end
  pdict::Dict{Symbol,Any} = getfield(ele, :pdict)
  if haskey(pdict, sym); return pdict[sym]; end                  # Does ele.pdict[sym] exist?    

  # Look for `sym` as part of an ele group
  pinfo = ele_param_info(sym)
  parent = Symbol(pinfo.parent_group)
  if !haskey(pdict, parent); error(f"Cannot find {sym} in element {ele_name(ele)}"); end

  # Mark as changed just in case getproperty is called in a construct like "q.x_limit[2] = ..."
  if pinfo.kind <: Vector
    pdict[:changed][sym] = getfield(pdict[parent], pinfo.struct_sym)
  end

  #
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

function Base.setproperty!(ele::Ele, sym::Symbol, value)
  pdict::Dict{Symbol,Any} = ele.pdict
  if haskey(pdict, sym); pdict[sym] = value; return pdict[sym]; end
  pinfo = ele_param_info(sym, ele)
  ## Currently is_settable() does not exist.
  ## if !is_settable(ele, sym); error(f"Parameter is not user settable: {sym}. For element: {ele.name}."); end

  parent = pinfo.parent_group
  # All parameters that do not have a parent ( EG: super_lord) are not "normal" and setting 
  # them does not have to be recorded in pdict[:changed]. 
  if parent == Nothing
    pdict[sym] = value
  else
    pdict[:changed][sym] = get_elegroup_param(ele, pdict[Symbol(parent)], pinfo)
    set_elegroup_param!(ele, pdict[Symbol(parent)], pinfo, value)
  end
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(branch::Vector{Branch}, ...)

"""
  Base.getindex(branch::Vector{Branch}, name::Union{Symbol,AbstractString})

Match `branch[name]` to branch in `branch[]` array using the names of the branches.
""" Base.getindex(branch::Vector{Branch}, name::Union{Symbol,AbstractString})

function Base.getindex(branch::Vector{Branch}, name::Union{Symbol,AbstractString})
  if typeof(name) == Symbol; name = String(name); end

  for br in branch
    if br.name == name; return br; end
  end

  error(f"NoBranch: No branch with name: {name}")
end

#---------------------------------------------------------------------------------------------------
# Base.getindex(ele::Vector{Ele}, ...)

"""
  Base.getindex(ele::Vector{Ele}, name::Union{Symbol,AbstractString})

Match `ele[name]` to element in `ele[]` array using the names of the elements.
""" Base.getindex(ele::Vector{Ele}, name::Union{Symbol,AbstractString})

function Base.getindex(ele::Vector{Ele}, name::Union{Symbol,AbstractString})
  if typeof(name) == Symbol; name = String(name); end

  for br in ele
    if br.name == name; return br; end
  end

  error(f"NoEle: No element with name: {name}")
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
  return getfield(group, pinfo.struct_sym)
end

#-

function get_elegroup_param(ele::Ele, group::Union{BMultipoleGroup, EMultipoleGroup}, pinfo::ParamInfo)
  (mtype, order, mgroup) = multipole_type(pinfo.user_sym)
  mul = multipole!(group, order)
  if isnothing(mgroup) || group != mgroup; return 0.0::Float64; end

  val =  getfield(mul, pinfo.struct_sym)
  if mtype[1] == 'K' || mtype[1] == 'B' || mtype[1] == 'E'
    if (mtype[end] == 'L') && !mul.integrated
      return val * ele.L
    elseif (mtype[end] != 'L') && mul.integrated
      if ele.L == 0; error(f"Cannot compute non-integrated multipole value {pinfo.user_sym} for" *
                           f" integrated multipole of element with zero length: {ele_name(ele)}"); end
      return val / ele.L
    end
  end

  return val
end

#---------------------------------------------------------------------------------------------------
# set_elegroup_param!

"""
    Internal: set_elegroup_param!(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo, value)

""" set_elegroup_param

function set_elegroup_param!(ele::Ele, group::EleParameterGroup, pinfo::ParamInfo, value)
  return setfield!(group, pinfo.struct_sym, value)
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
            f"Use set_integrated to change integrated status.")
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