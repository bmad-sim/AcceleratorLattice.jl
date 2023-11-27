#---------------------------------------------------------------------------------------------------
# lat.XXX dot operator overload

"""
    Base.getproperty(lat::Lat, s::Symbol)

Redirect Lat.XXX to Lat.pdict[:XXX] . 
Exceptions are:
  Lat.name, Lat.branch, Lat.pdict
""" Base.getproperty

function Base.getproperty(lat::Lat, s::Symbol)
  if s == :name; return getfield(lat, :name); end
  if s == :branch; return getfield(lat, :branch); end
  if s == :pdict; return getfield(lat, :pdict); end
  return getfield(lat, :pdict)[s]
end


function Base.setproperty!(lat::Lat, s::Symbol, value)
  if s == :name;   return setfield!(lat, :name, value); end
  if s == :branch; return setfield!(lat, :branch, value); end
  getfield(lat, :pdict)[s] = value
end

#---------------------------------------------------------------------------------------------------
# branch.XXX dot operator overload

function Base.getproperty(branch::Branch, s::Symbol)
  if s == :name; return getfield(branch, :name); end
  if s == :ele; return getfield(branch, :ele); end
  if s == :pdict; return getfield(branch, :pdict); end
  return getfield(branch, :pdict)[s]
end


function Base.setproperty!(branch::Branch, s::Symbol, value)
  if s == :name; return setfield!(branch, :name, value); end
  if s == :ele;  return setfield!(branch, :ele, value); end
  getfield(branch, :pdict)[s] = value
end

#---------------------------------------------------------------------------------------------------
# ele.XXX dot operator overload

"""
First return value if ele.pdict[s] exists ele.pdict[:inbox][s] exists.
If not found above, get from `ele.pdict[group][s]` where `group` is the corresponding element group.
If no corresponding element group for `s` exists, throw an error.
""" Base.getproperty

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

"""
Set ele.pdict[:inbox][s] unless symbol explicitly involves ele group. 
""" Base.setproperty!

function Base.setproperty!(ele::T, s::Symbol, value) where T <: Ele
  # :name is special since it is not associated with an element group.
  if isa_eleparametergroup(s) || s == :name; getfield(ele, :pdict)[s] = value; return; end
  if !has_param(ele, s); error(f"Not a registered parameter: {s}. For element: {ele.name} of type {typeof(ele)}."); end
  if !is_settable(ele, s); error(f"Parameter is not user settable: {s}. For element: {ele.name}."); end
  getfield(ele, :pdict)[:inbox][s] = value
end
