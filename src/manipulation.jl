#---------------------------------------------------------------------------------------------------
# branch.XXX dot operator overload

function Base.getproperty(branch::Branch, s::Symbol)
  if s == :ele; return getfield(branch, :ele); end
  if s == :pdict; return getfield(branch, :pdict); end
  if s == :name; return getfield(branch, :name); end
  return getfield(branch, :pdict)[s]
end


function Base.setproperty!(branch::Branch, s::Symbol, value)
  if s == :name; branch.name = value; end
  getfield(branch, :pdict)[s] = value
end

#---------------------------------------------------------------------------------------------------
# ele.XXX dot operator overload

"""
First return value if ele.pdict[s] exists ele.pdict[:inbox][s] exists.
If not found above, get from `ele.pdict[group][s]` where `group` is the corresponding element group.
If no corresponding element group for `s` exists, throw an error.
""" Base.getproperty

function Base.getproperty(ele::T, s::Symbol) where T <: Ele
  if s == :pdict; return getfield(ele, :pdict); end
  pdict = getfield(ele, :pdict)
  if haskey(pdict, s); return pdict[s]; end                  # Does ele.pdict[s] exist?
  if haskey(pdict[:inbox], s); return pdict[:inbox][s]; end  # Does ele.pdict[:inbox][s] exist?

  # If not found above, look for `s` as part of an ele group
  pinfo = ele_param_info(s)
  parent = Symbol(pinfo.parent_group)
  if !haskey(pdict, parent); error(f"Cannot find {s} in element {pdict[:name]}"); end

  if pinfo.kind <: Vector
    pdict[:inbox][s] = copy(getfield(pdict[parent], s))
    return pdict[:inbox][s]
  else
    return ele_group_value(pdict[parent], s)
  end
end

"""
Set ele.pdict[:inbox][s] unless symbol explicitly involves ele group. 
""" Base.setproperty!

function Base.setproperty!(ele::T, s::Symbol, value) where T <: Ele
  if isa_eleparametergroup(s); getfield(ele, :pdict)[s] = value; return; end
  if !has_param(ele, s); error(f"Not a registered parameter: {s}. For element: {ele.name}."); end
  if !is_settable(ele, s); error(f"Parameter is not user settable: {s}. For element: {ele.name}."); end
  getfield(ele, :pdict)[:inbox][s] = value
end
