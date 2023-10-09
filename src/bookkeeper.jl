#-------------------------------------------------------------------------------------
# lat_init_bookkeeper

function lat_init_bookkeeper!(lat::Lat)
  # Multipass: Sort slaves
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

  # Multipass: Create multipass lords

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

  # Ele parameter groups

  for branch in lat.branch
    for ele in branch.ele
      for group in ele_param_groups[typeof(ele)]
        ele_param_group_init_bookkeeper!(ele, group)
      end
    end
  end
end

#---------------------------------------------------------------------------------------------------
# param_conflict_check

function param_conflict_check(ele::Ele, gdict::Dict{Symbol, Any}, syms...)
  for ix1 in 1:length(syms)-1
    for ix2 in ix1+1:length(syms)
      if haskey(gdict, syms[ix1]) && haskey(gdict, syms[ix2])
        error(f"{syms[ix1]} and {syms[ix2]} cannot both be sepecified for a {typeof(ele)} element: {ele.name}")
      end
    end
  end
end

#---------------------------------------------------------------------------------------------------
# ele_param_group_init_bookkeeper!

"""
    ele_param_group_init_bookkeeper!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

""" ele_param_group_init_bookkeeper!

function ele_param_group_init_bookkeeper!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  init_ele_group!(ele, group)
end

"""
"""

function ele_param_group_init_bookkeeper!(ele::Ele, group::Type{ReferenceGroup})
  branch = ele.branch
  init_ele_group!(ele, ReferenceGroup)
  if typeof(ele) != BeginningEle; return; end

  rg = ele.pdict[:ReferenceGroup]
  if rg.species_ref.name == notset_name; error(f"Species not set in branch: {branch.name}"); end

  if !isnan(ele.pc_ref) && !isnan(ele.E_tot_ref)
    error(f"Beginning element has both pc_ref and E_tot_ref set in branch: {branch.name}")
  elseif isnan(ele.pc_ref) && isnan(ele.E_tot_ref)
    error(f"pc_ref and E_tot_ref not set for beginning element in branch: {branch.name}")
  elseif !isnan(ele.pc_ref)
    rg = @set rg.E_tot_ref = E_tot(ele.pc_ref, rg.species_ref)
  else
    rg = @set rg.pc_ref = pc(ele.E_tot_ref, rg.species_ref)
  end

  ele.pdict[:ReferenceGroup] = ReferenceGroup(pc_ref = rg.pc_ref, pc_ref_exit = rg.pc_ref,
                       E_tot_ref = rg.E_tot_ref, E_tot_ref_exit = rg.E_tot_ref,
                       time_ref = rg.time_ref, time_ref_exit = rg.time_ref, species_ref = rg.species_ref)

end

"""
"""

function ele_param_group_init_bookkeeper!(ele::Ele, group::Type{BendGroup})
  inbox = ele.pdict[:inbox]
  bdict = Dict{Symbol, Any}()
  try; bdict[:len] = ele.len; catch; end

  for field in fieldnames(BendGroup)
    if !haskey(inbox, field); continue; end
    bdict[field] = pop!(inbox, field)
  end

  if haskey(ele.pdict, :BendGroup)

  else  # Starting from scratch
    param_conflict_check(ele, bdict, :len, :len_chord)
    param_conflict_check(ele, bdict, :bend_field, :g, :rho, :angle)
    param_conflict_check(ele, bdict, :e1, :e1_rect)
    param_conflict_check(ele, bdict, :e2, :e2_rect)

    if !haskey(bdict, :bend_type) && (haskey(bdict, :len_chord) || 
              haskey(bdict, :e1_rect) || haskey(bdict, :e2_rect))
      bdict[:bend_type] = RBend
    end
  end

end

"""
"""

function ele_param_group_init_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup})
  if !haskey(ele.pdict, :BMultipoleGroup)
    ele.pdict[:BMultipoleGroup] = BMultipoleGroup(Vector{BMultipole1}([]))
  end
  bmg = ele.pdict[:BMultipoleGroup]

  inbox = ele.pdict[:inbox]
  for (p, value) in inbox
    mstr, order = multipole_type(p)
    if mstr == nothing || (mstr[1] != 'K' && mstr[1] != 'B' && mstr[1] != 't') ; continue; end
    pop!(inbox, p)

    mul = multipole!(bmg, order, insert = BMultipole1(n = order))
    ixm = multipole_index(bmg.vec, order)

    if mstr == "tilt"
      bmg.vec[ixm] = @set mul.tilt = value

    elseif occursin("l", mstr)
      if !mul.integrated && (!isnan(mul.K) || !isnan(mul.Ks) || !isnan(mul.B) || !isnan(mul.Bs))
        try
          len = ele.len
        catch 
          error(f"For element: {ele.name}.\n" *
                f"Combining integrated and non-integrated multipole values for a given order without len defined not permitted.")
        end
        if !isnan(mul.K);  bmg.vec[ixm] = @set mul.K  = mul.K * len; end
        if !isnan(mul.Ks); bmg.vec[ixm] = @set mul.Ks = mul.Ks * len; end
        if !isnan(mul.B);  bmg.vec[ixm] = @set mul.B  = mul.B * len; end
        if !isnan(mul.Bs); bmg.vec[ixm] = @set mul.Bs = mul.Bs * len; end
      end

      bmg.vec[ixm] = @set mul.integrated = true
      mstr = mstr[1:end-1]

    else
      if mul.integrated && (!isnan(mul.K) || !isnan(mul.Ks) || !isnan(mul.B) || !isnan(mul.Bs))
        try
          len = ele.len
        catch 
          error(f"For element: {ele.name}.\n" *
                f"Combining non-integrated and integrated multipole values for a given order without len defined not permitted.")
        end
        if len == 0; error(f"For element: {ele.name}.\n" *
                           f"len = 0 but integrated multipole values need to converted to integrated ones."); end
        if !isnan(mul.K);  bmg.vec[ixm] = @set mul.K  = mul.K / len; end
        if !isnan(mul.Ks); bmg.vec[ixm] = @set mul.Ks = mul.Ks / len; end
        if !isnan(mul.B);  bmg.vec[ixm] = @set mul.B  = mul.B / len; end
        if !isnan(mul.Bs); bmg.vec[ixm] = @set mul.Bs = mul.Bs / len; end
      end
      bmg.vec[ixm] = @set mul.integrated = false
    end

    mul = bmg.vec[ixm]
    if mstr == "K";      bmg.vec[ixm] = @set mul.K  = value
    elseif mstr == "Ks"; bmg.vec[ixm] = @set mul.Ks = value
    elseif mstr == "B";  bmg.vec[ixm] = @set mul.B  = value
    elseif mstr == "Bs"; bmg.vec[ixm] = @set mul.Bs = value
    end

    if mstr == "K" || mstr == "Ks"
      mul = bmg.vec[ixm]; bmg.vec[ixm] = @set mul.B  = NaN
      mul = bmg.vec[ixm]; bmg.vec[ixm] = @set mul.Bs = NaN
    end

    if mstr == "B" || mstr == "Bs"
      mul = bmg.vec[ixm]; bmg.vec[ixm] = @set mul.K  = NaN
      mul = bmg.vec[ixm]; bmg.vec[ixm] = @set mul.Ks = NaN
    end

  end
end

"""
"""

function ele_param_group_init_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup})
  if !haskey(ele.pdict, :EMultipoleGroup)
    ele.pdict[:EMultipoleGroup] = EMultipoleGroup(Vector{EMultipole1}([]))
  end
  emg = ele.pdict[:EMultipoleGroup]

  inbox = ele.pdict[:inbox]
  for (p, value) in inbox
    mstr, order = multipole_type(p)
    if mstr == nothing || mstr[1] != 'E' ; continue; end
    pop!(inbox, p)
    println(f"Start! {ele.name}  {mstr}")

    mul = multipole!(emg, order, insert = EMultipole1(n = order))
    ixm = multipole_index(emg.vec, order)

    if mstr == "Etilt"
      emg.vec[ixm] = @set mul.Etilt = value
    elseif occursin("l", mstr)
      if !mul.integrated && (!isnan(mul.E) && !isnan(mul.Es))
        try
          len = ele.len
        catch 
          error(f"For element: {ele.name}.\n" *
                f"Combining integrated and non-integrated multipole values for a given order without len defined not permitted.")
        end
        if !isnan(mul.E);  emg.vec[ixm] = @set mul.E  = mul.E * len; end
        if !isnan(mul.Es); emg.vec[ixm] = @set mul.Es = mul.Es * len; end
      end

      emg.vec[ixm] = @set mul.integrated = true
      mstr = mstr[1:end-1]

    else
      if mul.integrated && (!isnan(mul.E) || !isnan(mul.Es))
        try
          len = ele.len
        catch 
          error(f"For element: {ele.name}.\n" *
                f"Combining non-integrated and integrated multipole values for a given order without len defined not permitted.")
        end
        if len == 0; error(f"For element: {ele.name}.\n" *
                           f"len = 0 but integrated multipole values need to converted to integrated ones."); end
        if !isnan(mul.E);  emg.vec[ixm] = @set mul.E  = mul.E / len; end
        if !isnan(mul.Es); emg.vec[ixm] = @set mul.Es = mul.Es / len; end
      end

      emg.vec[ixm] = @set mul.integrated = false
    end

    mul = emg.vec[ixm]
    if mstr == "E";  emg.vec[ixm] = @set mul.E  = value; end
    if mstr == "Es"; emg.vec[ixm] = @set mul.Es = value; end
    println(f"L: {emg.vec}")
  end
end

#-------------------------------------------------------------------------------------
# put_params_in_ele_group

"""
    init_ele_group!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

Transfers parameters from `inbox` dict to a particular element `group`.

""" init_ele_group!

function init_ele_group!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  pdict = ele.pdict
  inbox = pdict[:inbox]

  gsym = Symbol(group)
  gdict = Dict{Symbol, Any}()

  # Load gdict with symbols in ele.pdict[:inbox]
  for field in fieldnames(group)
    if !haskey(inbox, field); continue; end
    gdict[field] = pop!(inbox, field)
  end

  str = ""
  for (field, value) in gdict
    str = str * ", $field = $(repr(value))"  # Need repr() for string fields
  end

  # Take advantage of the fact that the group has been defined using @kwargs.
  pdict[gsym] = eval(Meta.parse("$group($(str[3:end]))"))
end

#-----------------------------------------------------------------------------------------
# branch_bookkeeper!

function branch_bookkeeper!(branch::Branch)
  # Set ix_ele and branch pointer for elements.

  for (ix_ele, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix_ele
    ele.pdict[:branch] = branch
  end

  if branch.pdict[:type] == LordBranch; return; end

  # Not a lord branch...
  # Beginning ele bookkeeping

  s_book = false
  ref_book = false
  floor_book = false

  ele = branch.ele[1]
  lg = ele.LengthGroup
  ele.LengthGroup = LengthGroup(len = 0, s = lg.s, s_exit = lg.s)
  rg = ele.ReferenceGroup
  ele.ReferenceGroup = ReferenceGroup(pc_ref = rg.pc_ref, pc_ref_exit = rg.pc_ref,
                       E_tot_ref = rg.E_tot_ref, E_tot_ref_exit = rg.E_tot_ref,
                       time_ref = rg.time_ref, time_ref_exit = rg.time_ref, species_ref = rg.species_ref)


  old_ele = ele
  for (ix, ele) in enumerate(branch.ele[2:end])
    # LengthGroup
    s0 = old_ele.LengthGroup.s_exit
    len = ele.LengthGroup.len
    ele.LengthGroup = LengthGroup(len = len, s = s0, s_exit = s0+len)

    # FloorPositionGroup
    ele.FloorPositionGroup = propagate_ele_geometry(old_ele.FloorPositionGroup, old_ele)

    # ReferenceGroup
    rg = ele.ReferenceGroup
    rg0 = old_ele.ReferenceGroup
    dt = c_light * ele.len * rg0.pc_ref_exit / rg0.E_tot_ref_exit
    ele.ReferenceGroup = ReferenceGroup(pc_ref = rg0.pc_ref_exit, pc_ref_exit = rg0.pc_ref_exit,
            E_tot_ref = rg0.E_tot_ref_exit, E_tot_ref_exit = rg0.E_tot_ref_exit,
            time_ref = rg0.time_ref_exit, time_ref_exit = rg.time_ref_exit + dt, species_ref = rg0.species_ref)

    old_ele = ele
  end
end

#-----------------------------------------------------------------------------------------
# lat_bookkeeper!

function lat_bookkeeper!(lat::Lat)
  for (ix, branch) in enumerate(lat.branch)
    branch.pdict[:ix_branch] = ix
    branch_bookkeeper!(branch)
  end
  # Put stuff like ref energy in lords
end