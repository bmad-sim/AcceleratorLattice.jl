#-----------------------------------------------------------------------------------------
# LatEle[] get and set

function Base.getindex(ele::LatEle, key)
  if key == :name; return ele.name; end
  return ele.param[key]
end

function Base.setindex!(ele::LatEle, val, key)
  if key == :name
    ele.name = val
  else
    ele.param[key] = val
  end
  return ele
end

#-----------------------------------------------------------------------------------------
# bmad_regex

bmad_regex(str::AbstractString) = occursin("%", str) || occursin("*", str)

#-----------------------------------------------------------------------------------------
# offset_latele

"""
Returns the lattice element that is a distance `offset` from the input `ele`.
Will wrap around the ends of the branch if necessary and wrap = true.
"""
function latele_offset(ele::LatEle, offset::Int, wrap::Bool = true)
  return latele(ele.param[branch], offset + ele.param[:ix_ele], wrap)
end


"""
"""
function latele(branch::LatBranch, ix_ele::Int; wrap::Bool = true)
  n = size(branch.ele,1)

  if wrap
    ix_ele = mod(ix_ele-1, n-1) + 1
    return branch.ele[ix_ele]
  else
    if ix_ele < 0 || ix_ele > n; throw(BoundsError(f"Element index out of range {ix_ele} in branch {branch.name}")); end
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
function matches_branch(name::AbstractString, branch::LatBranch)
  if name == "": return true; end

  try
    ix = parse(Int, name)
    return branch.param[ix_branch] == ix
  catch
    str_match(name, branch.name)
  end
end

#-----------------------------------------------------------------------------------------
# lateles_finder_base

"""
Returns a vector of all lattice elements that match element `name` which is in the form:
  {branch_id>>}ele_id{#N}{+/-offset}
or
  {branch_id>>}attribute->match_str{+/-offset}

To match to element lists, use the `lateles` function.
"""
function lateles_finder_base(Lat::Lat, name::AbstractString)

  eles = LatEle[]
  name = replace(name, "'" => "\"")
  branch_id = ""; offset = 0
  nth_match = 1

  if occursin(">>", name); branch_id, name = split(name, ">>"); end

  # attrib->pattern construct
  if occursin("->", name)
    attrib, pattern = split(name, "->")
    attrib = Meta.parse(attrib)     # Makes attrib a Symbol

    words = str_split(pattern, "+-")
    if size(words,1) == 2 || size(words,1) > 3; throw(BmadParseError("Bad lattice element name: " * name)); end
    pattern = str_unquote(words[1])
    if size(words,1) == 3; offset = parse(Int, words[2]*words[3]); end

    for branch in lat.branch
      if !matches_branch(branch, branch_id); continue; end
      for ele in branch.ele
        if !haskey(ele.param, attrib); continue; end
        if str_match(pattern, ele.param[attrib]) push!(eles, latele_offset(ele, offset)); end
      end
    end

  # ele_id construct
  else
    words = str_split(name, "+-#", doubleup = true)

    if size(words,1) > 2 && occursin(words[end-1], "+-")
      offset = parse(Int, words[end-1]*words[end])
      words = words[:end-2]
    end

    if size(words,1) > 2 && words[end-1] == "#"
      nth_match = parse(Int, words[end])
      words = words[:end-2]
    end

    if size(words,1) != 1; throw(BmadParseError("Bad lattice element name: " * name)); end
    ele_id = words[1]
    ix_ele = str_to_int(ele_id, -1)
    if ix_ele != NaN && nth_match != 1; return eles; end

    for branch in lat.branch
      if !matches_branch(branch_id, branch); continue; end
      if ix_ele != -1
        push!(eles, latele(branch, ix_ele, wrap = false))
        continue
      end

      ix_match = 0
      for ele in branch.ele
        if !str_match(ele_id, ele.name); continue; end
        ix_match += 1
        if ix_match == nth_match; push!(eles, ele); end
        if ix_match > nth_match; continue; end
      end
    end   # branch loop

    return eles
  end
end

#-----------------------------------------------------------------------------------------
# latele_finder

function latele_finder(Lat::Lat, name::AbstractString)
    eles = lateles_finder_base(lat, name)
    if size(eles,1) == 0; return null_latele; end
    return eles[1]
end

#-----------------------------------------------------------------------------------------
# lateles_finder

"""
Returns a vector of all lattice elements that match `who`.
This is an extension of `latele(lat, name)` to include 
  key selection EG: "Quadrupole::<list>"
  ranges        EG: "<ele1>:<ele2>"
  negation      EG: "<list1> ~<list2>"
  intersection  EG: "<list1> & <list2>"
Note: negation and intersection evaluated left to right

latele vector will be ordered by s-position for each branch.
Use the lateles_order_by_index function to reorder by index is desired.
"""
function lateles_finder(lat::Lat, who::AbstractString)
  # Intersection
  list = str_split("~&", who, limit = 3)
  if size(list,1) == 2 || list[1] == "~" || list[1] == "&" || list[3] == "~" || list[3] == "&"
    throw(BmadParseError("Cannot parse: " * who))
  end

  eles1 = lateles_finder_base(lat, list[1])
  if size(list,1) == 1; return eles1; end

  eles2 = lateles_finder(lat, list[3])
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
# lateles_order_by_index

"""
Rearranges a latele vector in order by element index.
"""
function lateles_order_by_index(eles)
  return eles
end

#-----------------------------------------------------------------------------------------
# latele_at_s

"""
latele_at_s(branch::LatBranch, s::Real; choose_max::Bool = False, ele_near = nothing)

Returns lattice element that overlaps a given longitudinal s-position. Also returned
is the location (upstream, downstream, or inside) of the s-position with respect to the returned 

"""
function latele_at_s(branch::LatBranch, s::Real; choose_max::Bool = False, ele_near = nothing)
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
      ele2 = next_latele(ele)
      if ele2.param[:s] > s && choose_max && ele.param[:s] == s; return ele; end
      if ele2.param[:s] > s || (!choose_max && ele2.param[:s] == s); return ele2; end
      ele = ele2
    end

  else
    while true
      ele2 = next_latele(ele, -1)
      if ele2.param[:s] < s && !choose_max && ele.param[:s] == s; return ele; end
      if ele2.param[:s] < s || (choose_max && ele2.param[:s] == s); return ele2; end
      ele = ele2
    end
  end
end

#-----------------------------------------------------------------------------------------
# next_latele

function next_latele(ele, offset::Integer=1)
  branch = ele.param[:branch]
  ix_ele = mod(ele.param[:ix_ele] + offset-1, size(branch.ele,1)-1) + 1
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
function branch_split!(branch::LatBranch, s_split::Real; choose_max::Bool = False, ix_insert::Int = -1)
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
function s_inbounds(branch::LatBranch, s::Real)
end

#-----------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::LatBranch, s::Real)
  if s_split < branch.ele[1].param[:s] || s_split > branch.ele[end].param[:s]
    throw(RangeError(f"s_split ({string(s_split)}) position out of range [{branch.ele[1].param[:s]}], for branch ({branch.name})"))
  end
end

#-----------------------------------------------------------------------------------------
# branch_insert_latele!

function branch_insert_latele!(branch::LatBranch, ix_ele::Int, ele::LatEle)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
end

#-----------------------------------------------------------------------------------------
# branch_bookkeeper!

function branch_bookkeeper!(branch::LatBranch)
  if branch.name == "lord"; return; end
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.param[:ix_ele] = ix_ele
    if ix_ele > 1; ele.param[:s] = branch.ele[ix_ele-1].param[:s] + get(branch.ele[ix_ele-1].param, :len, 0); end
  end
end

#-----------------------------------------------------------------------------------------
# lat_bookkeeper!


function lat_bookkeeper!(lat::Lat)
  for branch in lat.branch
    branch_bookkeeper!(branch)
  end
end