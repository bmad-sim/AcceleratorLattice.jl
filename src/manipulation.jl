#---------------------------------------------------------------------------------------------------
# Base.copy(lat::Lat)

"""
    Base.copy(lat::Lat)

Shallow copy constructer for a lattice. 
""" Base.copy(lat::Lat)

function Base.copy(lat::Lat)
  lat_copy = Lat(lat.name, copy(lat.branch), copy(lat.pdict))
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
""" Base.copy(branch::Branch)

function Base.copy(branch::Branch)
  branch_copy = Branch(branch.name, copy(branch.ele), copy(branch.pdict))
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
  ele_copy = typeof(ele)(copy(ele.pdict))
  for key in keys(ele.pdict)
    if it_isimmutable(ele.pdict[key]); continue; end
    if key == :branch; continue; end              # Branch pointer
    ele_copy.pdict[key] = copy(ele.pdict[key])
  end
  return ele_copy
end

#---------------------------------------------------------------------------------------------------
# Base.insert!(branch::Branch, ...)

""" 
    Base.insert!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true)

Insert an element `ele` at index `ix_ele` in branch `branch`.
All elements with indexes of `ix_ele` and higher are pushed one element down the array.

Inserted is a (shallow) copy of `ele` and this copy is returned.

 - `adjust_orientation`  If `true`, and the `branch.type` is a `TrackingBranch`, the orientation 
parameter of `ele` is adjusted to match the neighboring elements.

""" Base.insert!(branch::Branch, ix_ele::Int, ele::Ele)

function Base.insert!(branch::Branch, ix_ele::Int, ele::Ele; adjust_orientation = true)
  ele = copy(ele)
  insert!(branch.ele, ix_ele, ele)
  index_and_s_bookkeeper!(branch)

  if adjust_orientation && branch.type == TrackingBranch && length(branch.ele) > 1
    if ix_ele == 1
      ele.pdict[:LengthGroup].orientation = branch.ele[2].orientation
    else
      ele.pdict[:LengthGroup].orientation = branch.ele[ele.ix_ele-1].orientation
    end
  end

  return ele
end

#---------------------------------------------------------------------------------------------------
# split!

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

  # Split case 1: Element is a drift. No super lord issues. Need to create a "master drift"
  # representing the original drift in `branch.drift_masters` so that the names of drift slices can 
  # be properly formed using a `!N` suffix where N is an integer.
  if typeof(slave1) == Drift
    slave2 = copy(slave1)
    insert!(branch.ele, slave1.ix_ele+1, slave2)  # Just after slave1

    if haskey(slave1.pdict, :drift_master) 
      master = slave1.pdict[:drift_master]
      ix = findfirst(isequal(slave1), master.pdict[:slices])
      insert!(master.pdict[:slices], ix+1, slave2)
    else
      haskey(branch.pdict, :drift_masters) ? push!(branch.pdict[:drift_masters], copy(slave1)) : 
                                                branch.pdict[:drift_masters] = Vector{Ele}([copy(slave1)])
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
    slave2 = copy(slave1)
    insert!(branch.ele, slave1.ix_ele+1, slave2)  # Just after slave1
    slave1.L = s_split - slave1.s
    slave2.L = slave1.s_downstream - s_split

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

  # Split case 3: Element to be split is not a super_slave. Here create a super_lord.
  # Important for multipass and governor control that original slave1 is put in super_lord branch
  # and the copies are in the tracking branch.

  lord = slave1

  slave = copy(slave1)
  pop!(slave.pdict, :multipass_lord, nothing)
  slave.pdict[:super_lords] = Vector{Ele}([lord])
  slave.slave_status = Slave.SUPER

  branch.ele[slave.ix_ele] = slave
  slave2 = copy(slave)
  insert!(branch.ele, slave.ix_ele+1, slave2)
  slave.L = s_split - slave1.s 
  slave2.L = slave1.s_downstream - s_split

  sbranch = branch.lat.branch[:super_lord]
  push!(sbranch.ele, lord)
  lord.pdict[:slaves] = Vector{Ele}([slave, slave2])
  lord.lord_status = Lord.SUPER

  index_and_s_bookkeeper!(branch)
  index_and_s_bookkeeper!(sbranch)
  set_super_slave_names!(lord)

  return slave2, true
end

#---------------------------------------------------------------------------------------------------
# set_drift_slice_names

"""
"""

function set_drift_slice_names(drift::Drift)
  # Drift slice case

  if haskey(drift.pdict, :drift_master)
    set_drift_slice_names(drift.pdict[:drift_master])
    return
  end

  # Drift master case

  if !haskey(drift.pdict, :slices); return; end

  n = 0
  for slice in drift.pdict[:slices]
    # A slice may have been replaced by an element via superposition so need to check that a
    # slice still represents a valid element.
    if !haskey(slice.pdict, :branch); continue; end
    branch = slice.branch
    if length(branch.ele) < slice.ix_ele; continue; end
    if !(branch.ele[slice.ix_ele] === slice); continue; end
    n += 1
    slice.name = drift.name * "!$n"
  end
end

#---------------------------------------------------------------------------------------------------
# set_super_slave_names!

"""
    Internal: set_super_slave_names!(lord::Ele) -> nothing

`lord` is a super_lord and all of the slaves of this lord will have their name set.
"""

function set_super_slave_names!(lord::Ele)
  if lord.lord_status != Lord.SUPER; error(f"Argument is not a super_lord: {ele_name(lord)}"); end

  name_dict = Dict{String,Int}()
  for slave in lord.slaves
    if length(slave.super_lords) == 1
      slave.name = lord.name
    else
      slave.name = ""
      for this_lord in slave.super_lords
        slave.name = slave.name * "!" * this_lord.name
      end
      slave.name = slave.name[2:end]
    end

    name_dict[slave.name] = get(name_dict, slave.name, 0) + 1
  end

  index_dict = Dict{String,Int}()
  for slave in lord.slaves
    if name_dict[slave.name] == 1
      slave.name = slave.name * "!s"
    else
      index_dict[slave.name] = get(index_dict, slave.name, 0) + 1
      slave.name = slave.name * "!s" * string(index_dict[slave.name])
    end
  end
end
