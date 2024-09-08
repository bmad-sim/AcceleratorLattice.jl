#---------------------------------------------------------------------------------------------------
# ele_at_offset

"""
    ele_at_offset(reference::Union{Ele,Branch}, offset::Int, wrap)  -> ele::Ele
    ele_at_offset(reference::Union{Ele,Branch}, offset::Int; wrap::Bool = true)  -> ele::Ele

If `reference` is a `Branch`, this routine returns the element whose index is equal to `offset`.

If `reference` is an `Ele`, this routine returns the element with index equal to `reference.ix_ele + offset`
in the branch containing `reference`. Exceptions: 
- A non-zero `offset` is not legal for `Governor` elements.
- If the `reference` is a `multipass_lord`, return the `multipass_lord` whose slaves are all
  `offset` away from the corresponding slaves of `reference`. If no such `mulitpass_lord` exists,
  throw an error.
- If the `reference` is a `super_lord` element the index of the returned element is `N + offset` where, 
  if `offset` is positive, `N` is the index of the last (that is, downstream) `super_slave` element and,
  if `index` is negative, `N` is the index of the first (that is, upstream) `super_slave` element.

With `wrap` = `false`, an error is raised if the element index is not in the range `[1, end]` where
`end` is the index of the last element in `branch.ele[]` array.

With `wrap` = `true`, if the  element index is out-of-bounds, the index will be "wrapped around" 
the ends of the branch so, for example, for a branch with `N` elements,
`index = N+1` will return `branch.ele[1]` and `index = 0` will return `branch.ele[N]`.
""" ele_at_offset

function ele_at_offset(reference::Union{Ele,Branch}, offset::Int, wrap::Bool)

  if typeof(reference) == Branch
    branch = reference
    indx = offset

  else
    branch = reference.branch
    indx = reference.ix_ele + offset

    if offset != 0
      if branch.type == GovernorBranch
        error("Non-zero offset ($offset) not allowed for Governor reference elements ($reference.name).")

      elseif branch.type == SuperLordBranch
        offset > 0 ? ref = reference.slaves[end] : ref = reference.slaves[1]
        branch = ref.branch
        indx = ref.ix_ele + offset

      elseif branch.type == MultipassLordBranch
        slaves = [ele_at_offset(slave, offset, wrap) for slave in reference.slaves]
        for slave in slaves
          if !(get(slave, :multipass_lord, NULL_ELE) === get(slaves[1], :multipass_lord, nothing))
            error("Cannot find multipass_lord at offset ($offset) from element ($(ele_name(reference))).")
          end
        end
        return slave.multipass_lord
      end
    end
  end

  !

  n = length(branch.ele)

  if wrap
    if n == 0; error("BoundsError: " *           # Happens with lord branch with no lord elements
              "Element index: $indx out of range in branch $(branch.ix_branch): $(branch.name)"); end
    indx = mod(indx-1, n) + 1
    return branch.ele[indx]
  else
    if indx < 1 || indx > n; error(f"BoundsError: " * 
              "Element index: $indx out of range in branch $(branch.ix_branch): $(branch.name)"); end
    return branch.ele[indx]
  end
end

#

function ele_at_offset(reference::Union{Ele,Branch}, offset::Int; wrap::Bool = true)
  return ele_at_offset(reference, offset, wrap)
end

#---------------------------------------------------------------------------------------------------
# eles_base

"""
    Internal: function eles_base(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; 
                                                               wrap::Bool = true)  -> ele_vector::Ele[]

Internal. Called by `eles` function.
""" eles_base

function eles_base(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
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
          if occursin(pattern, ele.pdict[attrib]); push!(eles, ele_at_offset(ele, offset, wrap)); end
        else
          if str_match(pattern, ele.pdict[attrib]); push!(eles, ele_at_offset(ele, offset, wrap)); end
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
        push!(eles, ele_at_offset(branch, branch.ele[ix_ele], offset, wrap))
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
          if ix_match == nth_match || nth_match == -1; push!(eles, ele_at_offset(ele, offset, wrap)); end
        end
      end
    end   # branch loop

    return eles
  end
end

#---------------------------------------------------------------------------------------------------
# eles

"""
    function eles(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = True)
                                                                                        -> ele_vector::Ele[]

Returns a vector of all elements that match `who`. 

There are two types of `who`.
On type uses a Julia `Regex` expression to match to element names. For example:
```
  who = r"q\\d"     # Matches "qN" where "N" is a digit 0-9.
```
See the Julia regex documentation for more information.

The other types of matches are those using the "AcceleratorLattice" (AL) regex syntax.
This syntax has wild card characters “*” and “%”.
The “*” character will match any number of characters (including zero) while “%” maches to any single character. 

All AL regex expressions are built up from "atomic" expressions. Atomic expressions are of
one of two forms: One atomic form is:
```
  {branch_id>>}{ele_class::}ele_id{#N}{+/-offset}`
```
Curly brackets `{...}` denote optional fields.
- `branch_id`   Optional lattice branch index or name. Alternative is to specify the branch
  using the `where_search` argument.
- `ele_class`   Optional element class (EG: `Quadrupole`).
- `ele_id`      Element name with or element index. The element name can contain wild card characters.
- `#N`          If present, return only the Nth instance matched to.
- `+/-offset`   If present, return element(s) whose index is offset from the elements matched to.

Examples:
```
  eles(lat, "d")                All elements named "d"
  eles(lat, "Marker::*")
  eles(lat, "Marker::*-1")
  eles(lat, "m1#2")
  eles(lat, "m1#2+1")
```


or
  `{branch_id>>}attribute->'match_str'{+/-offset}`
where `attribute` is something like `alias`, `description`, `type`, or any custom field.

  key selection EG: "Quadrupole::<list>"
  ranges        EG: "<ele1>:<ele2>"
  negation      EG: "<list1> ~<list2>"
  intersection  EG: "<list1> & <list2>"
Note: negation and intersection evaluated left to right

## Input

- `where_search` `Lat` or `Branch` to search.
- `who` `String` or `Regex` to use in the search.

## Notes:

- Element order is not guaranteed. Use
""" 
function eles(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
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
    ele_at_s(branch::Branch, s::Real; select::Select.T = Select.UPSTREAM, ele_near::ELE = NULL_ELE) 
                                                                          -> ele_overlap::Ele

Returns lattice element `ele_overlap` that overlaps a given longitudinal s-position. 
That is, `s` will be in the interval `[ele_overlap.s, ele_overlap.s_downstream]`.

## Input

 - `branch`     Lattice `Branch` to search.
 - `s`          Longitudinal position to match to.
 - `select`     If there is a choice of elements, which can happen if `s` corresponds to a boundary
                point between two elements, `select` is used to pick either the `Select.UPSTREAM` 
                element (default) or `Select.DOWNSTREAM` element.
 - `ele_near`   If there are elements with negative drift lengths (generally this will be a
                `drift` or `patch` element), there might be multiple solutions. If `ele_near`
                is specified, this routine will choose the solution nearest `ele_near`.

## Returns

 - `ele_overlap` Element that overlaps the given `s` position.

""" ele_at_s

function ele_at_s(branch::Branch, s::Real; select::Select.T = Select.UPSTREAM, ele_near::Ele = NULL_ELE)
  check_if_s_in_branch_range(branch, s)
  if select != Select.UPSTREAM && select != Select.DOWNSTREAM; error("Bad `select` argument: $select"); end 

  # If ele_near is not set
  if is_null(ele_near)
    n1 = 1
    n3 = branch.ele[end].ix_ele

    while true
      if n3 == n1 + 1; break; end
      n2 = div(n1 + n3, 2)
      s < branch.ele[n2].s || (select == Select.UPSTREAM && branch.ele[n2].s == s) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if select == Select.DOWNSTREAM && branch.ele[n3].s == s
      return branch.ele[n3]
    else
      return branch.ele[n1]
    end
  end

  # If ele_near is used
  ele = ele_near
  if ele.branch.type <: LordBranch
    select == Select.DOWNSTREAM ? ele = ele.slaves[end] : ele = ele.slaves[1]
  end


  if s > ele.s_downstream || (select == Select.DOWNSTREAM && s == ele.s_downstream)
    while true
      ele = next_ele(ele)
      if s < ele.s_downstream || (s == ele.s_downstream && select == Select.UPSTREAM); return ele; end
    end

  else
    while true
      if s > ele.s || (select == Select.DOWNSTREAM && ele.s == s); return ele; end
      ele = next_ele(ele, -1)
    end
  end
end
