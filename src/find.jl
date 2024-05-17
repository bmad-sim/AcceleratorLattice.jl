#---------------------------------------------------------------------------------------------------
# ele_at_index

"""
    ele_at_index(branch::Branch, ix_ele::Int; wrap::Bool = true)  -> ::Ele

Returns element with index `ix_ele` in branch `branch`.

With `wrap` = `false`, an error is raised if `ix_ele` is out-of-bounds.

With `wrap` = `true`, if `ix_ele` is out-of-bounds, will "wrap" around ends of the branch so,
for a branch with `N` elements,
`ix_ele = N+1` will return `branch.ele[1]` and `ix_ele = 0` will return `branch.ele[N]`.
""" ele_at_index

function ele_at_index(branch::Branch, ix_ele::Int; wrap::Bool = true)
  n = length(branch.ele)

  if wrap
    if n == 0; error(f"BoundsError: " *           # Happens with lord branch with no lord elements
              f"Element index: {ix_ele} out of range in branch {branch.ix_branch}: {branch.name}"); end
    ix_ele = mod(ix_ele-1, n) + 1
    return branch.ele[ix_ele]
  else
    if ix_ele < 1 || ix_ele > n; error(f"BoundsError: " * 
              f"Element index: {ix_ele} out of range in branch {branch.ix_branch}: {branch.name}"); end
    return branch.ele[ix_ele]
  end
end

#---------------------------------------------------------------------------------------------------
# find_ele_base

"""
    function find_ele_base(lat::Lat, name::Union{AbstractString,Regex})

Returns a vector of all lattice elements that match element `name` which is in the form:
  {branch_id>>}ele_id{#N}{+/-offset}
or
  {branch_id>>}attribute->match_str{+/-offset}

To match to element lists, use the `eles` function.
""" find_ele_base

function find_ele_base(lat::Lat, name::Union{AbstractString,Regex})
  julia_regex = (typeof(name) == Regex)
  name = string(name)

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
    if length(words) == 2 || length(words) > 3; error(f"ParseError: Bad lattice element name: {name}"); end
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

      if length(words) != 1; error(f"ParseError: Bad lattice element name: {name}"); end
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

#---------------------------------------------------------------------------------------------------
# find_eles

"""
    function find_eles(lat::Lat, who::Union{AbstractString,Regex})

Returns a vector of all lattice elements that match `who`.
This is an extension of `ele(lat, name)` to include 
  key selection EG: "Quadrupole::<list>"
  ranges        EG: "<ele1>:<ele2>"
  negation      EG: "<list1> ~<list2>"
  intersection  EG: "<list1> & <list2>"
Note: negation and intersection evaluated left to right

ele vector will be ordered by s-position for each branch.

Also see `find_ele`

Note: For something like `who` = `"quad::*"`, if order_by_index = True, the eles(:) array will
be ordered by element index. If order_by_index = False, the eles(:) array will be ordered by
s-position. This is the same as order by index except in the case where where there are super_lord elements. 
Since super_lord elements always have a greater index (at least in branch 0), order by index will 
place any super_lord elements at the end of the list.

Note: When there are multiple element names in loc_str (which will be separated by a comma or blank), 
the elements in the eles(:) array will be in the same order as they appear loc_str. For example,
with who = "quad::*,sbend::*", all the quadrupoles will appear in eles(:) before all of the sbends.
""" find_eles

function find_eles(lat::Lat, who::Union{AbstractString,Regex})
  # Julia regex is simple
  if typeof(who) == Regex; return find_ele_base(lat, who); end

  # Intersection
  list = str_split(who, "~&", limit = 3)
  if length(list) == 2 || list[1] == "~" || list[1] == "&" || 
                            (length(list) == 3 && (list[3] == "~" || list[3] == "&"))
    error(f"ParseError: Cannot parse: {who}")
  end

  eles1 = find_ele_base(lat, list[1])
  if length(list) == 1; return eles1; end

  eles2 = find_eles(lat, list[3])
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
    error(f"ParseError: Cannot parse: {who}")
  end

  return eles
end

#---------------------------------------------------------------------------------------------------
# find_ele

"""
    function find_ele(lat::Lat, who::Union{AbstractString,Regex}; default = NULL_ELE)

Returns element specified by `who`. 

- `default`   Value to return if the number of elements matching `who` is not one. 
If the value of `default` is `missing`, an error is thrown. 
""" find_ele

function find_ele(lat::Lat, who::Union{AbstractString,Regex}; default = NULL_ELE)
  eles = find_eles(lat, who)
  if length(eles) == 1; return eles[1]; end
  if (ismissing(default))
    if length(eles) == 0
      error(f"Cannot find: {who} in lattice")
    else
      error(f"FindError: More than one element matches: {who} in lattice")
    end
  end
end

#---------------------------------------------------------------------------------------------------
# branch

"""
    branch(lat::Lat, ix::Int)
    branch(lat::Lat, who::AbstractString) 

Returns the branch in `lat` with index `ix` or name that matches `who`.

Returns `nothing` if no branch can be matched.
""" branch

function branch(lat::Lat, ix::Int) 
  if ix < 1 || ix > length(lat.branch); error(f"Branch index {ix} out of bounds."); end
  return lat.branch[ix]
end

function branch(lat::Lat, who::AbstractString) 
  for branch in lat.branch
    if branch.name == who; return branch; end
  end
  error(f"Cannot find branch with name {name} in lattice.")
end

#---------------------------------------------------------------------------------------------------
# ele_at_s

"""
    ele_at_s(branch::Branch, s::Real, choose_downstream::Bool; ele_near::ELE = NULL_ELE) -> ele::Ele

Returns lattice element that overlaps a given longitudinal s-position. That is, `s` will be in the
half-open interval `[ele.s, ele.s_downstream)` (or the point `ele.s` if `ele` has zero length) where 
`ele` is the returned element.

## Input

 - `branch`            Branch to search.
 - `s`                 Longitudinal position to match to.
 - `choose_downstream` If there is a choice of elements, which can happen if `s` corresponds to a boundary
                       point, choose the downstream element if choose_downstream is `true` and vice versa.
 - `ele_near`          If there are elements with negative drift lengths (generally this will be a
                       `drift` or `patch` element), there might be multiple solutions. If `ele_near`
                       is specified, this routine will choose the solution nearest `ele_near`.

## Return

 - Returns element that overlaps the given `s` position.

""" ele_at_s

function ele_at_s(branch::Branch, s::Real, choose_downstream::Bool; ele_near::Ele = NULL_ELE)
  check_if_s_in_branch_range(branch, s)

  # If ele_near is not set
  if is_null(ele_near)
    n1 = 1
    n3 = branch.ele[end].ix_ele

    while true
      if n3 == n1 + 1; break; end
      n2 = div(n1 + n3, 2)
      s < branch.ele[n2].s || (!choose_downstream && branch.ele[n2].s == s) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if choose_downstream && branch.ele[n3].s == s
      return branch.ele[n3]
    else
      return branch.ele[n1]
    end
  end

  # If ele_near is used
  ele = ele_near
  if ele.branch.type <: LordBranch
    choose_downstream ? ele = ele.slaves[end] : ele = ele.slaves[1]
  end


  if s > ele.s_downstream || (choose_downstream && s == ele.s_downstream)
    while true
      ele = next_ele(ele)
      if s < ele.s_downstream || (s == ele.s_downstream && !choose_downstream); return ele; end
    end

  else
    while true
      if s > ele.s || (choose_downstream && ele.s == s); return ele; end
      ele = next_ele(ele, -1)
    end
  end
end
