#---------------------------------------------------------------------------------------------------
# Base.copy(lat::Lattice)

"""
    Base.copy(lat::Lattice)

Shallow copy constructer for a lattice. 
""" Base.copy(lat::Lattice)

function Base.copy(lat::Lattice)
  lat_copy = Lattice(lat.name, copy(lat.branch), copy(lat.pdict))
  for ix in 1:length(lat.branch)
    lat_copy.branch[ix] = copy(lat.branch[ix])
    lat_copy.branch[ix].lat => lat_copy
  end
  return lat_copy
end

#---------------------------------------------------------------------------------------------------
# Base.copy(branch::Branch)

"""
    Base.copy(branch::Branch)

Shallow copy constructer for a lattice branch. 
Note: copy will point to the same lattice as the input branch.
""" Base.copy(branch::Branch)

function Base.copy(branch::Branch)
  branch_copy = Branch(branch.name, branch.lat, copy(branch.ele), copy(branch.pdict))
  for ix in 1:length(branch.ele)
    branch_copy.ele[ix] = copy(branch.ele[ix])
    branch_copy.ele[ix].branch => branch_copy
  end
  return branch_copy
end

#---------------------------------------------------------------------------------------------------
# Base.copy(ele::Ele)

"""
    Base.copy(ele::Ele)

Shallow copy constructer for a lattice element to the level of `ele.XXX`. 
For all standard element parameter groups this is equivalent to a deep copy.
Custom

""" Base.copy(ele::Ele)

function Base.copy(ele::Ele)
  ele_copy = Ele(ele.name, ele.class, copy(ele.pdict))
  for key in keys(ele.pdict)
    if it_isimmutable(ele.pdict[key]); continue; end
    if key == :branch; continue; end              # Branch pointer
    ele_copy.pdict[key] = copy(ele.pdict[key])
  end
  return ele_copy
end

#---------------------------------------------------------------------------------------------------
# Base.insert!(branch, ix_ele, ele)

""" 
    Base.insert!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true) -> ::Ele
    Base.insert!(lat::Lattice, girder::Girder)

Insert a copy of an element in a lattice. Returned is the inserted element.
For th`ele` at index `ix_ele` in branch `branch` 
All elements with indexes of `ix_ele` and higher are pushed one element down the array.
Returned is the inserted element.

Inserted is a (shallow) copy of `ele` and this copy is returned.

 - `adjust_orientation`  If `true`, and the `branch.type` is a `TrackingBranch`, the orientation 
parameter of `ele` is adjusted to match the neighboring elements.

Also see `set!`, `push!`, and `pop!`
""" Base.insert!(branch::Branch, ix_ele::Int, ele::Ele)

#----------------

function Base.insert!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true)
  ele = copy(ele)
  insert!(branch.ele, ix_ele, ele)
  index_and_s_bookkeeper!(branch, ix_ele)

  if adjust_orientation && branch.type == TrackingBranch && length(branch.ele) > 1
    if ix_ele == 1
      ele.pdict[:LengthParams].orientation = branch.ele[2].orientation
    else
      ele.pdict[:LengthParams].orientation = branch.ele[ele.ix_ele-1].orientation
    end
  end

  set_branch_min_max_changed!(branch, ix_ele)
  ele.pdict[:changed][AllParams] = true
  if ele.class == Fork; fork_bookkeeper(ele); end
  if !isnothing(branch.lat) && branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
  return ele
end

#----------------

function Base.insert!(lat::Lattice, girder::Girder)
  gbranch = lat.branch["girder"]
  push!(gbranch.ele, copy(girder))
  girder = gbranch.ele[end]

  for ele in girder.supported
    if !(lat === lattice(ele)); error("Supported element $(ele.name) in girder $(girder.name) " *
                                      "not associated with lattice girder is to be placed in."); end 
    ele.pdict[:girder] = girder
  end

  return girder
end

#---------------------------------------------------------------------------------------------------
# set!(branch, ix_ele, ele)

""" 
    set!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true) -> ::Ele

Insert an element `ele` at index `ix_ele` in branch `branch`.
Inserted is a (shallow) copy of `ele` and this copy is returned.

 - `adjust_orientation`  If `true`, and the `branch.type` is a `TrackingBranch`, the orientation 
parameter of `ele` is adjusted to match the neighboring elements.

Also see `pop!`, `push!`, and `insert!`
""" set!(branch::Branch, ix_ele::Int, ele::Ele)

function set!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true)
  ele = copy(ele)
  branch.ele[ix_ele] = ele
  index_and_s_bookkeeper!(branch, ix_ele)

  if adjust_orientation && branch.type == TrackingBranch && length(branch.ele) > 1
    if ix_ele == 1
      ele.pdict[:LengthParams].orientation = branch.ele[2].orientation
    else
      ele.pdict[:LengthParams].orientation = branch.ele[ele.ix_ele-1].orientation
    end
  end

  set_branch_min_max_changed!(branch, ix_ele)
  ele.pdict[:changed][AllParams] = true
  if !isnothing(branch.lat) && branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
  return ele
end

#---------------------------------------------------------------------------------------------------
# Base.pop!(branch, ix_ele, ele)

""" 
    Base.pop!(branch::Branch, ix_ele::Int) -> ::Nothing

Remove the element with index `ix_ele` in `branch.ele[]`.

See also `set!`, `push!`, and `insert!`
""" Base.pop!(branch::Branch, ix_ele::Int, ele::Ele)

function Base.pop!(branch::Branch, ix_ele::Int)
  pop!(branch.ele, ix_ele)
  index_and_s_bookkeeper!(branch, ix_ele)

  set_branch_min_max_changed!(branch, ix_ele)
  branch.ele[ix_ele].pdict[:changed][AllParams] = "changed"
  if !isnothing(branch.lat) && branch.lat.autobookkeeping; bookkeeper!(branch.lat); end
  return nothing
end

#---------------------------------------------------------------------------------------------------
# Base.push!(branch, ele)

""" 
    Base.push!(branch::Branch, ele::Ele; adjust_orientation = true) -> ::Ele

Insert an element `ele` at end of branch `branch`.

Inserted is a (shallow) copy of `ele` and this copy is returned.

 - `adjust_orientation`  If `true`, and the `branch.type` is a `TrackingBranch`, the orientation 
parameter of `ele` is adjusted to match the neighboring elements.

No bookkeeping is done by this routine. See also set!, pop!, and insert!
""" Base.push!(branch::Branch)

function Base.push!(branch::Branch, ele::Ele; adjust_orientation = true)
  ele = copy(ele)
  push!(branch.ele, ele)
  ix_ele = length(branch.ele)
  index_and_s_bookkeeper!(branch, ix_ele)

  if adjust_orientation && branch.type == TrackingBranch && ix_ele > 1
    ele.pdict[:LengthParams].orientation = branch.ele[ele.ix_ele-1].orientation
  end

  return ele
end

#---------------------------------------------------------------------------------------------------
# create_unique_ele_names!

"""
    create_unique_ele_names!(lat::Lattice; suffix::AbstractString = "!#")

Modifies a lattice so that all elements have a unique name.

For elements whose names are not unique in lattice `lat`, 
the `suffix` arg is appended to the element name
and an integer is substituted for  the "#" character in the suffix arg starting from `1`
for the first instance, etc. 
If no "#" character exists, a "#" character is appended to the suffix arg.

## Example
```
  create_unique_ele_names!(lat, suffix = "_#x") 
```
In this example, elements that originally have names like `"abc"` would, after the function call,
have names `"abc_1x"`, `"abc_2x"`, etc.
"""
function create_unique_ele_names!(lat::Lattice; suffix::AbstractString = "!#")
  if !occursin("#", suffix); suffix = suffix * "#"; end
  eled = lat_ele_dict(lat)

  for (name, evec) in eled
    if length(evec) == 1; continue; end
    for (ix, ele) in enumerate(evec)
      ele.name = ele.name * replace(suffix, "#" => string(ix))
    end
  end

  return
end

#---------------------------------------------------------------------------------------------------
# split!(branch, s_split)

"""
    split!(branch::Branch, s_split::Real; select::Select.T = Select.UPSTREAM, ele_near::Ele = NULL_ELE)

Routine to split an lattice element of a branch into two to create a branch that has an element
boundary at the point s = `s_split`. 
This routine will not split the lattice if the split would create a "runt" element with length less 
than 2*`LatticeGlobal.significant_length`.

> [!NOTE]
> `split_branch!` will redo the appropriate bookkeeping for lords and slaves and
> a super-lord element will be created if needed (not needed for split drifts).
> For drifts that are split, a drift structure is put in `branch.drift_saved` so that split drifts
> can have their names properly mangled.
> [!NOTE]
> `bookkeeper!` needs to be called after splitting.

### Input
- `branch`            -- Lattice branch
- `s_split`           -- Position at which branch is to be split.
- `select`            -- logical, optional: If no splitting of an element is needed, that is, 
  `s_split` is at an element boundary, there can be multiple possible `ele_split` elements to
  return if there exist zero length elements at the split location. 
  If `select` = `Select.DOWNSTREAM`, the returned `ele_split` element will be chosen to be 
  at the maximal downstream element. If `select` = `Select.UPSTREAM`, the returned `ele_split` element
  will be chosen to be the maximal upstream location. 
  If `s_split` is not at an element boundary, the setting of `select` is immaterial.
- `ele_near`          -- Element near the point to be split. `ele_near` is useful in the case where
  there is a patch with a negative length which can create an ambiguity as to where to do the split
  In this case `ele_near` will remove the ambiguity. Also useful to ensure where to split if there
  are elements with zero length nearby. Ignored equal to `NULL_ELE`.

### Output tuple:
- `ele_split`     -- Element just after the s = `s_split` point.
- `split_done`    -- true if lat was split, false otherwise.
""" split!(branch::Branch)

function split!(branch::Branch, s_split::Real; select::Select.T = Select.UPSTREAM, ele_near::Ele = NULL_ELE)
  check_if_s_in_branch_range(branch, s_split)
  if select != Select.UPSTREAM && select != Select.DOWNSTREAM; error("Bad `select` argument: $select"); end 
  slave1 = ele_at_s(branch, s_split, select = select, ele_near = ele_near)

  # Make sure split does create an element that is less than min_len in length.
  min_len = min_ele_length(branch.lat)
  if select == Select.UPSTREAM && slave1.s > s_split-min_len
    slave1 = ele_at_s(branch, slave1.s, select = Select.DOWNSTREAM)
    s_split = slave1.s_downstream
  elseif select == Select.DOWNSTREAM && slave1.s_downstream < s_split+min_len
    slave1 = ele_at_s(branch, slave1.s_downstream, select = Select.DOWNSTREAM)
    s_split = slave1.s
  end

  # No element split cases where s_split is at an element boundary.

  if s_split == slave1.s; return (slave1, false); end
  if s_split == slave1.s_downstream; return (next_ele(slave1), false); end

  # An element is split cases:

  set_branch_min_max_changed!(branch, slave1.ix_ele, slave1.ix_ele+1)

  # Split case 1: Element is a drift. No super lord issues. Need to create a "master drift"
  # representing the original drift in `branch.drift_masters` so that the names of drift slices can 
  # be properly formed using a `!N` suffix where N is an integer.
  if slave1.class == Drift
    slave2 = insert!(branch, slave1.ix_ele+1, slave1)  # Just after slave1

    if haskey(slave1.pdict, :drift_master) 
      master = slave1.pdict[:drift_master]
      ix = findfirst(isequal(slave1), master.pdict[:slices])
      insert!(master.pdict[:slices], ix+1, slave2)
    else
      haskey(branch.pdict, :drift_masters) ? push!(branch.pdict[:drift_masters], copy(slave1)) : 
                                                  branch.pdict[:drift_masters] = Ele[copy(slave1)]
      master = branch.pdict[:drift_masters][end]
      master.pdict[:slices] = [slave1, slave2]
    end

    slave1 = branch.ele[slave1.ix_ele]
    slave1.L = s_split - slave1.s
    slave2.L = slave1.s_downstream - s_split

    slave1.pdict[:drift_master] = master
    slave2.pdict[:drift_master] = master

    index_and_s_bookkeeper!(branch)
    set_drift_slice_names(master)

    return (slave2, true)
  end

  # Split case 2: Element to be split is a super_slave. In this case no new lord is generated.
  if haskey(slave1.pdict, :super_lords)
    slave2 = insert!(branch, slave1.ix_ele+1, slave1)  # Just after slave1
    slave1.L = s_split - slave1.s
    slave2.L = slave1.s_downstream - s_split
    slave1.pdict[:changed][AllParams] = true
    slave2.pdict[:changed][AllParams] = true

    # Now update the slave lists for the super lords to include the new slave.
    # Notice that the lord list of the slaves does not have to be modified.
    for lord in slave1.super_lords
      for (ix, slave) in enumerate(lord.slaves)
        if !(slave === slave1) continue; end
        insert!(lord.slaves, ix+1, slave2)
        break
      end
    end
    index_and_s_bookkeeper!(branch)
    for lord in slave1.super_lords
      set_super_slave_names!(lord)
    end

    return (slave2, true)
  end

  # Split case 3: Element to be split is not a super_slave. Here create a super lord.
  # Important for multipass control that original slave1 is put in the super lord branch
  # and the copies are in the tracking branch.

  lord = copy(slave1)

  pop!(slave1.pdict, :multipass_lord, nothing)
  slave1.pdict[:super_lords] = Vector{Ele}([lord])
  slave1.slave_status = Slave.SUPER

  branch.ele[slave1.ix_ele] = slave1
  slave2 = insert!(branch, slave1.ix_ele+1, slave1)
  slave1.L = s_split - lord.s 
  slave2.L = lord.s_downstream - s_split
  slave1.pdict[:changed][AllParams] = true
  slave2.pdict[:changed][AllParams] = true
 
  sbranch = branch.lat[SuperBranch]
  push!(sbranch.ele, lord)
  lord.pdict[:slaves] = Vector{Ele}([slave1, slave2])
  lord.lord_status = Lord.SUPER
  lord.pdict[:changed][AllParams] = true

  index_and_s_bookkeeper!(branch)
  index_and_s_bookkeeper!(sbranch)
  set_super_slave_names!(lord)

  return slave2, true
end

