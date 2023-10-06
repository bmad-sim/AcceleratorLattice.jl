#-----------------------------------------------------------------------------------------
# lat_ele_dict

"""
    lat_ele_dict(lat::Lat)

Return a dictionary of `ele_name => Vector{Ele}` mapping of lattice element names to arrays of
elements with that name.

### Input

- `lat` -- Lattice to use.

### Output

(String, Vector{Ele}) Dictionary where the keys are element names and the values are vectors of elements of whose
name matches the key

### Example

eled = lat_ele_dict(lat)    # Create Dictionary
eled["q23w"]                


"""

function lat_ele_dict(lat::Lat)
  eled = Dict{String,Vector{Ele}}()
  for branch in lat.branch
    for ele in branch.ele
      if haskey(eled, ele.name)
        eled[ele.name]
        push!(eled[ele.name], ele)
      else
        eled[ele.name] = Vector{Ele}([ele])
      end
    end
  end
  return eled
end

#-----------------------------------------------------------------------------------------
# kill_ele_vars

"""
Set variables created with create_ele_vars to `nothing`. 
(Currently there is no way to undefine the variables).

The `prefix` argument is needed if a prefix was given in `create_ele_vars`.

The `this_module` argument is needed if the variables are not in the `Main` module. 
Note: `@__MODULE__` is the name of the module of the calling routine.
"""
function kill_ele_vars(lat::Lat; prefix::AbstractString = "", this_module = Main)
  for branch in lat.branch
    for ele in branch.ele
      nam = prefix * ele.name
      if !isdefined(this_module, Symbol(nam)); continue; end
      eval( :($(Symbol(nam)) = nothing) )
    end
  end
  return nothing
end

#-----------------------------------------------------------------------------------------
# create_ele_vars

"""
Creates `Ele` variables external to a lattice with the same name as the elements in the lattice.

For example, if "q23w" is the name of an element in the lattice, this routine will create a
variable with the name `q23w`. 

In the case where multiple lattice elements have the same name, the corresponding variable 
will be a vector of `Ele`s.

The `prefix` arg can be used to distinguish between elements of the same name in different lattices.

The `this_module` arg is needed if the variables are not to be in the Main module. 
Use `@__MODULE__` for the name of the module of the code calling `create_ele_vars`.
"""
function create_ele_vars(lat::Lat; prefix::AbstractString = "", this_module = Main)
  eled = lat_ele_dict(lat)

  for (name, evec) in eled
    if length(evec) == 1
      eval( :($(Symbol(this_module)).$(Symbol(name)) = $(evec[1])) )
    else
      eval( :($(Symbol(this_module)).$(Symbol(name))= $(evec)) )
    end
  end
  return nothing
end

#-----------------------------------------------------------------------------------------
# create_unique_ele_names!

"""
function create_unique_ele_names!(lat::Lat; suffix::AbstractString = "!#")

Modifies a lattice so that all elements have a unique name.

For elements whose names are not unique, the `suffix` arg is appended to the element name
and an integer is substituted for  the "#" character in the suffix arg. If no "#" 
character exists, a "#" character is appended to the suffix arg.
"""
function create_unique_ele_names!(lat::Lat; suffix::AbstractString = "!#")
  if !occursin("#", suffix); suffix = suffix * "#"; end
  eled = lat_ele_dict(lat)

  for (name, evec) in eled
    if length(evec) == 1; continue; end
    for (ix, ele) in enumerate(evec)
      ele.name = ele.name * replace(suffix, "#" => string(ix))
    end
  end

  return nothing
end

#-----------------------------------------------------------------------------------------
# Ele[] get and set

function Base.getindex(ele::Ele, key)
  if key == :name; return ele.name; end
  return ele.param[key]
end

function Base.setindex!(ele::Ele, val, key)
  if key == :name
    ele.name = val
  else
    
    ele.param[key] = val
  end
  return ele
end

#-----------------------------------------------------------------------------------------
# Vector{Ele}[] get and set

function Base.getindex(eles::Vector{Ele}, key::Symbol)
  return [ele[key] for ele in eles]
end

function Base.setindex!(eles::Vector{Ele}, val, key::Symbol)
  for ele in eles
    ele[key] = val
  end
  return eles
end

#-----------------------------------------------------------------------------------------
# Branch[] get and set


"""
"""
function Base.getindex(branch::Branch, key)
  if key == :name; return branch.name; end
  if haskey(branch.param, key)
    return branch.param[key]
  elseif haskey(branch_param_defaults, key)
    return branch_param_defaults[key]
  else
    return "branch.param key not found: " * key
  end
end

function Base.setindex!(branch::Branch, val, key)
  if key == :name
    branch.name = val
  else
    branch.param[key] = val
  end
  return ele
end

#-----------------------------------------------------------------------------------------
# get_group for element groups

function get_group(group::Type{T}, ele::Ele) where T <: EleParameterGroup
  return ele.param[Symbol(group)]
end


#-----------------------------------------------------------------------------------------
# eles_order_by_index

"""
Rearranges a ele vector in order by element index.
"""
function eles_order_by_index(eles)
  return eles
end

#-----------------------------------------------------------------------------------------
# ele_at_s

"""
ele_at_s(branch::Branch, s::Real; choose_max::Bool = False, ele_near = nothing)

Returns lattice element that overlaps a given longitudinal s-position. Also returned
is the location (upstream, downstream, or inside) of the s-position with respect to the returned 

"""
function ele_at_s(branch::Branch, s::Real; choose_max::Bool = False, ele_near = nothing)
  check_if_s_in_branch_range(branch, s)

  # If ele_near is not set
  if ele_near == nothing
    n1 = 1
    n3 = branch.ele[end].param[:ix_ele]

    while true
      if n3 == n1 + 1; break; end
      n2 = div(n1 + n3, 2)
      branch.ele[n2].param[:s] > s || (choose_max && branch.ele[n2].param[:s] == s) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if choose_max && branch.ele[n3].param[:s] == s; n1 = n3; end
    return branch.ele[n1]
  end

  # If ele_near is used
  ele = ele_near

  if ele.param[:s] < s || choose_max && s == ele.param[:s]
    while true
      ele2 = next_ele(ele)
      if ele2.param[:s] > s && choose_max && ele.param[:s] == s; return ele; end
      if ele2.param[:s] > s || (!choose_max && ele2.param[:s] == s); return ele2; end
      ele = ele2
    end

  else
    while true
      ele2 = next_ele(ele, -1)
      if ele2.param[:s] < s && !choose_max && ele.param[:s] == s; return ele; end
      if ele2.param[:s] < s || (choose_max && ele2.param[:s] == s); return ele2; end
      ele = ele2
    end
  end
end

#-----------------------------------------------------------------------------------------
# next_ele

function next_ele(ele, offset::Integer=1)
  branch = ele.param[:branch]
  ix_ele = mod(ele.param[:ix_ele] + offset-1, length(branch.ele)-1) + 1
  return branch.ele[ix_ele]
end

#-----------------------------------------------------------------------------------------
# branch_split!

"""
Routine to split an lattice element of a branch into two to create a branch that has an element boundary at the point s = s_split. 
This routine will not split the lattice if the split would create a "runt" element with length less 
than 5*bmad_com%significant_length.

branch_split! will redo the appropriate bookkeeping for lords and slaves.
A super_lord element will be created if needed. 
"""
function branch_split!(branch::Branch, s_split::Real; choose_max::Bool = False, ix_insert::Int = -1)
  check_if_s_in_branch_range(branch, s_split)
  # return ix_split, split_done
end

#-----------------------------------------------------------------------------------------
# s_inbounds

"""
Returns the equivalent inbounds s-position in the range [branch.ele[1].param(:s), branch.ele[end].param(:s)]
if the branch has a closed geometry. Otherwise returns s.
This is useful since in closed geometries 
"""
function s_inbounds(branch::Branch, s::Real)
end

#-----------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::Branch, s::Real)
  if s_split < branch.ele[1].param[:s] || s_split > branch.ele[end].param[:s]
    throw(RangeError(f"s_split ({string(s_split)}) position out of range [{branch.ele[1].param[:s]}], for branch ({branch.name})"))
  end
end

#-----------------------------------------------------------------------------------------
# branch_insert_ele!

function branch_insert_ele!(branch::Branch, ix_ele::Int, ele::Ele)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
end

#-----------------------------------------------------------------------------------------
# branch_bookkeeper!

function branch_bookkeeper!(branch::Branch)
  if branch.param[:type] == LordBranch
    for (ix_ele, ele) in enumerate(branch.ele)
      ele[:ix_ele] = ix_ele
      ele[:branch] = branch
    end
    return
  end

  ele = branch.ele[1]
  ele.param[:ix_ele] = 1
  ele.param[:branch] = branch
  if !haskey(ele.param, :s); ele.param[:s] = 0; end
  if !haskey(ele.param, :floor_position); ele.param[:floor_position] = FloorPositionGroup(); end
  ele.param[:s_exit] = ele.param[:s]

  # ReferenceGroup
  rg = ele.param[:ReferenceGroup]
  if rg.species_ref.name == notset_name; error(f"Species not set in branch: {branch.name}"); end

  if !isnan(ele.pc_ref) && !isnan(ele.E_tot_ref)
    error(f"Beginning element has both pc_ref and E_tot_ref set in branch: {branch.name}")
  elseif isnan(ele.pc_ref) && isnan(ele.E_tot_ref)
    error(f"pc_ref and E_tot_ref not set for beginning element in branch: {branch.name}")
  elseif !isnan(ele.pc_ref)
    rg = @set rg.E_tot_ref = E_tot(ele.pc_ref, rg.species_ref)
  else
    rg = @set rg.pc_ref = pc(ele.E_tot_ref, rg.species_ref)
  end

  ele.param[:ReferenceGroup] = ReferenceGroup(pc_ref = rg.pc_ref, pc_ref_exit = rg.pc_ref,
                       E_tot_ref = rg.E_tot_ref, E_tot_ref_exit = rg.E_tot_ref,
                       time_ref = rg.time_ref, time_ref_exit = rg.time_ref, species_ref = rg.species_ref)

  old_ele = ele

  for (ix, ele) in enumerate(branch.ele[2:end])
    ele.param[:ix_ele] = old_ele.param[:ix_ele] + 1 
    ele.param[:s] = old_ele.param[:s_exit]
    ele.param[:s_exit] = ele.param[:s] + get(ele.param, :len, 0)
    ele.param[:branch] = branch
    # Floor position

    # Reference energy and time
    rg = ele.param[:ReferenceGroup]
    dt = c_light * ele.len * rg.pc_ref / rg.E_tot_ref
    ele.param[:ReferenceGroup] = ReferenceGroup(pc_ref = rg.pc_ref, pc_ref_exit = rg.pc_ref,
                       E_tot_ref = rg.E_tot_ref, E_tot_ref_exit = rg.E_tot_ref,
                       time_ref = rg.time_ref, time_ref_exit = rg.time_ref + dt, species_ref = rg.species_ref)

    old_ele = ele
  end
end

#-----------------------------------------------------------------------------------------
# lat_bookkeeper!

function lat_bookkeeper!(lat::Lat)
  for (ix, branch) in enumerate(lat.branch)
    branch.param[:ix_branch] = ix
    branch_bookkeeper!(branch)
  end
  # Put stuff like ref energy in lords
end