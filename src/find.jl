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
# eles_atomic

"""
    Internal: function eles_atomic(where_search, who::Union{AbstractString,Regex}; 
                                                               wrap::Bool = true)  -> ele_vector::Ele[]

Internal function. Called by `eles` function.
`who` is an "atomic" search string. See the documentation in `eles` for more details.
""" eles_atomic

function eles_atomic(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
  julia_regex = (typeof(who) == Regex)

  if typeof(where_search) == Lat
    branch_vec = where_search.branch
  else
    branch_vec = collect(where_search)
  end

  branch_id = ""
  ele_type = nothing
  param_id = :name
  match_str = ""
  offset = 0
  nth_instance = -1

  # Parse who

  if julia_regex
    match_str = who

  else
    this_who = replace(who, "'" => "\'")
    chunks = str_split(this_who, [">>", "::", "#", "+", "-", "=", "`", " "])

    if length(chunks) > 2 && chunks[2] == ">>"
      branch_id = chunks[1]
      chunks = chunks[3:end]
    end

    if length(chunks) > 2 && chunks[2] == "::"
      ele_type = Symbol(chunks[1])
      chunks = chunks[3:end]
    end

    if length(chunks) > 4 && chunks[2] == "="
      if chunks[3] != "`" || chunks[5] != "`" error("Malformed match string for reference element(s): $who"); end
      param_id = Symbol(chunks[1])
      match_str = chunks[4]
      chunks = chunks[6:end]
    else
      match_str = chunks[1]
      chunks = chunks[2:end]
    end

    if length(chunks) > 0 && chunks[1] == "#"
      if length(chunks) == 1; error("Malformed match string for reference elements(s): $who"); end
      nth_instance = integer(chunks[2])
      chunks = chunks[3:end]
    end

    if length(chunks) > 0 && (chunks[1] == "-" || chunks[1] == "+")
      if length(chunks) == 1; error("Malformed match string for reference elements(s): $who"); end
      offset = integer(chunks[1] * chunks[2])
      chunks = chunks[3:end]
    end
  end

  # Search for elements

  eles = Ele[]
  ix_ele = integer(match_str, -1)

  if ix_ele != -1 && param_id == :name
    if nth_instance != -1; error("Specifying element index and using `#N` construct not allowed in: $who"); end
    for branch in branch_vec
      if !matches_branch(branch_id, branch); continue; end
      push!(eles, ele_at_offset(branch.ele[ix_ele], offset, wrap))
    end

  # 

  else
    for branch in branch_vec
      if !matches_branch(branch_id, branch); continue; end
      if !julia_regex && branch_id == "" && branch.type == SuperLordBranch; continue; end

      ix_match = 0
      for ele in branch.ele
        if julia_regex
          if match(match_str, ele.name); push!(eles, ele); end
        else
          # Match to super_lord elements in case `#N` construct has been used and the testing order of the 
          # element is important. To not double count, only check lords where ele is the first super_slave.
          if haskey(ele.pdict, :super_lords)
            for lord in ele.pdict[:super_lords]
              if !(lord.slaves[1] === ele); continue; end
              if !haskey(lord.pdict, param_id); continue; end
              if !isnothing(ele_type) && Symbol(typeof(lord)) != ele_type; continue; end
              if !str_match(match_str, lord.pdict[param_id]); continue; end
              ix_match += 1
              if nth_instance != -1 && ix_match > nth_instance; continue; end
              if ix_match == nth_instance || nth_instance == -1; push!(eles, ele_at_offset(lord, offset, wrap)); end
            end
          end

          if !haskey(ele.pdict, param_id); continue; end
          if !isnothing(ele_type) && Symbol(typeof(ele)) != ele_type; continue; end
          if !str_match(match_str, ele.pdict[param_id]); continue; end
          ix_match += 1
          if nth_instance != -1 && ix_match > nth_instance; continue; end
          if ix_match == nth_instance || nth_instance == -1; push!(eles, ele_at_offset(ele, offset, wrap)); end
        end
      end
    end
  end

  return eles
end

#---------------------------------------------------------------------------------------------------
# eles

"""
    function eles(where_search, who::Union{AbstractString,Regex}; wrap::Bool = True) -> Ele[]

Returns a vector of all elements that match `who`. 

## Arguments
- `where_search`  Where to search. Either a lattice (all branches searched), lattice branch, or 
  vector of lattice branches.
- `who`           The string to match elements to. 
  Either a Julia `Regex` expression to match to element names or a string with matching 
  governed by the "AcceleratorLattice" (AL) regex syntax (see below).
- `wrap`          Used if there is an `offset` specified in the search string (see below).

## AL Regex

The "AcceleratorLattice" (AL) regex syntax has wild card characters `“*”` and `“%”`.
The `“*”` character will match any number of characters (including zero) while 
`“%”` maches to any single character. 

All AL regex expressions are built up from "atomic" expressions of
the form:
```
  {branch_id>>}{ele_class::}ele_id{#N}{+/-offset}
```
Curly brackets `{...}` denote optional fields.
- `branch_id`   Optional lattice branch index or name. Alternative is to specify the branch
  using the `where_search` argument. A branch is searched if it matches both `where_search`
  and `branch_id`. 
- `ele_class`   Optional element class (EG: `Quadrupole`).
- `ele_id`      Element name, index, or `parameter='match_str'` construct. 
  The element name can contain wild card characters.
- `#N`          If present, return only the Nth instance matched to.
- `+/-offset`   If present, return element(s) whose index is offset from the elements matched to.

Atomic expressions may be combined using the operators `","` (union), `"~"` (negation) or `"&"` (intersection):
If there are more than two atomic expressions involved, evaluation is left to right. For example:
```
  "<atom1>, <atom2>"              # Union of <atom1> and <atom2>.
  "<atom1>, <atom2> & <atom3>"    # Intersection of <atom3> with the union of <atom1> and <atom2>.
  "<atom1> ~<atom2>"              # All elements in <atom1> that are not in <atom2>.
```

## Notes

- The `parameter='match_str'` construct allows for matching to element parameters other than the element name. 
  Typically used with the standard element "string parameters" `alias`, `type`, and `description`
  but matching is not limited to these parameters.
- If `ele_id` is an integer (element index), Specifying `#N` is not permitted.

## Examples
```
  eles(lat, "r>>d")             # All elements named "d" in the branch with name "r".
  eles(lat, "Marker::*")        # All Marker elements
  eles(lat, "Marker::%5-1")     # All elements just before Marker elements with two character names
                                #   ending in the digit "5"
  eles(lat, "1>>m1#2")          # Second element named "m1" in branch 1.
  eles(lat.branch[1], "m1#2")   # Equivalent to eles(lat, "1>>m1#2").
  eles(lat, "alias=`abc`")
```
""" 
function eles(where_search::Union{Lat,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
  # Julia regex is simple
  if typeof(who) == Regex; return eles_atomic(where_search, who); end

  # Not Julia regex
  list = str_split(who, "~&,")

  eles1 = eles_atomic(where_search, list[1])
  list = list[2:end]

  while true
    if length(list) == 0; return eles1; end
    if length(list) == 1; error("Bad `who` argument: $who"); end

    eles2 = eles(where_search, list[2], wrap = wrap)

    if list[1] == "&"
      ele_list = []
      for ele1 in eles1
        if ele1 in eles2; push!(ele_list, ele1); continue; end
      end
      eles1 = ele_list

    elseif list[1] == "~"
      ele_list = []
      for ele1 in eles1
        if ele1 ∉ eles2; push!(ele_list, ele1); continue; end
      end
      eles1 = ele_list

    elseif list[1] == ","
      eles1 = append!(eles1, eles2)

    else
      error("ParseError: Cannot parse: $who")
    end

    list = list[3:end]
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
