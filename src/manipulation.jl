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
    Base.insert!(branch::Branch, ix_ele::Int, ele::Ele)

Insert an element `ele` at index `ix_ele` in branch `branch`.
All elements with indexes of `ix_ele` and higher are pushed one element down the array.

Inserted is a copy which is returned.
""" Base.insert!(branch::Branch, ix_ele::Int, ele::Ele)

function Base.insert!(branch::Branch, ix_ele::Int, ele::Ele)
  ele = copy(ele)
  insert!(branch.ele, ix_ele, ele)
  index_and_s_bookkeeper!(branch)
  return ele
end

#---------------------------------------------------------------------------------------------------
# split!

"""
    split!(branch::Branch, s_split::Real, choose_upstream::Bool; ele_near::Ele = NULL_ELE)
    split!(branch::Branch, s_split::Real; choose_upstream::Bool = true, ele_near::Ele = NULL_ELE)

Routine to split an lattice element of a branch into two to create a branch that has an element
boundary at the point s = `s_split`. 
This routine will not split the lattice if the split would create a "runt" element with length less 
than 2*`LatticeGlobal.significant_length`.

> [!NOTE]
> `split_branch!` will redo the appropriate bookkeeping for lords and slaves and
> a super-lord element will be created if needed (not needed for split drifts).
> drift to be split is put in `branch.ele_saved` for possible use if a future superposition uses
> the drift as a reference.
> `bookkeeper!` needs to be called after splitting.

### Input
- `branch`            -- Lattice branch
- `s_split`           -- Position at which branch is to be split.
- `choose_upstream`   -- logical, optional: If no splitting of an element is needed, that is, 
  `s_split` is at an element boundary, there can be multiple possible split points if there exist zero 
  length elements at the split point. If `choose_upsteam` = true, the split will be chosen to be 
  at the maximal upstream location. If `choose_upstream` = false the split will be chosen to be the 
  downstream location. If `s_split` is not at an element boundary, the setting of `choose_upstream` is immaterial.
- `ele_near`          -- Element near the point to be split. `ele_near` is useful in the case where
  there is a patch with a negative length which can create an ambiguity as to where to do the split
  In this case `ele_near` will remove the ambiguity. Also useful to ensure where to split if there
  are elements with zero length nearby. Ignored equal to `NULL_ELE`.

### Output tuple:
- `ele_split`     -- Element just after the s = `s_split` point.
- `split_done`    -- true if lat was split, false otherwise.
""" split!(branch::Branch)

function split!(branch::Branch, s_split::Real, choose_upstream::Bool; ele_near::Ele = NULL_ELE)
  check_if_s_in_branch_range(branch, s_split)
  ele0 = ele_at_s(branch, s_split, choose_upstream, ele_near = ele_near)

  # Make sure split does create an element that is less than min_len in length.
  min_len = min_ele_length(branch.lat)
  if choose_upstream && ele0.s > s_split-min_len
    ele0 = ele_at_s(branch, ele0.s, true)
    s_split = ele0.s_downstream
  elseif !choose_upstream && ele0.s_downstream < s_split+min_len
    ele0 = ele_at_s(branch, ele0.s_downstream, true)
    s_split = ele0.s
  end

  # No element split cases where s_split is at an element boundary.

  if s_split == ele0.s; return (next_ele(ele0, -1), false); end
  if s_split == ele0.s_downstream; return(ele0, false); end

  # An element is split cases:

  # Split case 1: Element is a drift. No super lord issues but save this element in case
  # later superpositions use this drift as a reference element.
  if typeof(ele0) == Drift
    slave2 = copy(ele0)
    slave2.name = ele0.name * "!0"    # To include ele in name setting below
    insert!(branch.ele, ele0.ix_ele+1, slave2)  # Just after ele0
    if haskey(branch.pdict, :ele_save)
      push!(branch.pdict[:ele_save], ele0)
    else
      branch.pdict[:ele_save] = Vector{Ele}([ele0])
    end
    branch.ele[ele0.ix_ele] = copy(ele0)
    branch.ele[ele0.ix_ele].L = s_split - ele0.s
    branch.ele[ele0.ix_ele].name = ele0.name * "!0"
    slave2.L = ele0.s_downstream - s_split
    ele0.ix_ele = -1             # Mark as not being in branch.ele array.
    index_and_s_bookkeeper!(branch)

    # Set names of all split drifts in branch
    drift_index = Dict{String, Int}()
    for ele in branch.ele
      if typeof(ele) != Drift; continue; end
      ix = index(ele.name, "!")
      # Avoid name mangling something like "d!mp1" so check if integer after "!".
      if ix == 0 || isnan(integer(ele.name[ix+1:end], NaN)); continue; end
      if ele.name[1:ix-1] in keys(drift_index)
        drift_index[ele.name[1:ix-1]] += 1
      else
        drift_index[ele.name[1:ix-1]] = 1
      end
      ele.name = ele.name[1:ix] * string(drift_index[ele.name[1:ix-1]])
    end
    return (slave2, true)
  end

  # Split case 2: Element to be split is a super_slave. In this case no new lord is generated.
  if haskey(ele0.pdict, :super_lord)
    slave2 = copy(ele0)
    insert!(branch.ele, ele0.ix_ele+1, slave2)  # Just after ele0
    ele0.L = s_split - ele0.s
    slave2.L = ele0.s_downstream - s_split

    # Now update the slave lists for the super lords to include the new slave.
    # Notice that the lord list of the slaves does not have to be modified.
    for lord in ele0.super_lord
      for (ix, slave) in enumerate(lord.slave)
        if !(slave === ele0) continue; end
        insert!(lord.slave, ix+1, slave2)
        break
      end
    end
    index_and_s_bookkeeper!(branch)
    for lord in ele0.super_lord
      set_super_slave_name!(lord)
    end
    return (slave2, true)
  end

  # Split case 3: Element to be split is not a super_slave. Here create a super_lord.
  # Important for multipass and governor control that original ele0 is put in super_lord branch
  # and the copies are in the tracking branch.

  lord = ele0

  slave = copy(ele0)
  pop!(slave.pdict, :multipass_lord, nothing)
  slave.pdict[:super_lord] = Vector{Ele}([lord])

  branch.ele[slave.ix_ele] = slave
  slave2 = copy(slave)
  insert!(branch.ele, slave.ix_ele+1, slave2)
  slave.L = s_split - ele0.s 
  slave2.L = ele0.s_downstream - s_split

  sbranch = branch.lat.branch[:SuperLord]
  push!(sbranch.ele, lord)
  lord.pdict[:slave] = Vector{Ele}([slave, slave2])

  index_and_s_bookkeeper!(branch)
  index_and_s_bookkeeper!(sbranch)
  set_super_slave_name!(lord)

  return slave, true
end

function split!(branch::Branch, s_split::Real; choose_upstream::Bool = true, ele_near::Ele = NULL_ELE)
  return split!(branch, s_split, choose_upstream; ele_near = ele_near)
end

#---------------------------------------------------------------------------------------------------
# set_super_slave_name!

"""
    Internal: set_super_slave_name!(ele::Ele)

`ele` can be either a super_slave or a super_lord (in which case all the super_slaves of the lord
have their name set.
"""

function set_super_slave_name!(ele::Ele)
  if ele.branch.type <: LordBranch
    for slave in ele.slave
      set_super_slave_name!(slave)
    end
    return
  end

  name = ""
  for lord in ele.super_lord
    ix = findfirst(item -> item === ele, lord.slave)
    name = name * "!!" * lord.name * "!s" * string(ix)
  end
  ele.name = name[3:end]
end
