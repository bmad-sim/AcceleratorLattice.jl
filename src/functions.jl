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
# kill_external_ele

"""
Set external variables corresponding to elements with the same name in a lattice to `nothing`. 
(Currently there is no way to undefine the variables).
See also `create_external_ele`.

The `prefix` argument is needed if a prefix was given in `create_ele_vars`.

The `this_module` argument is needed if the variables are not in the `Main` module. 
Note: `@__MODULE__` is the name of the module of the calling routine.
"""
function kill_external_ele(lat::Lat; prefix::AbstractString = "", this_module = Main)
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
# create_external_ele

"""
Creates `Ele` variables external to a lattice with the same name as the elements in the lattice.

For example, if "q23w" is the name of an element in the lattice, this routine will create a
variable with the name `q23w`. 

In the case where multiple lattice elements have the same name, the corresponding variable 
will be a vector of `Ele`s.

The `prefix` arg can be used to distinguish between elements of the same name in different lattices.

The `this_module` arg is needed if the variables are not to be in the Main module. 
Use `@__MODULE__` for the name of the module of the code calling `create_ele_vars`.

The routine kill_external_ele will remove these external elements.
"""
function create_external_ele(lat::Lat; prefix::AbstractString = "", this_module = Main)
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
ele_at_s(branch::Branch, s::Real; choose_upstream::Bool = true, ele_near = nothing)

Returns lattice element that overlaps a given longitudinal s-position. Also returned
is the location (upstream, downstream, or inside) of the s-position with respect to the returned 

`choose_max`    If there is a choice of elements, which can happen if `s` corresponds to a boundary
                  point, choose the upstream element if choose_upstream is `true` and vice versa.

""" ele_at_s

function ele_at_s(branch::Branch, s::Real; choose_upstream::Bool = true, ele_near = nothing)
  check_if_s_in_branch_range(branch, s)

  # If ele_near is not set
  if ele_near == nothing
    n1 = 1
    n3 = branch.ele[end].pdict[:ix_ele]

    while true
      if n3 == n1 + 1; break; end
      n2 = div(n1 + n3, 2)
      branch.ele[n2].pdict[:s] > s || (choose_max && branch.ele[n2].pdict[:s] == s) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if choose_max && branch.ele[n3].pdict[:s] == s; n1 = n3; end
    return branch.ele[n1]
  end

  # If ele_near is used
  ele = ele_near

  if ele.pdict[:s] < s || choose_max && s == ele.pdict[:s]
    while true
      ele2 = next_ele(ele)
      if ele2.pdict[:s] > s && !choose_upstream && ele.pdict[:s] == s; return ele; end
      if ele2.pdict[:s] > s || (choose_upstream && ele2.pdict[:s] == s); return ele2; end
      ele = ele2
    end

  else
    while true
      ele2 = next_ele(ele, -1)
      if ele2.pdict[:s] < s && choose_upstream && ele.pdict[:s] == s; return ele; end
      if ele2.pdict[:s] < s || (!choose_upstream && ele2.pdict[:s] == s); return ele2; end
      ele = ele2
    end
  end
end

#-----------------------------------------------------------------------------------------
# next_ele

function next_ele(ele, offset::Integer=1)
  branch = ele.pdict[:branch]
  ix_ele = mod(ele.pdict[:ix_ele] + offset-1, length(branch.ele)-1) + 1
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
Returns the equivalent inbounds s-position in the range [branch.ele[1].pdict(:s), branch.ele[end].pdict(:s)]
if the branch has a closed geometry. Otherwise returns s.
This is useful since in closed geometries 
"""
function s_inbounds(branch::Branch, s::Real)
end

#-----------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::Branch, s::Real)
  if s_split < branch.ele[1].pdict[:s] || s_split > branch.ele[end].pdict[:s]
    throw(RangeError(f"s_split ({string(s_split)}) position out of range [{branch.ele[1].pdict[:s]}], for branch ({branch.name})"))
  end
end

#-----------------------------------------------------------------------------------------
# branch_insert_ele!

function branch_insert_ele!(branch::Branch, ix_ele::Int, ele::Ele)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
end

