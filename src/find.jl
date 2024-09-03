#---------------------------------------------------------------------------------------------------
# ele_at_index

"""
    ele_at_index(branch::Branch, ix_ele::Int; wrap::Bool = true, ele0::Ele = NULL_ELE)  -> ele::Ele

Returns element with index `ix_ele` in branch `branch`.
If `ele0` is not `NULL_ELE`, `ix_ele` will be offset by `ele0.ix_ele`.

With `wrap` = `false`, an error is raised if `ix_ele` is out-of-bounds.

With `wrap` = `true`, if `ix_ele` is out-of-bounds, will "wrap" around ends of the branch so,
for a branch with `N` elements,
`ix_ele = N+1` will return `branch.ele[1]` and `ix_ele = 0` will return `branch.ele[N]`.
""" ele_at_index

function ele_at_index(branch::Branch, ix_ele::Int; wrap::Bool = true, ele0::Ele = NULL_ELE)
  if ele0 != NULL_ELE; ix_ele = ix_ele + ele0.ix_ele; end

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
# eles_base

"""
    Internal: function eles_base(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex})

Internal. Called by `eles` function.
""" eles_base

function eles_base(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex})
  julia_regex = (typeof(who) == Regex)
  who = string(who)
  typeof(where_search) == Lat ? branch_vec = where_search.branch : branch_vec = [where_search]

  eles = Ele[]
  if !julia_regex; who = replace(who, "'" => "\""); end

  branch_id = ""; offset = 0
  nth_match = -1

  if occursin(">>", who); branch_id, who = split(who, ">>"); end

  # attrib->pattern construct
  if occursin("->", who)
    attrib, pattern = split(who, "->")
    attrib = Meta.parse(attrib)     # Makes attrib a Symbol

    words = str_split(pattern, "+-")
    if length(words) == 2 || length(words) > 3; error(f"ParseError: Bad lattice element name: {who}"); end
    pattern = str_unquote(words[1])
    if length(words) == 3; offset = parse(Int, words[2]*words[3]); end

    for branch in branch_vec
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

  # ele_id or key::ele_id construct
  else
    key = nothing
    if occursin("::", who)
      key, who = split(who, "::")
      key = Symbol(key)
    end

    ix_ele = -1
    if !julia_regex
      words = str_split(who, "+-#", doubleup = true)   # EG: ["Marker::*", "-", "1"]

      if length(words) > 2 && occursin(words[end-1], "+-")
        offset = parse(Int, words[end-1]*words[end])
        words = words[1:end-2]
      end

      if length(words) > 2 && words[end-1] == "#"
        nth_match = parse(Int, words[end])
        words = words[1:end-2]
      end

      if length(words) != 1; error(f"ParseError: Bad lattice element name: {who}"); end
      ele_id = words[1]
      ix_ele = str_to_int(ele_id, -1)
      if ix_ele != -1 && nth_match != -1; return eles; end
    end

    for branch in branch_vec
      if !matches_branch(branch_id, branch); continue; end
      if ix_ele != -1
        push!(eles, ele_at_index(branch, ix_ele+offset, wrap = false))
        continue
      end

      ix_match = 0
      for ele in branch.ele
        if julia_regex
          if match(ele_id, ele.who); push!(eles, ele); end
        else
          if !isnothing(key) && Symbol(typeof(ele)) != key; continue; end
          if !str_match(ele_id, ele.name); continue; end
          ix_match += 1
          if nth_match != -1 && ix_match > nth_match; continue; end
          if ix_match == nth_match || nth_match == -1; push!(eles, ele_at_index(branch, offset, ele0=ele)); end
        end
      end
    end   # branch loop

    return eles
  end
end

#---------------------------------------------------------------------------------------------------
# eles

"""
    function eles(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}) -> [ele-array]

Returns a vector of all elements that match `who`.

# 


Returns a vector of all lattice elements that match element `who` which is in the form:
  `{branch_id>>}{key::}ele_id{#N}{+/-offset}`
or
  `{branch_id>>}attribute->match_str{+/-offset}`
where `attribute` is something like `alias`, `description`, `type`, or any custom field.

  key selection EG: "Quadrupole::<list>"
  ranges        EG: "<ele1>:<ele2>"
  negation      EG: "<list1> ~<list2>"
  intersection  EG: "<list1> & <list2>"
Note: negation and intersection evaluated left to right

### Input

- `where_search` `Lat` or `Branch` to search.
- `who` `String` or `Regex` to use in the search.
""" 
function eles(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex})
  # Julia regex is simple
  if typeof(who) == Regex; return eles_base(where_search, who); end

  # Intersection
  list = str_split(who, "~&", limit = 3)
  if length(list) == 2 || list[1] == "~" || list[1] == "&" || 
                            (length(list) == 3 && (list[3] == "~" || list[3] == "&"))
    error(f"ParseError: Cannot parse: {who}")
  end

  eles1 = eles_base(where_search, list[1])
  if length(list) == 1; return eles1; end

  eles2 = eles(lat, list[3])
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
    ele_at_s(branch::Branch, s::Real; choose::StreamLocationSwitch = upstream_end, ele_near::ELE = NULL_ELE) 
                                                                          -> ele_overlap::Ele

Returns lattice element `ele_overlap` that overlaps a given longitudinal s-position. 
That is, `s` will be in the interval `[ele_overlap.s, ele_overlap.s_downstream]`.

## Input

 - `branch`     Lattice `Branch` to search.
 - `s`          Longitudinal position to match to.
 - `choose`     If there is a choice of elements, which can happen if `s` corresponds to a boundary
                point between two elements, `choose` is used to pick either the `upstream_end` 
                element (default) or `downstream_end` element.
 - `ele_near`   If there are elements with negative drift lengths (generally this will be a
                `drift` or `patch` element), there might be multiple solutions. If `ele_near`
                is specified, this routine will choose the solution nearest `ele_near`.

## Returns

 - `ele_overlap` Element that overlaps the given `s` position.

""" ele_at_s

function ele_at_s(branch::Branch, s::Real; choose::StreamLocationSwitch = upstream_end, ele_near::Ele = NULL_ELE)
  check_if_s_in_branch_range(branch, s)
  if choose != upstream_end && choose != downstream_end; error("Bad `choose` argument: $choose"); end 

  # If ele_near is not set
  if is_null(ele_near)
    n1 = 1
    n3 = branch.ele[end].ix_ele

    while true
      if n3 == n1 + 1; break; end
      n2 = div(n1 + n3, 2)
      s < branch.ele[n2].s || (choose == upstream_end && branch.ele[n2].s == s) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if choose == downstream_end && branch.ele[n3].s == s
      return branch.ele[n3]
    else
      return branch.ele[n1]
    end
  end

  # If ele_near is used
  ele = ele_near
  if ele.branch.type <: LordBranch
    choose == downstream_end ? ele = ele.slaves[end] : ele = ele.slaves[1]
  end


  if s > ele.s_downstream || (choose == downstream_end && s == ele.s_downstream)
    while true
      ele = next_ele(ele)
      if s < ele.s_downstream || (s == ele.s_downstream && choose == upstream_end); return ele; end
    end

  else
    while true
      if s > ele.s || (choose == downstream_end && ele.s == s); return ele; end
      ele = next_ele(ele, -1)
    end
  end
end
