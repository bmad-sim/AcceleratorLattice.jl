#---------------------------------------------------------------------------------------------------
# Base.getproperty for lat.XXX, branch.XXX, ele.XXX dot operator overload

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
# Base.getproperty for branch.XXX dot operator overload

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
# Base.getproperty for ele.XXX dot operator overload

"""
    Base.getproperty(ele::T, sym::Symbol) where T <: Ele

Overloads the dot struct component selection operator.

Algorithm for what to return for `ele.XXX`:
  1. If `XXX` is `pdict`, return `ele.pdict`.
  1. If `ele.pdict[:XXX]` exists, return `ele.pdict[:XXX]`.
  1. If `ele.pdict[:inbox][:XXX]` exists, return this.
  1. If `XXX` is a component of the Element group `GGG`, return `ele.pdict[:GGG].XXX`. In this case, `XXX` must have been registered as a component of `GGG` (see the manual for details). Exception: If `XXX` is an array, create `ele.pdict[:inbox][:XXX]` and return that. This exception is necessary due to how something like `ele.pdict[:GGG].XXX[2] = ...` is evaluated. If no corresponding element group for `sym` exists, throw an error.
  1. If none of the above, throw an error.

Also see: `get_property`
""" Base.getproperty(ele::T, sym::Symbol) where T <: Ele

function Base.getproperty(ele::T, sym::Symbol) where T <: Ele
  if sym == :pdict; return getfield(ele, :pdict); end
  pdict = getfield(ele, :pdict)
  if haskey(pdict, sym); return pdict[sym]; end                  # Does ele.pdict[sym] exist?
  if !haskey(pdict, :inbox) error("Malformed element"); end      
  if haskey(pdict[:inbox], sym); return pdict[:inbox][sym]; end  # Does ele.pdict[:inbox][sym] exist?

  # If not found above, look for `sym` as part of an ele group
  pinfo = ele_param_info(sym)
  parent = Symbol(pinfo.parent_group)
  if !haskey(pdict, parent); error(f"Cannot find {sym} in element {pdict[:name]}"); end

  if pinfo.kind <: Vector
    pdict[:inbox][sym] = copy(getfield(pdict[parent], sym))
    return pdict[:inbox][sym]
  else
    return ele_group_value(pdict[parent], sym)
  end
end

#---------------------------------------------------------------------------------------------------
# get_property

"""
    get_property(ele::T, sym::Symbol, default)

Element accessor with default. Useful for elements that are not part of a lattice.

""" get_property

function get_property(ele::Ele, sym::Symbol, default)
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
    Base.setproperty!(ele::T, sym::Symbol, value) where T <: Ele

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

function Base.setproperty!(ele::T, sym::Symbol, value) where T <: Ele
  # :name is special since it is not associated with an element group.
  if isa_eleparametergroup(sym) || sym == :name; getfield(ele, :pdict)[sym] = value; return; end
  if !has_param(ele, sym); error(f"Not a registered parameter: {sym}. For element: {ele.name} of type {typeof(ele)}."); end
  if !is_settable(ele, sym); error(f"Parameter is not user settable: {sym}. For element: {ele.name}."); end
  getfield(ele, :pdict)[:inbox][sym] = value
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
