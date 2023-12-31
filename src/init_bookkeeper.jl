#---------------------------------------------------------------------------------------------------
# init_bookkeeper!(Lat, superimpose)

"""
    init_bookkeeper!(lat::Lat, superimpose::Vector{T}) where T <: Ele
    init_bookkeeper!(branch::Branch, superimpose::Vector{T}) where T <: Ele

Internal routine called by `expand` to do initial bookkeeping like multipass init,
superpositions, reference energy propagation, etc. Not meant for general use.
""" init_bookkeeper!

function init_bookkeeper!(lat::Lat, superimpose::Vector{T}) where T <: Ele
  init_multipass_bookkeeper!(lat)

  for branch in lat.branch
    init_bookkeeper!(branch, superimpose)
  end
end

#---------------------------------------------------------------------------------------------------
# init_bookkeeper!(Branch)

function init_bookkeeper!(branch::Branch, superimpose::Vector{T}) where T <: Ele
  # Set ix_ele and branch pointer for elements.
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix_ele
    ele.pdict[:branch] = branch
  end

  if branch.pdict[:type] == LordBranch; return; end

  previous_ele = nothing
  for ele in branch.ele
    bookkeeper!(ele, previous_ele)
    previous_ele = ele
  end

  for ele in superimpose
    superimpose_branch!(branch, ele)
  end
end

#---------------------------------------------------------------------------------------------------
# init_governors!

"""
    init_governors!(lat::Lat, governors::Vector{T}) where T<: Ele

Initialize lattice controllers and girders during lattice expansion.
Called by the `expansion` function. Not meant for general use.
""" init_governors!

function init_governors!(lat::Lat, governors::Vector{T}) where T<: Ele
  branch = lat.governor
  branch.ele = Vector{Ele}(governors)
  changed = ChangedLedger(false, true, true, true, true)

  for (ix, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix
    ele.pdict[:branch] = branch
    # ...
  end
end

#---------------------------------------------------------------------------------------------------
# init_ele_bookkeeper!(Controller)

"""
    init_ele_bookkeeper!(ele::Controller)
    init_ele_bookkeeper!(ele::Girder)

Initialize `Controller` and `Girder` elements during lattice expansion. Not meant for general use.
""" init_ele_bookkeeper!

function init_ele_bookkeeper!(ele::Controller)
  lat = ele.branch.lat
  pdict = ele.pdict
  if !haskey(pdict[:inbox], :control); error(f"No control vector defined for Controller: {ele.name}."); end
  if !haskey(pdict[:inbox], :variable); error(f"No variable vector defined for Controller: {ele.name}."); end

  # Put controls in place
  pdict[:control] = pop!(pdict[:inbox], :control)
  for ctl in pdict[:control]
    loc = Vector{LatEleLocation}()
    for ele_id in ctl.eles
      if typeof(ele_id) == LatEleLocation
        push!(loc, ele_id)
      elseif typeof(ele_id) == String
        append!(loc, LatEleLocation.(eles_find(lat, ele_id)))
      else
        error(f"Control ele ID not a string nor a LatEleLocation.")
      end
    end
  end

  # Put variables in place
  pdict[:variable] = pop!(pdict[:inbox], :variable)
  for var in pdict[:variable]
    pdict[:inbox][var.name] = var.value
    var.value = var.old_value
  end
end

#---------------------------------------------------------------------------------------------------
# init_ele_bookkeeper!(Girder)

function init_ele_bookkeeper!(ele::Girder)


end

#---------------------------------------------------------------------------------------------------
# init_multipass_bookkeeper!

"""
    init_multipass_bookkeeper!(lat::Lat)

Multipass initialization done during lattice expansion. Not meant for general use.
""" init_multipass_bookkeeper!

function init_multipass_bookkeeper!(lat::Lat)
  # Sort slaves. multipass_id is an identification tag to enable identifying the set of slaves
  # for a given lord. multipass_id is removed here since it will be no longer needed.
  mdict = Dict()
  for branch in lat.branch
    if branch.name == "multipass_lord"; global multipass_branch = branch; end
    for ele in branch.ele
      id = ele.pdict[:multipass_id]
      delete!(ele.pdict, :multipass_id)
      if length(id) == 0; continue; end
      if haskey(mdict, id)
        push!(mdict[id], ele)
      else
        mdict[id] = [ele]
      end
    end
  end

  # Create multipass lords
  for (key, val) in mdict
    push!(multipass_branch.ele, deepcopy(val[1]))
    lord = multipass_branch.ele[end]
    delete!(lord.pdict, :multipass_id)
    lord.pdict[:branch] = multipass_branch
    lord.pdict[:ix_ele] = length(multipass_branch.ele)
    lord.pdict[:slave] = Vector{Ele}()
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "!mp" * string(ix)
      ele.pdict[:multipass_lord] = lord
      push!(lord.pdict[:slave], ele)
    end
  end
end
