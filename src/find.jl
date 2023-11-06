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
  return ele(ele.pdict[branch], offset + ele.pdict[:ix_ele], wrap)
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
Returns `true`/`false` if `name` matches/does not match `branch`.
A match can match branch.name or the branch index.
A blank name matches all branches.
Bmad standard wildcard characters "*" and "%" can be used.
"""
function matches_branch(name::AbstractString, branch::Branch)
  if name == ""; return true; end

  ix = integer(name, 0)
  if ix > 0
    return ix == branch.pdict[:ix_branch]
  else
    return str_match(name, branch.name)
  end
end

#-----------------------------------------------------------------------------------------
# ele_finder_base

"""
Returns a vector of all lattice elements that match element `name` which is in the form:
  {branch_id>>}ele_id{#N}{+/-offset}
or
  {branch_id>>}attribute->match_str{+/-offset}

To match to element lists, use the `eles` function.
"""
function ele_finder_base(lat::Lat, name::Union{AbstractString,Regex})
  julia_regex = (typeof(name) == Regex)
  name = string(name)

  eles = Ele[]
  if julia_regex
    name = string(name)[3:end-1]
  else
    name = replace(name, "'" => "\"")
  end

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
        if !haskey(ele.pdict, attrib); continue; end
        if julia_regex
          if occursin(pattern, ele.pdict[attrib]); push!(eles, ele_offset(ele, offset)); end
        else
          if str_match(pattern, ele.pdict[attrib]); push!(eles, ele_offset(ele, offset)); end
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
s-position. This is the same as order by index except in the case where where there are super_lord elements. 
Since super_lord elements always have a greater index (at least in branch 0), order by index will 
place any super_lord elements at the end of the list.

Note: When there are multiple element names in loc_str (which will be separated by a comma or blank), 
the elements in the eles(:) array will be in the same order as they appear loc_str. For example,
with who = "quad::*,sbend::*", all the quadrupoles will appear in eles(:) before all of the sbends.
"""
function ele_finder(lat::Lat, who::Union{AbstractString,Regex})
  # Julia regex is simple
  if typeof(who) == Regex; return ele_finder_base(lat, who); end

  # Intersection
  list = str_split(who, "~&", limit = 3)
  if length(list) == 2 || list[1] == "~" || list[1] == "&" || 
                            (length(list) == 3 && (list[3] == "~" || list[3] == "&"))
    throw(BmadParseError("Cannot parse: " * who))
  end

  eles1 = ele_finder_base(lat, list[1])
  if length(list) == 1; return eles1; end

  eles2 = ele_finder(lat, list[3])
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
# branch_finder

"""
Returns branch corresponding to name. Else returns `nothing`
"""

function branch_finder(lat::Lat, name::AbstractString)
  for branch in lat.branch
    if matches_branch(name, branch); return branch; end
  end
  return nothing
end

