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

function get_group(group::Type{T}, ele::Ele) where T <: ParameterGroup
  return ele.param[Symbol(group)]
end

#-----------------------------------------------------------------------------------------
# bmad_regex

bmad_regex(str::AbstractString) = occursin("%", str) || occursin("*", str)

#-----------------------------------------------------------------------------------------
# ele

"""
    function ele(ele::Ele, index_offset::Int, wrap::Bool = true)

Returns the lattice element whose index relative to the index of the input `ele` is `index_offset`.
Will wrap around the ends of the branch if necessary and wrap = true.

### Input


### Output
  `Ele` in given `branch` and given element i
"""
function ele(ele::Ele, index_offset::Int, wrap::Bool = true)
  return ele(ele.param[branch], offset + ele.param[:ix_ele], wrap)
end


"""
    ele(branch::Branch, ix_ele::Int; wrap::Bool = true)

Returns element in given `branch` with given `ix_ele` element index.

### Input
If `wrap`


### Output
- `Ele` in given `branch` and given element index `ix_ele
"""
function ele(branch::Branch, ix_ele::Int; wrap::Bool = true)
  n = length(branch.ele)

  if wrap
    ix_ele = mod(ix_ele-1, n-1) + 1
    return branch.ele[ix_ele]
  else
    if ix_ele < 1 || ix_ele > n; throw(BoundsError(f"element index out of range {ix_ele} in branch {branch.name}")); end
    return branch.ele[ix_ele]
  end
end

#-----------------------------------------------------------------------------------------
# matches_branch

"""
Returns if name matches the branch.
A match can match branch.name or the branch index.
A blank name matches all branches.
Bmad standard wildcard characters "*" and "%" can be used.
"""
function matches_branch(name::AbstractString, branch::Branch)
  if name == ""; return true; end

  try
    ix = parse(Int, name)
    return branch.param[:ix_branch] == ix
  catch
    str_match(name, branch.name)
  end
end

#-----------------------------------------------------------------------------------------
# eles_finder_base

"""
Returns a vector of all lattice elements that match element `name` which is in the form:
  {branch_id>>}ele_id{#N}{+/-offset}
or
  {branch_id>>}attribute->match_str{+/-offset}

To match to element lists, use the `eles` function.
"""
function eles_finder_base(Lat::Lat, name::AbstractString, julia_regex::Bool=false)

  eles = Ele[]
  if !julia_regex; name = replace(name, "'" => "\""); end
  branch_id = ""; offset = 0
  nth_match = 1

  if occursin(">>", name); branch_id, name = split(name, ">>"); end

  # attrib->pattern construct
  if occursin("->", name)
    attrib, pattern = split(name, "->")
    attrib = Meta.parse(attrib)     # Makes attrib a Symbol

    words = str_split(pattern, "+-")
    if length(words) == 2 || length(words) > 3; throw(BmadParseError("Bad lattice element name: " * name)); end
    pattern = str_unquote(words[1])
    if length(words) == 3; offset = parse(Int, words[2]*words[3]); end

    for branch in lat.branch
      if !matches_branch(branch, branch_id); continue; end
      for ele in branch.ele
        if !haskey(ele.param, attrib); continue; end
        if julia_regex
          if occursin(pattern, ele.param[attrib]); push!(eles, ele_offset(ele, offset)); end
        else
          if str_match(pattern, ele.param[attrib]); push!(eles, ele_offset(ele, offset)); end
        end
      end
    end

  # ele_id construct
  else
    ix_ele = -1
    if !julia_regex
      words = str_split(name, "+-#", doubleup = true);

      if length(words) > 2 && occursin(words[end-1], "+-")
        offset = parse(Int, words[end-1]*words[end])
        words = words[:end-2]
      end

      if length(words) > 2 && words[end-1] == "#"
        nth_match = parse(Int, words[end])
        words = words[:end-2]
      end

      if length(words) != 1; throw(BmadParseError("Bad lattice element name: " * name)); end
      ele_id = words[1]
      ix_ele = str_to_int(ele_id, -1)
      if ix_ele != NaN && nth_match != 1; return eles; end
    end

    for branch in lat.branch
      if !matches_branch(branch_id, branch); continue; end
      if ix_ele != -1
        push!(eles, ele(branch, ix_ele, wrap = false))
        continue
      end

      ix_match = 0
      for ele in branch.ele
        if julia_regex
          if match(ele_id, ele.name); push!(eles, ele); end
        else
          if !str_match(ele_id, ele.name); continue; end
          ix_match += 1
          if ix_match == nth_match; push!(eles, ele); end
          if ix_match > nth_match; continue; end
        end
      end
    end   # branch loop

    return eles
  end
end

#-----------------------------------------------------------------------------------------
# ele_finder

function ele_finder(Lat::Lat, name::AbstractString; julia_regex::Bool = false)
    eles = eles_finder_base(lat, name, julia_regex)
    if length(eles) == 0; return NULL_ELE; end
    return eles[1]
end

#-----------------------------------------------------------------------------------------
# eles_finder

"""
Returns a vector of all lattice elements that match `who`.
This is an extension of `ele(lat, name)` to include 
  key selection EG: "Quadrupole::<list>"
  ranges        EG: "<ele1>:<ele2>"
  negation      EG: "<list1> ~<list2>"
  intersection  EG: "<list1> & <list2>"
Note: negation and intersection evaluated left to right

ele vector will be ordered by s-position for each branch.
Use the eles_order_by_index function to reorder by index is desired.


Note: For something like loc_str = "quad::*", if order_by_index = True, the eles(:) array will
be ordered by element index. If order_by_index = False, the eles(:) array will be ordered by
s-position. This is the same as order by index except in the case where where there are super_lord
elements. Since super_lord elements always have a greater index (at least in branch 0), order by index will place any super_lord elements at the end of the list.

Note: When there are multiple element names in loc_str (which will be separated by a comma or blank), 
the elements in the eles(:) array will be in the same order as they appear loc_str. For example,
with who = "quad::*,sbend::*", all the quadrupoles will appear in eles(:) before all of the sbends.
"""
function eles_finder(lat::Lat, who::AbstractString, julia_regex::Bool=false)
  # Julia regex is simple
  if julia_regex; return eles_finder_base(lat, who, julia_regex); end

  # Intersection
  list = str_split("~&", who, limit = 3)
  if length(list) == 2 || list[1] == "~" || list[1] == "&" || list[3] == "~" || list[3] == "&"
    throw(BmadParseError("Cannot parse: " * who))
  end

  eles1 = eles_finder_base(lat, list[1])
  if length(list) == 1; return eles1; end

  eles2 = eles_finder(lat, list[3])
  eles = []

  if list[2] == "&"
    for ele1 in eles1
      for ele2 in eles2
        if ele1 === ele2; push!(eles, ele1); continue; end
      end
    end

  elseif list[2] == "~"
    for ele1 in eles1
      found = false
      for ele2 in eles2
        if ele1 === ele2; found = true; continue; end
      end
      if !found; push!(eles, ele1); continue; end
    end
  else
    throw(BmadParseError("Cannot parse: " * who))
  end

  return eles
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
  old_ele = ele

  for (ix, ele) in enumerate(branch.ele[2:end])
    ele.param[:ix_ele] = old_ele.param[:ix_ele] + 1 
    ele.param[:s] = old_ele.param[:s] + get(old_ele.param, :len, 0)
    ele.param[:branch] = branch
    # Floor position
    # Reference energy and time
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
  # Put branch index in branch.param
end