#---------------------------------------------------------------------------------------------------
# bookkeeper!(Lattice; init::Bool = false)

"""
    bookkeeper!(lat::Lattice; init::Bool = false)

All Lattice bookkeeping. For example, if the reference energy is changed at the start of a branch the 
bookkeeping code will propagate that change through the reset of the lattice. 

If `init` is set `true`, maximal bookkeeping will be done. 
Setting `true` meant to be used when the lattice is instantiated.
""" bookkeeper!(lat::Lattice)

function bookkeeper!(lat::Lattice; init::Bool = false)
  if !lat.parameters_have_changed && !init; return; end
  lat.parameters_have_changed = false
  push_bookkeeping_state!(lat, autobookkeeping = false, auditing_enabled = false)

#  try
    # Tracking branch bookkeeping
    for (ix, branch) in enumerate(lat.branch)
      if branch.type != TrackingBranch; continue; end
      branch.pdict[:ix_branch] = ix
      bookkeeper_tracking_branch!(branch, init = init)
    end

    # Check for unbookkeeped parameters
    for branch in lat.branch
      for ele in branch.ele
        for param in keys(ele.pdict[:changed])
          println("WARNING! Unbookkeeped parameter: $(repr(param)) in element $(ele_name(ele)). Please report this!")
        end
      end
    end

#  catch this_err
#    pop_bookkeeping_state!(lat)
#    rethrow(this_err)
#  end

  pop_bookkeeping_state!(lat)
  return
end

#---------------------------------------------------------------------------------------------------
# check_if_settable

"""
    Internal: check_is_settable(ele::Ele, sym::Symbol, pinfo::Union{ParamInfo, Nothing})

Check that it is valid to have varied element parameters.
For example, parameters of a super slave element cannot be directly changed.
Or dependent parameters cannot be directly changed.
""" check_if_settable

function check_if_settable(ele::Ele, sym::Symbol, pinfo::Union{ParamInfo, Nothing})
  branch = lat_branch(ele)
  lat = lattice(ele)
  if !isnothing(lat) && !lat.auditing_enabled; return; end

  if !isnothing(lat)
    if get(ele, :slave_status, 0) == Slave.MULTIPASS || get(ele, :slave_status, 0) == Slave.SUPER
      if sym == :multipass_phase; return; end
      error("Changing component $sym in multipass or super slave $(ele_name(ele)) not allowed.")
    end
  end

  if sym in DEPENDENT_ELE_PARAMETERS
    error("Parameter is not user settable: $sym. For element: $(ele_name(ele)).")
  end

  return
end

#---------------------------------------------------------------------------------------------------
# bookkeeper_tracking_branch!(Branch; init = true)

"""
    Internal: bookkeeper_tracking_branch!(branch::Branch; init::Bool = false)

Branch bookkeeping. This function is called by `bookkeeper!`.
This processes tracking branches only.

If `init` is set `true`, maximal bookkeeping will be done. 
Setting `true` meant to be used when the lattice is instantiated.
""" bookkeeper_tracking_branch!(branch::Branch)

function bookkeeper_tracking_branch!(branch::Branch; init::Bool = false)
  if branch.pdict[:type] == LordBranch; error("Confused bookkeeping! Please report this!"); end

  if init
    ix_min = 1
    ix_max = length(branch.ele)
    changed = ChangedLedger(true, true, true, true)
  else
    ix_min = branch.pdict[:ix_ele_min_changed]
    if ix_min > length(branch.ele); return; end
    ix_max = branch.pdict[:ix_ele_max_changed]
    changed = ChangedLedger()
  end

  ix_min == 1 ? previous_ele = NULL_ELE : previous_ele = branch.ele[ix_min-1]

  for ele in branch.ele[ix_min:end]
    # A UnionEle may not be a super slave.
    if typeof(ele) == UnionEle && ele.slave_status == Slave.SUPER
      bookkeeper_unionele_superslave!(ele, changed, previous_ele)
    elseif ele.slave_status == Slave.SUPER
      bookkeeper_superslave!(ele, changed, previous_ele)
    elseif ele.slave_status == Slave.MULTIPASS
      bookkeeper_multipass_slave!(ele, changed, previous_ele)
    else
      bookkeeper_ele!(ele, changed, previous_ele)
    end

    previous_ele = ele
    if ix_max > 0 && ele.ix_ele == ix_max && changed == ChangedLedger(); break; end
  end

  branch.pdict[:ix_ele_min_changed] = typemax(Int)
  branch.pdict[:ix_ele_max_changed] = 0

  return
end

#---------------------------------------------------------------------------------------------------
# bookkeeper_ele!(ele, changed, previous_ele)

"""
    Internal: bookkeeper_ele!(ele::Ele, changed::ChangedLedger, previous_ele::Ele)

Lattice element bookkeeping. For example, propagating the floor geometry from one element to the next. 
These low level routines (there are several with this signature) are called via `bookkeeper!(lat::Lattice)`.

## Arguments

- `ele`           -- Element to do bookkeeping on.
- `previous_ele`  -- Element in the branch before `ele`. Will be `NULL_ELE` if `ele` is first element in branch.
""" bookkeeper_ele!(ele::Ele)

function bookkeeper_ele!(ele::Ele, changed::ChangedLedger, previous_ele::Ele)
  for group in PARAM_GROUPS_LIST[typeof(ele)]
    if !haskey(ELE_PARAM_GROUP_INFO, group) || !ELE_PARAM_GROUP_INFO[group].bookkeeping_needed; continue; end

    try
      ele_paramgroup_bookkeeper!(ele, group, changed, previous_ele)
    catch this_err
      reinstate_changed!(ele, group)    # Try to undo the dammage.
      rethrow(this_err)
    end
  end

  # Throw out changed parameters that don't need bookkeeping

  cdict = ele.pdict[:changed]

  for param in copy(keys(cdict))
    if typeof(param) != Symbol    # Something like param = `ReferenceParams`
      group = param
    else
      pinfo = ele_param_info(param, throw_error = false)
      if isnothing(pinfo); continue; end
      group = pinfo.parent_group
    end

    if group in keys(ELE_PARAM_GROUP_INFO) && !ELE_PARAM_GROUP_INFO[group].bookkeeping_needed
      pop!(cdict, param)
    end
  end

  if AllParams in keys(cdict); pop!(cdict, AllParams); end
  return
end

#---------------------------------------------------------------------------------------------------
# bookkeeper_unionele_superslave!

"""
    bookkeeper_unionele_superslave!(union_ele::Ele, changed::ChangedLedger, previous_ele::Ele)

Bookkeeping for a `UnionEle` that is also a super slave.
"""

function bookkeeper_unionele_superslave!(union_ele::Ele, changed::ChangedLedger, previous_ele::Ele)
  # Only need to bookkeep lords where union_ele is the first slave 
  for lord in union_ele.super_lords
    if slave_index(union_ele, lord) == 1; bookkeeper_ele!(lord, changed, previous_ele); end
  end

  bookkeeper_ele!(union_ele, changed, previous_ele);
  return
end

#---------------------------------------------------------------------------------------------------
# bookkeeper_superslave!

"""
    Internal: bookkeeper_superslave!(slave::Ele, changed::ChangedLedger, previous_ele::Ele)

Internal bookkeeping for a non-`UnionEle` super slave.
""" bookkeeper_superslave!

function bookkeeper_superslave!(slave::Ele, changed::ChangedLedger, previous_ele::Ele)
  # A non-UnionEle super slave has only one lord
  lord = slave.super_lords[1]
  ix_slave = slave_index(slave)
  L_rel = slave.L / lord.L

  # Bookkeeping of the super lord is only done if the slave is the first superslave of the lord.
  if ix_slave == 1
    bookkeeper_ele!(lord, changed, previous_ele) 
  end

  # Transfer info from lord to slave
  for group in PARAM_GROUPS_LIST[typeof(lord)]
    if group == LengthParams; continue; end     # Do not modify length of slave
    if group == FloorParams; continue; end
    if group == LordSlaveStatusParams; continue; end

    group_changed = has_changed(lord, group)
    if group_changed && group != AlginmentParams
      slave.pdict[Symbol(group)] = copy(lord.pdict[Symbol(group)])
      slave.pdict[:changed][group] = "changed"
    end

    # Note: BodyLoc.CENTER cannot be handled. 
    # Possible solution: Add aperture_offset parameter to group.
    if group == ApertureParams && group_changed && length(lord.slaves) > 1
      lord.orientation == 1 ? ixs = ix_slave : ixs = length(lord.slaves) + 1 - ix_slave
      if slave.aperture_at == BodyLoc.ENTRANCE_END
        if ixs > 1; slave.aperture_at = BodyLoc.NOWHERE; end
      elseif slave.aperture_at == BodyLoc.EXIT_END
        if ixs > length(lord.slaves); slave.aperture_at = BodyLoc.NOWHERE; end
      elseif slave.aperture_at == BodyLoc.BOTH_ENDS
        if ixs == 1
          slave.aperture_at = BodyLoc.ENTRANCE_END
        elseif ixs == length(lord.slaves)
          slave.aperture_at = BodyLoc.EXIT_END
        else
          slave.aperture_at = BodyLoc.NOWHERE
        end
      end
    end

    if group == EMultipoleParams && (group_changed ||changed.this_ele_length)
      for (ix, elord) in enumerate(lord.pdict[:EMultipoleParams].pole)
        if !elord.Eintegrated; continue; end
        eslave = deepcopy(slave.pdict[:EMultipoleParams].pole[ix])
        eslave.En = elord.En * L_rel
        eslave.Es = elord.Es * L_rel
      end
    end

    if group == TrackingParams && (group_changed ||changed.this_ele_length)
      if lord.num_steps > 0
        slave.num_steps = nint(lord.num_steps * L_rel)
      end
    end

    if group == BodyShiftParams && (group_changed ||changed.this_ele_length)
      if haskey(lord.pdict, :BendParams)
        bgl = lord.pdict[:BendParams]
        bgs = slave.pdict[:BendParams]
        # Need transformation from lord alignment point to slave alignment point
        # Translate from lord alignment point to beginning of lord point
        ct = FloorParams(r = [0.0, 0.0, -0.5*bgl.l_chord])
        # Rotate from z parallel to lord chord to z tangent to bend curve.
        ct = rot(ct, bend_quaternion(-0.5*bgl.angle, bg.ref_tilt))
        # Transform from beginning of lord to beginning of slave
        ct = coord_transform(slave.s - lord.s, bgl.g, bgl.ref_tilt)
        # Rotate from z tangent to bend curve to z parallel to slave chord.
        ct = rot(ct, bend_quaternion(0.5*bgs.angle, bg.ref_tilt))
        # translate from beginning of slave to center of slave chord.
        ct.r = ct.r + [0.0, 0.0, 0.5*bgs.l_chord]
        # Apply total transformation of BodyShiftParams.
        bs = lord.pdict[:BodyShiftParams]
        lord_shift = FloorParams(bs.offset, Quaternion(bs.x_rot, bs.y_rot, bs.z_rot))
        slave_shift = coord_transform(lord_shift, ct)
        slave.BodyShiftParams = BodyShiftParams(slave_shift.r, rot_angles(slave_shift.q)...)
      end
    end
  end

  # Now bookkeep the slave
  bookkeeper_ele!(slave, changed, previous_ele)  # In case slave parameters have changed.

  # If last slave of lord, clear lord.changed dict.
  if ix_slave == length(lord.slaves); lord.pdict[:changed] = Dict{Symbol,Any}(); end

  return
end

#---------------------------------------------------------------------------------------------------
# bookkeeper_multipass_slave!(slave, changed, previous_ele)

"""
    Internal: bookkeeper_multipass_slave!(slave::Ele, changed::ChangedLedger, previous_ele::Ele)

Internal bookkeeping for multipass slave.

""" bookkeeper_multipass_slave!

function bookkeeper_multipass_slave!(slave::Ele, changed::ChangedLedger, previous_ele::Ele)
  lord = slave.multipass_lord
  cdict = lord.changed

  # Bookkeep the lord but only if this is the first slave.
  if slave_index(slave) == 1
    ele_paramgroup_bookkeeper!(lord, ReferenceParams, changed, previous_ele)
    haskey(lord.pdict, :BMultipoleParams) && ele_paramgroup_bookkeeper!(lord, BMultipoleParams, changed, previous_ele)
    haskey(lord.pdict, :EMultipoleParams) && ele_paramgroup_bookkeeper!(lord, EMultipoleParams, changed, previous_ele)
  end

  # Transfer info from lord to slave
  for param in copy(keys(lord.pdict[:changed]))
    if typeof(param) != Symbol; continue; end
    pinfo = ele_param_info(param)
    if isnothing(pinfo); continue; end
    group = pinfo.parent_group
    if group ∉ keys(ELE_PARAM_GROUP_INFO); continue; end  # Ignore custom stuff
    if group == LengthParams; continue; end     # Do not modify length of slave
    if group == ReferenceParams; continue; end  # Slave ReferenceParams independent of lord

    slave.pdict[Symbol(group)] = deepcopy(lord.pdict[Symbol(group)])
    slave.pdict[:changed][group] = "changed"
  end

  # Now bookkeep the slave
  bookkeeper_ele!(slave, changed, previous_ele)  # In case slave parameters have changed.

  # If last slave of lord, clear lord.changed dict.
  if lord.slaves[end] == slave; lord.pdict[:changed] = Dict{Symbol,Any}(); end

  return
end

#---------------------------------------------------------------------------------------------------
# index_and_s_bookkeeper!(Branch)

"""
    Internal: index_and_s_bookkeeper!(branch::Branch, ix_start = 1)

Does "quick" element index and s-position bookkeeping for a given branch starting
at index `ix_start` to the end of `branch.ele`.

  Used by lattice manipulation routines that need reindexing but do not need (or want) a full bookkeeping.
""" index_and_s_bookkeeper!

function index_and_s_bookkeeper!(branch::Branch, ix_start = 1)
  for ix in range(ix_start, length(branch.ele))
    pdict = branch.ele[ix].pdict
    pdict[:ix_ele] = ix
    pdict[:branch] = branch
  end

  if branch.type <: LordBranch; return; end

  ix_start == 1 ?  s_now = branch.ele[ix_start].s : s_now = branch.ele[ix_start-1].s_downstream
  for ix in range(ix_start, length(branch.ele))
    ele = branch.ele[ix]
    set_param!(ele, :s, s_now)
    s_now = s_now + ele.L
    set_param!(ele, :s_downstream, s_now)
  end

  return
end

#---------------------------------------------------------------------------------------------------
# param_conflict_check

"""
    param_conflict_check(ele::Ele, syms...)

Checks if there is a symbol conflict in `ele`.
A symbol conflict occurs when two keys in `ele.changed[]` are not allowed to both be simultaneously set.
For example, `L` and `L_chord` for a `Bend` cannot be simultaneously set.

Returns an array of the names of the parameters present. 
"""  param_conflict_check

function param_conflict_check(ele::Ele, syms...)
  sym_in = []

  for sym in syms
    if haskey(ele.changed, sym); push!(sym_in, sym); end
  end
  if length(sym_in) > 1; error("Conflict: $(s[1]) and $(s[2]) cannot both " * 
                                    "be specified for a $(typeof(ele)) element: $(ele.name)"); end
  return sym_in

  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{T}, ...)
# Essentially no bookkeeping is needed for groups not covered by a specific method.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{T}, changed::ChangedLedger, 
                                      previous_ele::Ele) where T <: EleParams
  clear_changed!(ele, group)
  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{BMultipoleParams}, ...)
# BMultipoleParams bookkeeping.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{BMultipoleParams}, changed::ChangedLedger, previous_ele::Ele)
  bmg = ele.BMultipoleParams
  cdict = ele.changed
  if !has_changed(ele, BMultipoleParams) && !changed.this_ele_length && !changed.reference; return; end

  ff = ele.pc_ref / (C_LIGHT * charge(ele.species_ref))

  if ele.slave_status == Slave.SUPER
    lord = ele.super_lords[1]
    L_rel = ele.L / lord.L
    for (ix, lpole) in enumerate(lord.pdict[:BMultipoleParams].pole)
      epole = deepcopy(ele.pdict[:BMultipoleParams].pole[ix])
      if lpole.integrated
        epole.Kn = lpole.Kn * L_rel
        epole.Bn = lpole.Bn * L_rel
        epole.Ks = lpole.Ks * L_rel
        epole.Bs = lpole.Bs * L_rel
      else
        ele.pdict[:BMultipoleParams].pole[ix] = deepcopy(lpole)
      end
    end

  # Not a slave case
  else
    for param in keys(cdict)
      if typeof(param) == DataType; continue; end
      (mtype, order, group) = multipole_type(param)
      if isnothing(group) || group != BMultipoleParams || mtype == "tilt"; continue; end
      mul = multipole!(bmg, order)

      if     mtype[1:2] == "Kn"; mul.Bn = mul.Kn * ff
      elseif mtype[1:2] == "Ks"; mul.Bs = mul.Ks * ff
      elseif mtype[1:2] == "Bn"; mul.Kn = mul.Bn / ff
      elseif mtype[1:2] == "Bs"; mul.Ks = mul.Bs / ff
      end
    end

    # Update multipoles if the reference energy has changed.
    if changed.reference
      if ele.field_master
        for mul in bmg.pole
          mul.Kn = mul.Bn / ff
          mul.Ks = mul.Bs / ff
        end
      else
        for mul in bmg.pole
          mul.Bn = mul.Kn * ff
          mul.Bs = mul.Ks * ff
        end
      end
    end
  end

  clear_changed!(ele, BMultipoleParams)
  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{BendParams}, ...)
# BendParams bookkeeping.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{BendParams}, changed::ChangedLedger, previous_ele::Ele)
  bg = ele.BendParams
  cdict = ele.changed

  if !has_changed(ele, BendParams) && !changed.this_ele_length && !changed.reference; return; end

  if ele.slave_status == Slave.SUPER
    lord = ele.super_lords[1]
    L_rel = ele.L / lord.L
    ix_slave = slave_index(ele)
    ele.BendParams = copy(lord.BendParams)
    bg = ele.BendParams
    bg.angle = lord.angle * L_rel
    if ix_slave < length(lord.slaves)
      bg.e2 = 0
      bg.e2_rect = 0.5 * bg.angle
    elseif ix_slave > 1
      bg.e1 = 0
      bg.e1_rect = 0.5 * bg.angle
    end
    ele.g == 0 ? ele.L_chord = ele.L : ele.L_chord = 2 * sin(ele.angle/2) / ele.g 

  # Not a slave
  else
    conflict1 = param_conflict_check(ele, :L, :L_chord)
    param_conflict_check(ele, :g, :bend_field_ref)
    param_conflict_check(ele, :e1, :e1_rect)
    param_conflict_check(ele, :e2, :e2_rect)

    if haskey(cdict, :bend_field_ref)
      bg.g = bg.bend_field_ref * C_LIGHT * charge(ele.species_ref) / ele.pc_ref
    end

    if haskey(cdict, :angle) && haskey(cdict, :g) && length(conflict1) == 1
      error("Conflict: $(conflict1[1]), g, and angle cannot simultaneously be specified for a Bend element $(ele.name)")
    end

    if  haskey(cdict, :angle) && haskey(cdict, :g)
      L = bg.g * bg.angle
    elseif haskey(cdict, :angle) && haskey(cdict, :L_chord)
      if bg.L_chord == 0 && bg.angle != 0; 
                          error("Bend cannot have finite angle and zero length: $(ele_name(ele))"); end
      bg.angle == 0 ? bg.g = 0.0 : bg.g = 2.0 * sin(bg.angle/2) / bg.L_chord
      L = bg.angle * bg.g
    elseif haskey(cdict, :angle)
      L = ele.L
      if L == 0 && bg.angle != 0; error("Bend cannot have finite angle and zero length: $(ele_name(ele))"); end
        bg.angle == 0 ? bg.g = 0 : bg.g = bg.angle / L
    else
      L = ele.L
      bg.angle = L * bg.g
    end

    if L != ele.L
      ele.L = L
      changed.this_ele_length = true
      changed.s_position = true
      changed.floor_position = true
    end

    bg.bend_field_ref = bg.g * ele.pc_ref / (C_LIGHT * charge(ele.species_ref))

    if haskey(cdict, :L_chord)
      bg.angle = 2 * asin(bg.L_chord * bg.g / 2)
      bg.g == 0 ? bg.L =  bg.L_chord : bg.L = bg.angle / bg.g
    else
      bg.angle = L * bg.g
      bg.g == 0 ? bg.L_chord = L : bg.L_chord = 2 * sin(bg.angle/2) / bg.g 
    end

    if haskey(cdict, :e1)
      bg.e1_rect = bg.e1 - 0.5 * bg.angle
    elseif haskey(cdict, :e1_rect)
      bg.e1 = bg.e1_rect + 0.5 * bg.angle
    elseif bg.bend_type == BendType.SECTOR
      bg.e1_rect = bg.e1 + 0.5 * bg.angle
    else
      bg.e1 = bg.e1_rect - 0.5 * bg.angle
    end

    if haskey(cdict, :e2)
      bg.e2_rect = bg.e2 - 0.5 * bg.angle
    elseif haskey(cdict, :e2_rect)
      bg.e2 = bg.e2_rect + 0.5 * bg.angle
    elseif bg.bend_type == BendType.SECTOR
      bg.e2_rect = bg.e2 + 0.5 * bg.angle
    else
      bg.e2 = bg.e2_rect - 0.5 * bg.angle
    end

    clear_changed!(ele, BendParams)
  end

  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{FloorParams}, ...)
# FloorParams bookkeeper

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{FloorParams}, 
                                              changed::ChangedLedger, previous_ele::Ele)
  fpg = ele.FloorParams
  cdict = ele.changed

  if has_changed(ele, FloorParams) || changed.this_ele_length; changed.floor_position = true; end
  if !changed.floor_position; return; end

  if is_null(previous_ele); return; end   # Happens with beginning element

  ele.FloorParams = propagate_ele_geometry(previous_ele)
  clear_changed!(ele, FloorParams)

  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{ForkParams}, ...)
# ForkParams bookkeeper

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{ForkParams}, 
                                              changed::ChangedLedger, previous_ele::Ele)
  fg = ele.ForkParams
  rg = ele.ReferenceParams

  to_ele = fg.to_ele
  if to_ele.ix_ele != 1
    clear_changed!(ele, ForkParams)
    return
  end

  # Transfer FloorPrams

  if has_changed(ele, FloorParams)
    to_ele.FloorParams = copy(ele.FloorPrams)
    to_ele.pdict[:changed][FloorParams] = true
    set_branch_min_max_changed!(to_ele.branch, 1)
  end

  # Transfer ReferenceParams

  clear_changed!(ele, ForkParams)

  if !fg.propagate_reference && !is_null(to_ele.species_ref) && (!isnan(to_ele.E_tot_ref) || !isnan(to_ele.pc_ref))
    return
  end

  if rg.species_ref == to_ele.species_ref && (rg.E_tot_ref == to_ele.E_tot_ref || rg.pc_ref == to_ele.pc_ref)
    return
  end

  to_ele.pdict[:changed][:pc_ref] = to_ele.pc_ref
  to_ele.species_ref = rg.species_ref
  to_ele.pc_ref      = rg.pc_ref

  set_branch_min_max_changed!(to_ele.branch, 1)
  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{LengthParams}, ...)
# Low level LengthParams bookkeeping.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{LengthParams}, changed::ChangedLedger, previous_ele::Ele)
  lg = ele.LengthParams
  cdict = ele.changed

  if haskey(cdict, :L)
    changed.this_ele_length = true
    changed.s_position = true
    pop!(cdict, :L)
  end

  if is_null(previous_ele)
    if haskey(cdict, :s)
      changed.s_position = true
      pop!(cdict, :s)
    end

    lg.s_downstream = lg.s + lg.L
    return
  end

  if !changed.s_position && !changed.this_ele_length; return; end

  lg.s = previous_ele.s_downstream
  lg.s_downstream = lg.s + lg.L

  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{RFParams}, ...)

"""
    ele_paramgroup_bookkeeper!(ele::Ele, group::Type{RFParams}, changed::ChangedLedger, previous_ele::Ele)

`RFParams` bookkeeping.
"""

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{RFParams}, changed::ChangedLedger, previous_ele::Ele)
  rg = ele.RFParams
  cdict = ele.changed

  if !has_changed(ele, RFParams) && !has_changed(ele, ReferenceParams) && !changed.this_ele_length
    return
  end

  if ele.slave_status == Slave.SUPER
    lord = ele.super_lords[1]
    L_rel = ele.L / lord.L
    rg.voltage = lord.voltage * L_rel
  end

  if ele.field_master
    rg.voltage = rg.gradient * ele.L
  elseif ele.L == 0
    rg.gradient = NaN
  else
    rg.gradient = rg.voltage / ele.L
  end

  clear_changed!(ele, RFParams)
  return
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{ReferenceParams}, ...)

"""
    ele_paramgroup_bookkeeper!(ele::Ele, group::Type{ReferenceParams}, changed::ChangedLedger, previous_ele::Ele)

`ReferenceParams` bookkeeping.
"""

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{ReferenceParams}, 
                                                          changed::ChangedLedger, previous_ele::Ele)
  rg = ele.ReferenceParams
  cdict = ele.changed

  if has_changed(ele, ReferenceParams); changed.reference = true; end

  if ele.slave_status == Slave.SUPER
    lord = ele.super_lords[1]
    L_rel = ele.L / lord.L
    ele.dE_ref = lord.dE_ref * L_rel
    ele.extra_dtime_ref = lord.extra_dtime_ref * L_rel
  end

  #

  if is_null(previous_ele)   # implies BeginningEle
    if !changed.reference; return; end
    if rg.species_ref == Species(); error("Species not set for first element in branch: $(ele_name(ele))"); end

    if haskey(cdict, :pc_ref) && haskey(cdict, :E_tot_ref)
      error("Beginning element has both pc_ref and E_tot_ref set in $(ele_name(ele))")
    elseif haskey(cdict, :E_tot_ref)
      rg.pc_ref = calc_pc(rg.species_ref, E_tot = rg.E_tot_ref)
    elseif haskey(cdict, :pc_ref)
      rg.E_tot_ref = calc_E_tot(rg.species_ref, pc = rg.pc_ref)
    else
      error("Neither pc_ref nor E_tot_ref set for: $(ele_name(ele))")
    end

    clear_changed!(ele, ReferenceParams)
    return
  end

  # Propagate from previous ele

  if !changed.this_ele_length && !changed.reference; return; end

  rg_old = copy(rg)
  rg.species_ref      = previous_ele.species_ref

  if ele.static_energy_ref
    isnan(rg.pc_ref) && isnan(rg.E_tot_ref) &&
        error("With static_energy_ref set true, either pc_ref or E_tot_ref must be set in $(ele_name(ele))")
    if haskey(cdict, :E_tot_ref) || isnan(rg.pc_ref)
      rg.pc_ref = calc_pc(rg.species_ref, E_tot = rg.E_tot_ref)
    else
      rg.E_tot_ref = calc_E_tot(rg.species_ref, pc = rg.pc_ref)
    end

  elseif previous_ele.dE_ref == 0
    rg.pc_ref      = previous_ele.pc_ref
    rg.E_tot_ref   = previous_ele.E_tot_ref
    rg.time_ref    = previous_ele.time_ref + previous_ele.extra_dtime_ref + 
                           previous_ele.L * previous_ele.E_tot_ref / (C_LIGHT * previous_ele.pc_ref)

  else
    rg.pc_ref, rg.E_tot_ref = calc_changed_energy(previous_ele.species_ref, 
                                                            previous_ele.pc_ref, previous_ele.dE_ref)
    rg.time_ref = previous_ele.time_ref + previous_ele.extra_dtime_ref + previous_ele.L *
                  (previous_ele.E_tot_ref + rg.E_tot_ref) / (C_LIGHT * (previous_ele.pc_ref + rg.pc_ref))
  end

  # End stuff

  clear_changed!(ele, ReferenceParams)
  changed.reference = (rg_old != rg)

  return nothing
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{SolenoidParams}, ...)
# SolenoidParams bookkeeping.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{SolenoidParams}, changed::ChangedLedger, previous_ele::Ele)
  sg = ele.SolenoidParams
  cdict = ele.changed
  if !has_changed(ele, SolenoidParams) && !changed.reference; return; end

  ff = ele.pc_ref / (C_LIGHT * charge(ele.species_ref))

  if has_key(cdict, :Ksol)
    sg.Bsol = sg.Ksol * ff
  elseif has_key(cdict, :Bsol)
    sg.Ksol = sg.Bsol / ff
  elseif ele.field_master   # Ref energy has changed
    sg.Ksol = sg.Bsol / ff
  else
    sg.Bsol = sg.Ksol * ff
  end

  clear_changed!(ele, SolenoidParams)
  return nothing
end

#---------------------------------------------------------------------------------------------------
# ele_paramgroup_bookkeeper!(ele::Ele, group::Type{TrackingParams}, ...)
# Low level LengthParams bookkeeping.

function ele_paramgroup_bookkeeper!(ele::Ele, group::Type{TrackingParams}, changed::ChangedLedger, previous_ele::Ele)
  tg = ele.TrackingParams
  cdict = ele.changed

  if haskey(cdict, :num_steps)
    pop!(cdict, :num_steps)
    tg.ds_step = ele.L / tg.num_steps
  end

  if haskey(cdict, :ds_step)
    pop!(cdict, :ds_step)
    tg.num_steps = ele.L / tg.ds_step
  end

  return
end

#---------------------------------------------------------------------------------------------------
# has_changed

"""
    has_changed(ele::Ele, group::Type{T}) where T <: EleParams -> Bool

Has any parameter in `group` changed since the last bookkeeping?
"""

function has_changed(ele::Ele, group::Type{T}) where T <: EleParams
  if ele.slave_status == Slave.SUPER
    lord = ele.super_lords[1]         # UnionEle slave handled elsewhere.
    for param in keys(lord.changed)
      if param == AllParams; return true; end
      if param == group; return true; end
      info = ele_param_info(param, lord, throw_error = false)
      if isnothing(info); continue; end
      if info.parent_group == group; return true; end
    end
  end

  for param in keys(ele.changed)
    if param == AllParams; return true; end
    if param == group; return true; end
    info = ele_param_info(param, ele, throw_error = false)
    if isnothing(info); continue; end
    if info.parent_group == group; return true; end
  end

  return false
end

#---------------------------------------------------------------------------------------------------
# clear_changed!

"""
    clear_changed!(ele::Ele, group::Type{T}; clear_lord::Bool = false) where T <: EleParams
    clear_changed!(ele::Ele)

Clear record of any parameter in `ele` as having been changed that is associated with `group`.
If group is not present, clear all records.

Exception: A super lord or multipasslord is not touched since these lords must retain changed
information until bookkeeping has finished for all slaves. The appropriate lord/slave
bookkeeping code will handle this.
""" clear_changed!

function clear_changed!(ele::Ele, group::Type{T}; clear_lord::Bool = false) where T <: EleParams
  if !clear_lord && (ele.lord_status == Lord.SUPER || 
                     ele.lord_status == Lord.MULTIPASS); return; end

  for param in keys(ele.changed)
    if param == group
      pop!(ele.changed, param)
    else
      info = ele_param_info(param, ele, throw_error = false)
      if isnothing(info) || info.parent_group != group; continue; end
      pop!(ele.changed, param)
    end
  end

  return
end

function clear_changed!(ele::Ele)
  ele.pdict[:changed] = Dict{Union{Symbol,DataType},Any}()
end

#---------------------------------------------------------------------------------------------------
# reinstate_changed

"""
Reinstate values for parameters associated with `group`.
This is used to try to back out of changes that cause an error.
"""

function reinstate_changed!(ele::Ele, group::Type{T}) where T <: EleParams
  for param in keys(ele.changed)
    info = ele_param_info(param, ele, throw_error = false)
    if isnothing(info) || info.parent_group != group; continue; end
    Base.setproperty!(ele, param, ele.changed[param], false)
  end

  return
end

#---------------------------------------------------------------------------------------------------
# init_multipass_bookkeeper!

"""
    Internal: init_multipass_bookkeeper!(lat::Lattice)

Multipass initialization done during lattice expansion.
""" init_multipass_bookkeeper!

function init_multipass_bookkeeper!(lat::Lattice)
  # Sort slaves. multipass_id is an identification tag to enable identifying the set of slaves
  # for a given lord. multipass_id is removed here since it will be no longer needed.
  # The Dict is ordered so that the order of the lords in the lord branch is deterministic.
  # [Note: The id vector contains strings generated by Random and is not deterministic but this is OK.]

  mdict = OrderedDict()
  multipass_branch = lat.branch["multipass"]

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

  # Create multipass lords.
  for (key, val) in mdict
    push!(multipass_branch.ele, deepcopy(val[1]))
    lord = multipass_branch.ele[end]
    delete!(lord.pdict, :multipass_id)
    lord.pdict[:branch] = multipass_branch
    lord.pdict[:ix_ele] = length(multipass_branch.ele)
    lord.pdict[:slaves] = Ele[]
    lord.lord_status = Lord.MULTIPASS
    for (ix, ele) in enumerate(val)
      ele.name = ele.name * "!mp" * string(ix)
      ele.pdict[:multipass_lord] = lord
      ele.slave_status = Slave.MULTIPASS
      ele.static_energy_ref = false
      if haskey(ele.pdict, :MasterParams); ele.field_master = true; end
      push!(lord.pdict[:slaves], ele)
    end
  end

  return
end

#---------------------------------------------------------------------------------------------------
# fork_bookkeeper

"""
  fork_bookkeeper(fork::Ele)

Adds the `Branch` that is forked to to the lattice.
""" fork_bookkeeper

function fork_bookkeeper(fork::Ele)
  isnothing(fork.to_ele) && isnothing(fork.to_line) && 
                                error("Neither to_ele nor to_line set for Fork element $(fork.name)")
  isnothing(fork.to_ele) && typeof(fork.to_line) == Lattice && 
                                error("to_ele not set for fork element $(fork.name)")

  lat = fork.branch.lat

  # If to_line is a BeamLine then forking to a new branch
  if typeof(fork.to_line) == BeamLine 
    typeof(fork.to_ele) == Ele && !isnothing(lattice(fork.to_ele)) && error(
        "Confusion: to_line is a BeamLine and to_ele is associated with a Lattice for fork element $(fork.name).")

    to_branch = new_tracking_branch!(lat, fork.to_line)

    if isnothing(fork.to_ele)
      fork.to_ele = to_branch[1]
    else
      if typeof(fork.to_ele) == Ele
        name = fork.to_ele.name
      else  # String
        name = fork.to_ele
      end

      to_eles = eles_search(to_branch, name)
      if length(to_eles) == 0; error("to_ele $name not found in new branch for fork $(fork.name)."); end
      if length(to_eles) > 1; error("Multiple elements matched to to_ele $name) for fork $(fork.name)."); end
      fork.to_ele = to_eles[1]
    end

  # to_line is nothing means fork to existing element.
  elseif typeof(fork.to_ele) == String
    to_eles = eles_search(lat, fork.to_ele)
    if length(to_eles) == 0; error("to_ele $name not found in new branch for fork $(fork.name)."); end
    if length(to_eles) > 1; error("Multiple elements matched to to_ele $name) for fork $(fork.name)."); end
    fork.to_ele = to_eles[1]
  end

  # 

  to_ele = fork.to_ele
  if haskey(to_ele.pdict, :from_forks)
    push!(to_ele.pdict[:from_forks], fork)
  else
    to_ele.pdict[:from_forks] = Vector{Ele}([fork])
  end

  return
end

#---------------------------------------------------------------------------------------------------
# push_bookkeeping_state

"""
    push_bookkeeping_state!(lat::Lattice; auditing_enabled::Union{Bool,Nothing} = nothing, 
                                autobookkeeping::Union{Bool,Nothing} = nothing)

Push the current state of `auditing_enabled` and `autobookkeeping` onto a saved state stack and set
these parameters to the corresponding arguments if the arguments are not `nothing`.
""" push_bookkeeping_state!

function push_bookkeeping_state!(lat::Lattice; auditing_enabled::Union{Bool,Nothing} = nothing, 
                                     autobookkeeping::Union{Bool,Nothing} = nothing)
  push!(lat.private[:bookkeeping_state], copy(lat.pdict))
  if !isnothing(auditing_enabled); lat.pdict[:auditing_enabled] = auditing_enabled; end
  if !isnothing(autobookkeeping); lat.pdict[:autobookkeeping] = autobookkeeping; end
end

#---------------------------------------------------------------------------------------------------
# pop_bookkeeping_state!

"""
    pop_bookkeeping_state!(lat::Lattice)

Restore the state of `auditing_enabled` and `autobookkeeping` from the saved state stack.
""" pop_bookkeeping_state!

function pop_bookkeeping_state!(lat::Lattice)
  lat.pdict[:auditing_enabled] = lat.private[:bookkeeping_state][end][:auditing_enabled]
  lat.pdict[:autobookkeeping] = lat.private[:bookkeeping_state][end][:autobookkeeping]
  pop!(lat.private[:bookkeeping_state])
end

#---------------------------------------------------------------------------------------------------
# set_branch_min_max_changed!

"""
    function set_branch_min_max_changed!(branch::Branch, ix_ele::Number)
    function set_branch_min_max_changed!(branch::Branch, ix_ele_min::Number, ix_ele_max::Number)

Sets `branch.ix_ele_min_changed` and `branch.ix_ele_max_changed` to record the indexes at which
element parameters have changed. This is used by `bookkeeper!` to minimize computation time.

The arguments `ix_ele`, `ix_ele_min`, and `ix_ele_max` are all element indexes where there
has been a change in parameters.

Note: Elements whose index has shifted but whose parameters have not changed, do not need to be
marked as changed.

""" set_branch_min_max_changed!

function set_branch_min_max_changed!(branch::Branch, ix_ele::Number)
  branch.ix_ele_min_changed = min(branch.ix_ele_min_changed, ix_ele)
  branch.ix_ele_max_changed = max(branch.ix_ele_max_changed, ix_ele)
  if !isnothing(branch.lat); branch.lat.parameters_have_changed = true; end
end

function set_branch_min_max_changed!(branch::Branch, ix_ele_min::Number, ix_ele_max::Number)
  branch.ix_ele_min_changed = min(branch.ix_ele_min_changed, ix_ele_min)
  branch.ix_ele_max_changed = max(branch.ix_ele_max_changed, ix_ele_max)
  if !isnothing(branch.lat); branch.lat.parameters_have_changed = true; end
end
