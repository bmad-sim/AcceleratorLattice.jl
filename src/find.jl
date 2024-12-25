#---------------------------------------------------------------------------------------------------
# ele_at_offset

"""
    ele_at_offset(reference::Union{Ele,Branch}, offset::Int, wrap)  -> ele::Ele
    ele_at_offset(reference::Union{Ele,Branch}, offset::Int; wrap::Bool = true)  -> ele::Ele

If `reference` is a `Branch`, this routine returns the element whose index is equal to `offset`.

If `reference` is an `Ele`, this routine returns the element with index equal to `reference.ix_ele + offset`
in the branch containing `reference`. Exceptions: 
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
      if branch.type == SuperBranch
        offset > 0 ? ref = reference.slaves[end] : ref = reference.slaves[1]
        branch = ref.branch
        indx = ref.ix_ele + offset

      elseif branch.type == MultipassBranch
        slaves = [ele_at_offset(slave, offset, wrap) for slave in reference.slaves]
        for slave in slaves
          if !(get(slave, :multipass_lord, NULL_ELE) === get(slaves[1], :multipass_lord, nothing))
            error("Cannot find multipass_lord at offset ($offset) from element ($(ele_name(reference))).")
          end
        end
        return slave.multipass_lord

      elseif branch.type == GirderBranch
        error("Not yet implemented!!")
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
    Internal: function eles_atomic(where_search, who, branch_id, ele_type, param_id, match_str, 
                                        nth_instance, offset, wrap)  -> ele_vector::Ele[]

Internal function. Called by the `eles_group` function which in turn is called by `eles`.
""" eles_atomic

function eles_atomic(where_search, who, branch_id, ele_type, param_id, match_str, nth_instance, offset, wrap)

  eles = Ele[]
  ix_ele = integer(match_str, -1)
  julia_regex = (typeof(who) == Regex)

  if typeof(where_search) == Lattice
    branch_vec = where_search.branch
  else
    branch_vec = collect(where_search)
  end

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
      if !julia_regex && branch_id == "" && branch.type == SuperBranch; continue; end

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
              if !isnothing(ele_type) && Symbol(typeof(lord)) != ele_type; continue; end
              if !str_match(match_str, getproperty(lord, param_id)); continue; end
              ix_match += 1
              if nth_instance != -1 && ix_match > nth_instance; continue; end
              if ix_match == nth_instance || nth_instance == -1; push!(eles, ele_at_offset(lord, offset, wrap)); end
            end
          end

          if !isnothing(ele_type) && Symbol(typeof(ele)) != ele_type; continue; end
          if !str_match(match_str, getproperty(ele, param_id)); continue; end
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
# eles_group

"""
    Internal: function eles_group(where_search, who::Union{AbstractString,Regex}; 
                                                               wrap::Bool = true)  -> ele_vector::Ele[]

Internal function. Called by `eles` function.
`who` is a "group" search string. See the documentation in `eles` for more details.
""" eles_group

function eles_group(where_search::Union{Lattice,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
  julia_regex = (typeof(who) == Regex)

  ele_type = nothing
  branch_id = ""
  param_id = :name
  match_str = ""
  offset = 0
  nth_instance = -1

  # Regex case

  if julia_regex
    match_str = who
    return eles_atomic(where_search, who, branch_id, nothing, param_id, match_str, nth_instance, offset, wrap) 
  end

  # Parse `who`

  this_who = replace(who, "'" => "\'")
  chunks = str_split(this_who, [">>", "::", ":", "#", "+", "-", "=", "`", " "])

  if length(chunks) > 2 && chunks[2] == "::"
    ele_type = Symbol(chunks[1])
    if ele_type ∉ Symbol.(subtypes(Ele)); error("Element type not recognized: $ele_type"); end
    chunks = chunks[3:end]
  end

  if length(chunks) > 2 && chunks[2] == ">>"
    branch_id = chunks[1]
    chunks = chunks[3:end]
  end

  if length(chunks) > 4 && chunks[2] == "="
    if chunks[3] != "`" || chunks[5] != "`" error("Malformed back ticks in element match string: $who"); end
    param_id = Symbol(chunks[1])
    match_str = chunks[4]
    chunks = chunks[6:end]
  else
    match_str = chunks[1]
    chunks = chunks[2:end]
  end

  if length(chunks) > 0 && chunks[1] == "#"
    if length(chunks) == 1; error("Malformed `#` character in element match string: $who"); end
    nth_instance = integer(chunks[2])
    chunks = chunks[3:end]
  end

  if length(chunks) > 0 && (chunks[1] == "-" || chunks[1] == "+")
    if length(chunks) == 1; error("Malformed `-` or `+` character in element match string: $who"); end
    offset = integer(chunks[1] * chunks[2])
    chunks = chunks[3:end]
  end

  # Non-range construct

  if length(chunks) == 0
   return eles_atomic(where_search, who, branch_id, ele_type, param_id, match_str, nth_instance, offset, wrap) 
  end

  # Range construct
  # Note: ele_type not used in search for range end points.

  ele_vec = eles_atomic(where_search, who, branch_id, nothing, param_id, match_str, nth_instance, offset, wrap) 

  if chunks[1] != ":"; error("Malformed group: $who"); end
  if length(ele_vec) == 0; error("First element in range construct does not match anything in the lattice: $who"); end
  if length(ele_vec) > 1; error("First element in range construct matches multiple elements: $who"); end

  param_id = :name
  match_str = ""
  offset = 0
  nth_instance = -1

  if length(chunks) > 4 && chunks[2] == "="
    if chunks[3] != "`" || chunks[5] != "`" error("Malformed back ticks in element match string: $who"); end
    param_id = Symbol(chunks[1])
    match_str = chunks[4]
    chunks = chunks[6:end]
  else
    match_str = chunks[1]
    chunks = chunks[2:end]
  end

  if length(chunks) > 0 && chunks[1] == "#"
    if length(chunks) == 1; error("Malformed `#` character in element match string: $who"); end
    nth_instance = integer(chunks[2])
    chunks = chunks[3:end]
  end

  if length(chunks) > 0 && (chunks[1] == "-" || chunks[1] == "+")
    if length(chunks) == 1; error("Malformed `-` or `+` character in element match string: $who"); end
    offset = integer(chunks[1] * chunks[2])
    chunks = chunks[3:end]
  end

  if length(chunks) > 0; error("Extra stuff in group construct: $who"); end

  ele_vec2 = eles_atomic(where_search, who, branch_id, nothing, param_id, match_str, nth_instance, offset, wrap) 
  if length(ele_vec2) == 0; error("Second element in range construct does not match anything in the lattice: $who"); end
  if length(ele_vec2) > 1; error("Second element in range construct matches multiple elements: $who"); end

  ele1 = ele_vec[1]
  if ele1.lord_status == Lord.SUPER; ele1 = ele1.slaves[1]; end

  ele2 = ele_vec2[1]
  if ele2.lord_status == Lord.SUPER; ele2 = ele2.slaves[end]; end

  branch = ele1.branch
  if !(ele2.branch === branch); error("Elements in range construct are not in the same branch: $who"); end

  if ele1.ix_ele <= ele2.ix_ele
    ele_vec = branch.ele[ele1.ix_ele:ele2.ix_ele]
  elseif wrap
    ele_vec = convert(Vector{Ele}, append!(copy(branch.ele[ele1.ix_ele:end]), branch.ele[1:ele2.ix_ele]))
  else
    return Ele[]
  end

  if isnothing(ele_type)
    return ele_vec
  else
    return ele_vec[typeof(ele_vec) .== ele_type] 
  end

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

AL regex expressions are built up from "atomic" expressions which are of the form:
```
 {branch_id>>}ele_id{#N}{+/-offset}
```
Curly brackets `{...}` denote optional fields.
- `branch_id`   Optional lattice branch index or name. Alternative is to specify the branch
  using the `where_search` argument. A branch is searched if it matches both `where_search`
  and `branch_id`. 
- `ele_id`      Element name (which can contain wild card characters), index, or 
  `parameter='match_str'` construct.
- `#N`          If present, return only the Nth instance matched to.
- `+/-offset`   If present, return element(s) whose index is offset from the elements matched to.



A `group` is either an `atom` with an optional `type` prefix or a `"range"` construct:
```
  {ele_type::}atom           # or
  {ele_type::}atom1:atom2    # Range construct

```

- `ele_type`   Optional element type (EG: `Quadrupole`, `Drift`, etc.).


With the range construct, `atom1` and `atom2` must both evaluate to a single element in the
same branch 
All elements between `atom1` and

- With a range, if `atom1` is a `super_lord` element, For evaluating the range, the first slave of
  the `super_lord` will be used for the boundary element of the range. 
  If `atom2` is a `super_lord` element,
  the last slave of the `super_lord` will be used for the boundary element of the range.
- To exclude the boundary elements from the returned list, use the appropriate `offset`.
- In a range construct the `ele_type` is used to remove elements from the returned list but
  do not affect matching to the elements at the ends of the range. That is, the elements
  at the range ends do not have to be of type `ele_type`.

Group expressions may be combined using the operators `","` (union), `"~"` (negation) or `"&"` (intersection):
If there are more than two group expressions involved, evaluation is left to right. For example:
```
  "<group1>, <group2>"              # Union of <group1> and <group2>.
  "<group1>, <group2> & <group3>"   # Intersection of <group3> with the union of <group1> and <group2>.
  "<group1> ~<group2>"              # All elements in <group1> that are not in <group2>.
```

## Notes

- The `parameter='match_str'` construct allows for matching to element parameters other than the element name. 
  Typically used with the standard element "string parameters" `ID`, `type`, and `class`
  but matching is not limited to these parameters.
- If `ele_id` is an integer (element index), Specifying `#N` is not permitted.
- To exclude matches to super slave elements, use `"~*!s"` at the end of an expression.

## Examples
```
  eles(lat, "r>>d")             # All elements named "d" in the branch with name "r".
  eles(lat, "Marker::*")        # All Marker elements
  eles(lat, "Marker::%5-1")     # All elements just before Marker elements with two character names
                                #   ending in the digit "5"
  eles(lat, "1>>m1#2")          # Second element named "m1" in branch 1.
  eles(lat.branch[1], "m1#2")   # Equivalent to eles(lat, "1>>m1#2").
  eles(lat, "ID=`abc`")
```

Note: The index operator `[...]` is overloaded so that `branch[who]` where `branch` is a `Branch` 
instance, or `lat[who]` where `lat` is a
`Lattice` instance is the same as `eles(branch, who)` and `eles(lat, who)` respectively.
""" 
function eles(where_search::Union{Lattice,Branch}, who::Union{AbstractString,Regex}; wrap::Bool = true)
  # Julia regex is simple
  if typeof(who) == Regex; return eles_group(where_search, who); end

  # Not Julia regex
  list = str_split(who, "~&,")

  eles1 = eles_group(where_search, list[1])
  list = list[2:end]

  while true
    if length(list) == 0; return eles1; end
    if length(list) == 1; error("Bad `who` argument: $who"); end

    eles2 = eles(where_search, list[2], wrap = wrap)

    if list[1] == "&"
      ele_list = Ele[]
      for ele1 in eles1
        if ele1 in eles2; push!(ele_list, ele1); continue; end
      end
      eles1 = ele_list

    elseif list[1] == "~"
      ele_list = Ele[]
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

  return list
end

#---------------------------------------------------------------------------------------------------
# lat_branch

"""
    lat_branch(lat::Lattice, ix::Int)
    lat_branch(lat::Lattice, who::AbstractString) 
    lat_branch(lat::Lattice, who::T) where T <: BranchType
    lat_branch(ele::Lattice)

With `lat` as first argument: Returns the branch in `lat` with index `ix` or name that matches `who`.
With `ele` as first argumnet: Returns the branch `ele` is in.
Returns `nothing` if no branch can be matched.
""" lat_branch

function lat_branch(lat::Lattice, ix::Int) 
  if ix < 1 || ix > length(lat.branch); error(f"Branch index {ix} out of bounds."); end
  return lat.branch[ix]
end

function lat_branch(lat::Lattice, who::AbstractString) 
  for branch in lat.branch
    if branch.name == who; return branch; end
  end
  error(f"Cannot find branch with name {name} in lattice.")
end

function lat_branch(lat::Lattice, who::Type{T}) where T <: BranchType
  for branch in lat.branch
    if branch.pdict[:type] == who; return branch; end
  end
  error(f"Cannot find branch with type {name} in lattice.")  
end

function lat_branch(ele::Ele)
  if haskey(ele.pdict, :branch); return ele.pdict[:branch]; end
  return
end

#---------------------------------------------------------------------------------------------------
# lattice

"""
    lattice(ele::Ele) -> Union{Lattice, Nothing}

Returns the lattice that an element is contained in or `nothing` if there is no containing lattice.
"""
function lattice(ele::Ele)
  branch = lat_branch(ele)
  if isnothing(branch); return nothing; end
  return branch.lat
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
