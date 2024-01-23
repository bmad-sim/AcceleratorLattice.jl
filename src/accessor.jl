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

Also see: `get_property`
""" Base.getproperty(ele::Ele, sym::Symbol)

function Base.getproperty(ele::Ele, sym::Symbol)
  if sym == :pdict; return getfield(ele, :pdict); end
  pdict::Dict{Symbol,Any} = getfield(ele, :pdict)
  if haskey(pdict, sym); return pdict[sym]; end                  # Does ele.pdict[sym] exist?    

  # Look for `sym` as part of an ele group
  pinfo = ele_param_info(sym)
  parent = Symbol(pinfo.parent_group)
  if !haskey(pdict, parent); error(f"Cannot find {sym} in element {ele_name(ele)}"); end
  if pinfo.kind <: Vector
    pdict[:changed][sym] = getfield(pdict[parent], pinfo.struct_sym)
  end

  # 
  return get_ele_group_param(pdict[parent], pinfo.struct_sym)
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

Overloads the dot struct component selection operator so something like `lat.XXX = ...` sets the appropriate component in the `lat` variable. See the Base.getproperty for documentation on what the appropriate property is.
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
  if haskey(pdict, sym); return pdict[sym]; end
  pinfo = ele_param_info(sym, ele)
  if !is_settable(ele, sym); error(f"Parameter is not user settable: {sym}. For element: {ele.name}."); end
  getfield(ele, :pdict)[:changed][sym] = get_ele_group_param(pdict[parent], sym)
  set_ele_group_param(pinfo.parent, pinfo.struct_sym)
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
