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
- If the `reference` is a super lord element the index of the returned element is `N + offset` where, 
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
    Internal: eles_atomic(where_search, who, branch_id, ele_type, param_id, 
                                                  match_str, wrap)  -> ele_vector::Ele[]

Internal function. Find all elements that match an "atomic" construct.
Called by the `eles_search_a_block` function which in turn is called by `eles_search`.
""" eles_atomic

function eles_atomic(where_search, who, branch_id, ele_type, param_id, match_str, wrap)

  # Parse out offset

  chunks = str_split(match_str, ["+", "-"])
  offset = 0

  if length(chunks) > 1
    if length(chunks) != 3; error("Malformed element ID: $who"); end
    match_str = chunks[1]
    offset = integer(chunks[2] * chunks[3])
  end

  # What branches to search?

  ele_list = Ele[]
  ix_ele = integer(match_str, -1)

  if typeof(where_search) == Lattice
    lat = where_search
    if ix_ele != -1 && branch_id == ""
      branch_vec = [lat.branch[1]]
    else
      branch_vec = lat.branch
    end

  else
    branch_vec = collect(where_search)
  end

  # Search for element

  for branch in branch_vec
    if !matches_branch(branch_id, branch); continue; end

    if ix_ele != -1 && param_id == :name
      if ix_ele > length(branch.ele); error("Element index above branch.ele[] range: $(who)"); end
      push!(ele_list, ele_at_offset(branch.ele[ix_ele], offset, wrap))
    else
      for ele in branch.ele
        if !isnothing(ele_type) && Symbol(typeof(ele)) != ele_type; continue; end
        if !str_match(match_str, getproperty(ele, param_id)); continue; end
        push!(ele_list, ele_at_offset(ele, offset, wrap))
      end
    end
  end

  return ele_list
end

#---------------------------------------------------------------------------------------------------
# eles_search_a_block

"""
  Internal: eles_search_a_block(where_search::Union{Lattice,Branch}, 
                                            who::Union{AbstractString,Regex}; wrap::Bool = true)

Internal routine called by `eles` to search for matches to a string that represents a single "block".
A string representing a single block is a string that does not contain, ",", "&", nor "~".
See the `eles` documentation for details.
Returned is a list that is naturally sorted by index.
""" eles_search_a_block

function eles_search_a_block(where_search::Union{Lattice,Branch}, who::Union{AbstractString,Regex},
                                                                              wrap::Bool = true)
  # Julia regex is simple
  if typeof(who) == Regex; return eles_search_a_block(where_search, who); end

  # Not Julia regex
  ele_type = nothing
  branch_id = ""       # Branch ID used with "branch_id>>ele_id" construct
  param_id = :name
  match_str = ""

  # Parse `who`. Will accept constructs of the form "branch>>type::name" or "type::branch>>name"

  this_who = replace(who, "'" => "\'")
  chunks = str_split(this_who, [">>", "::", ":", "=", "`", " "])

  if length(chunks) > 2 && chunks[2] == "::"
    ele_type = chunks[1]
    chunks = chunks[3:end]
  end

  if length(chunks) > 2 && chunks[2] == ">>"
    branch_id = chunks[1]
    chunks = chunks[3:end]
  end

  if length(chunks) > 2 && chunks[2] == "::"   # Need this test for "branch>>type::name" construct
    ele_type = chunks[1]
    chunks = chunks[3:end]
  end

  if !isnothing(ele_type)
    ele_type = Symbol(ele_type)
    if ele_type ∉ Symbol.(subtypes(Ele)); error("Element type not recognized: $ele_type"); end
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

  # Non-range construct

  if length(chunks) == 0
    return eles_atomic(where_search, who, branch_id, ele_type, param_id, match_str, wrap) 
  end

  # Range construct
  # Note: ele_type not used in search for range end points.

  ele_vec = eles_atomic(where_search, who, branch_id, nothing, param_id, match_str, wrap) 

  if chunks[1] != ":"; error("Malformed construct: $who"); end
  if length(ele_vec) == 0; error("First element in range construct does not match anything in the lattice: $who"); end
  if length(ele_vec) > 1; error("First element in range construct matches multiple elements: $who"); end

  param_id = :name
  match_str = ""

  if length(chunks) > 5 && chunks[3] == "="
    if chunks[4] != "`" || chunks[6] != "`" error("Malformed back ticks in element match string: $who"); end
    param_id = Symbol(chunks[2])
    match_str = chunks[5]
    chunks = chunks[7:end]
  else
    match_str = chunks[2]
    chunks = chunks[3:end]
  end

  if length(chunks) > 0; error("Extra stuff in search string: $who"); end

  ele_vec2 = eles_atomic(where_search, who, branch_id, nothing, param_id, match_str, wrap) 
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
    return ele_vec[Symbol.(typeof.(ele_vec)) .== ele_type] 
  end
end

#---------------------------------------------------------------------------------------------------
# eles_search

"""
    eles_search(where_search, who::Union{AbstractString,Regex}; order::Order.T = Order.NONE, 
             substitute_lords = false, wrap::Bool = true, scalar = false) -> Union{Ele[], Ele, Nothing}

Returns a vector of all elements that match `who`.
If the last character of 

## Arguments
- `where_search`  Where to search. Either a lattice (all branches searched), lattice branch, or 
  vector of lattice branches.
- `who`           The string to match elements to. 
  Either a Julia `Regex` expression to match to element names or a string with matching 
  governed by the "AcceleratorLattice" (AL) regex syntax (see below).
- `order`         If `Order.BY_INDEX`, ordering of the output vector is by branch and ele index.
  If `Order.BY_S`, order by s-position with super and multipass lords interspersed with tracking elements.
- `substitute_lords` If `true`, for every matched element that is a slave, remove the slave and
  add to the output list the slave's super or multipass lords.
- `wrap`          Used if there is an `offset` specified in the search string (see below).
- `scalar`        If `false`, return vector of elements (which may have zero length), 
  If `true`, return a single element if `who` matches to a single element or otherwise return `nothing`.
  As a shortcut, if the last character of `who` is a `#` character, remove this character and set
  `scalar` to `true`.

## AL Regex

The "AcceleratorLattice" (AL) regex syntax has wild card characters `“*”` and `“%”`.
The `“*”` character will match any number of characters (including zero) while 
`“%”` maches to any single character. 

AL regex expressions are built up from "blocks" which are of the form:
```
 {branch_id>>}ele_id{+/-offset}
```
Curly brackets `{...}` denote optional fields.
- `branch_id`   Optional lattice branch index or name. Alternative is to specify the branch
  using the `where_search` argument. A branch is searched if it matches both `where_search`
  and `branch_id`. If `ele_id` is an integer and `branch_id` is not present, branch 1 is
  is used.
- `ele_id`      Element name. See below.
- `+/-offset`   If present, return element(s) whose index is offset from the elements matched to.

A `ele_id` is of the form:
```
  {ele_type::}atom           # or
  {ele_type::}atom1:atom2    # range construct

```
where `ele_type` is an optional element type (EG: `Quadrupole`, `Drift`, etc.) and `atom`
is an element name (which can contain wild card characters), index, or
`parameter='match_str'` construct. Here `parameter` is the name of any string component of
an element. Standard string components are
• `type`     Example: `type = 'abc'` \\
• `class`    Example: `class = 'abc'` \\
• `ID`       Example: `ID = 'abc'` \\
Notice that here strings to be matched to use single quotes.

With the range construct, `atom1` and `atom2` must both evaluate to a single element in the
same branch.

- With a range, if `atom1` is a super lord element, For evaluating the range, the first slave of
  the super lord will be used for the boundary element of the range. 
  If `atom2` is a super lord element,
  the last slave of the super lord will be used for the boundary element of the range.
- To exclude the boundary elements from the returned list, use the appropriate `offset`.
- In a range construct the `ele_type` is used to remove elements from the returned list but
  do not affect matching to the elements at the ends of the range. That is, the elements
  at the range ends do not have to be of type `ele_type`.

Params expressions may be combined using the operators `","` (union), `"~"` (negation) or `"&"` (intersection):
If there are more than two block expressions involved, evaluation is left to right. For example:
```
  "<block1>, <block2>"              # Union of <block1> and <block2>.
  "<block1>, <block2> & <block3>"   # Intersection of <block3> with the union of <block1> and <block2>.
  "<block1> ~<block2>"              # All elements in <block1> that are not in <block2>.
```

## Notes

- The `parameter='match_str'` construct allows for matching to element parameters other than the element name. 
  Typically used with the standard element "string parameters" `ID`, `type`, and `class`
  but matching is not limited to these parameters.
- To exclude matches to super slave elements, use `"~*!s"` at the end of an expression.
- The returned list will not have duplications. That is, a given element will not show up in multiple places. 

## Examples
```
  eles_search(lat, "r>>d")             # All elements named "d" in the branch with name "r".
  eles_search(lat, "Bend::* ~*!*")     # All Bend elements which are not multipass nor super slaves.
                                       #   This works since all slaves have a "!" in their name.
  eles_search(lat, "Marker::%5-1")     # All elements just before Marker elements with two character names
                                       #   ending in the digit "5".
  eles_search(lat.branch[SuperBranch], "ID=`abc`")  # All super lord elements with ID string equal to "abc".
  eles_search(lat, "1>>Patch::4:10")   # All Patch elements in branch 1 between elements 4 through 10.
  eles_search(lat, "Patch::1>>4:10")   # Same as above
  eles_search(lat, "Qa+1:Qb+2")        # All elements between the element after "Qa" through the
                                       #   element that is second after "Qb",
  eles_search(lat, "34")               # Element with index 34 in branch 1. Notice that if the 
                                       #    ele ID is not an integer, all branches are searched.
```

Note: The index operator `[...]` is overloaded so that `branch[who]` where `branch` is a `Branch` 
instance, or `lat[who]` where `lat` is a
`Lattice` instance is the same as `eles_search(branch, who)` and `eles_search(lat, who)` respectively.
""" eles_search

function eles_search(where_search::Union{Lattice,Branch}, who::Union{AbstractString,Regex}; 
          order::Order.T = Order.NONE, substitute_lords = false, wrap::Bool = true, scalar = false)

  # See if end of `who` is a "#" character

  if length(who) > 0 && who[end] == '#'
    who = who[1:end-1]
    scalar = true
  end

  # Break `who` into blocks for searching

  if typeof(who) == Regex
    ele_list = eles_search_a_block(where_search, who, wrap)

  else
    list = str_split(who, "~&,")
    ele_list = eles_search_a_block(where_search, list[1])
    list = list[2:end]

    while true
      if length(list) == 0; break; end
      if length(list) == 1; error("Bad `who` argument: $who"); end

      list2 = eles_search(where_search, list[2], wrap = wrap)

      if list[1] == "&"
        ele_list = intersect(ele_list, list2)

      elseif list[1] == "~"
        ele_list = setdiff(ele_list, list2)

      elseif list[1] == ","
        ele_list = unique(append!(ele_list, list2))

      else
        error("ParseError: Cannot parse: $who")
      end

      list = list[3:end]
    end
  end

  # End stuff

  if substitute_lords; eles_substitute_lords!(ele_list); end

  if scalar
    if length(ele_list) == 1
      return ele_list[1]
    else
      return nothing
    end
  else
    return eles_sort!(ele_list, order = order)
  end
end

#---------------------------------------------------------------------------------------------------
# lat_branch

"""
    lat_branch(lat::Lattice, ix::Int)
    lat_branch(lat::Lattice, who::AbstractString) 
    lat_branch(lat::Lattice, who::T) where T <: BranchType
    lat_branch(ele::Ele)

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

#---------------------------------------------------------------------------------------------------
# lat_ele_dict

"""
    lat_ele_dict(lat::Lattice) -> Dict{String, Vector{Ele}}

Return a dictionary of `ele_name => Vector{Ele}` mapping of lattice element names to arrays of
elements with that name. Using a dictionary for name lookup will be much faster than 
searching using the `eles` function.

## Output

Dict{String, Vector{Ele}} dictionary where the keys are element names and the values are 
vectors of elements of whose name matches the key. The element vectors are ordered by s-position.

## Example
```
eled = lat_ele_dict(lat)    # Create Dictionary
eled["q23w"]                
```
""" lat_ele_dict

function lat_ele_dict(lat::Lattice)
  eled = Dict{String,Vector{Ele}}()

  for branch in lat.branch
    if branch.type == SuperBranch || branch.type == MultipassBranch; continue; end
    for ele in branch.ele
      lat_ele_dict(ele, eled)
    end
  end

  return eled
end

# Internal function used by lat_ele_dict above.

function lat_ele_dict(ele::Ele, eled::Dict)
  if haskey(eled, ele.name)
    eled[ele.name]
    push!(eled[ele.name], ele)
  else
    eled[ele.name] = Vector{Ele}([ele])
  end

  if ele.slave_status == Slave.SUPER
    for lord in ele.super_lords
      lat_ele_dict(lord, eled)
    end
  end

  if ele.slave_status == Slave.MULTIPASS
    lat_ele_dict(ele.multipass_lord, eled)
  end
end

