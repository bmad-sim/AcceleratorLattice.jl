#---------------------------------------------------------------------------------------------------
# init_superimpose!(Lat, superimpose)

"""
    Internal: init_superimpose!(lat::Lat, superimpose::Vector{T}) where T <: Ele
    Internal: init_superimpose!(branch::Branch, superimpose::Vector{T}) where T <: Ele

Internal routine called by `expand` to do initial bookkeeping 
superpositions, reference energy propagation, etc.
""" init_superimpose!

function init_superimpose!(lat::Lat, superimpose::Vector{T}) where T <: Ele
  for branch in lat.branch
    init_superimpose!(branch, superimpose)
  end
end

#---------------------------------------------------------------------------------------------------
# init_superimpose!(Branch, superimpose)

function init_superimpose!(branch::Branch, superimpose::Vector{T}) where T <: Ele
  if branch.pdict[:type] == LordBranch; return; end

  changed = ChangedLedger(false, true, true, true, true)
  previous_ele = nothing
  for ele in branch.ele
    bookkeeper!(ele, changed, previous_ele)
    previous_ele = ele
  end

  for ele in superimpose
    superimpose_branch!(branch, ele)
  end
end

#---------------------------------------------------------------------------------------------------
# add_governor!

"""
    add_governor!(lat::Lat, governor::Union{T, Vector{T}}) where T <: Ele

Initialize lattice controllers and girders.
""" add_governors!

function add_governor!(lat::Lat, governor::Union{T, Vector{T}}) where T <: Ele
  if !(typeof(governor) <: Vector); governor = [governor]; end
  gbranch = branch(lat, "governor")
  gbranch.ele = vcat(gbranch.ele, governor)

  for (ix, ele) in enumerate(gbranch.ele)
    ele.pdict[:ix_ele] = ix
    ele.pdict[:branch] = gbranch
    # ...
  end
end

#---------------------------------------------------------------------------------------------------
# init_ele_bookkeeper!(Controller)

"""
    Internal: init_ele_bookkeeper!(ele::Controller)
    Internal: init_ele_bookkeeper!(ele::Girder)

Initialize `Controller` and `Girder` elements during lattice expansion.
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
        append!(loc, LatEleLocation.(find_eles(lat, ele_id)))
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
# init_multipass_bookkeeper!

"""
    Internal: init_multipass_bookkeeper!(lat::Lat)

Multipass initialization done during lattice expansion.
""" init_multipass_bookkeeper!

function init_multipass_bookkeeper!(lat::Lat)
  # Sort slaves. multipass_id is an identification tag to enable identifying the set of slaves
  # for a given lord. multipass_id is removed here since it will be no longer needed.
  mdict = Dict()
  multipass_branch = lat.branch[:multipass_lord]

  for branch in lat.branch
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
    lord.pdict[:slaves] = Vector{Ele}()
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "!mp" * string(ix)
      ele.pdict[:multipass_lord] = lord
      push!(lord.pdict[:slaves], ele)
    end
  end
end
