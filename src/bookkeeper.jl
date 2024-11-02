#---------------------------------------------------------------------------------------------------
# ChangedLedger

"""
    Internal: mutable struct ChangedLedger

When bookkeeping a branch, element-by-element, starting from the beginning of the branch,
the ledger keeps track of what has changed so that the change can propagate to the 
following elements. 

Ledger parameters, when toggled to true, will never be reset for the remainder of the branch bookkeeping.
The exception is the `this_ele_length` parameter which is reset for each element.
""" ChangedLedger

@kwdef mutable struct ChangedLedger
  this_ele_length::Bool = false
  s_position::Bool = false
  ref_group::Bool = false
  floor_position::Bool = false
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Lattice)

"""
    bookkeeper!(lat::Lattice)

All Lattice bookkeeping. For example, if the reference energy is changed at the start of a branch the 
bookkeeping code will propagate that change through the reset of the lattice. 
""" bookkeeper!(lat::Lattice)

function bookkeeper!(lat::Lattice)
  if !lat.parameters_have_changed; return; end
  lat.parameters_have_changed = false

  # Lord bookkeeping at the start involves transferring changes in the lords to the slaves.

  start_multipass_bookkeeper!(lat)
  start_superimpose_bookkeeper!(lat)

  # Tracking branch bookkeeping

  for (ix, branch) in enumerate(lat.branch)
    if branch.type != TrackingBranch; continue; end
    branch.pdict[:ix_branch] = ix
    bookkeeper!(branch)
  end

  # Lord bookkeeping at the end involves making sure that shifts in the reference energy
  # which have filtered up from the slaves to the lords is handled.

  end_multipass_bookkeeper!(lat)
  end_superimpose_bookkeeper!(lat)
end

#---------------------------------------------------------------------------------------------------
# check_if_settable

"""
    Internal: check_is_settable(ele::Ele, sym::Symbol, pinfo::Union{ParamInfo, Nothing})

Check that it is valid to have varied element parameters.
For example, parameters of a super slave element cannot be directly changed.
Or dependent parameters cannot be directly changed.
"""



function check_if_settable(ele::Ele, sym::Symbol, pinfo::Union{ParamInfo, Nothing})
  branch = lat_branch(ele)
  lat = lattice(ele)
  if !isnothing(lat) && !lat.record_changes; return; end

  if !isnothing(lat)
    if get(ele, :slave_status, 0) == Slave.MULTIPASS || get(ele, :slave_status, 0) == Slave.SUPER
      if sym == :multipass_phase; return; end
      error("Changing component $sym in multipass or super slave $(ele_name(ele)) not allowed.")
    end
  end

  if sym in DEPENDENT_ELE_PARAMETERS
    error("Parameter is not user settable: $sym. For element: $(ele_name(ele)).")
  end
end

#---------------------------------------------------------------------------------------------------
# start_multipass_bookkeeper!(lat)

"""
    Internal: start_multipass_bookkeeper!(lat)

Bookkeeper to handle changes in multipass lord elements. Used by `bookkeeper!(::Lattice)`
""" start_multipass_bookkeeper!

function start_multipass_bookkeeper!(lat)
  mbranch = lat_branch(lat, MultipassLordBranch)
  for lord in mbranch.ele

  end 
end

#---------------------------------------------------------------------------------------------------
# end_multipass_bookkeeper!(lat)

"""
    Internal: end_multipass_bookkeeper!(lat)

Bookkeeper to handle changes in multipass lord elements. Used by `bookkeeper!(::Lattice)`
""" end_multipass_bookkeeper!

function end_multipass_bookkeeper!(lat)
  mbranch = lat_branch(lat, MultipassLordBranch)
  for lord in mbranch.ele
    cdict = lord.changed

    if haskey(cdict, :ReferenceGroup)
      if haskey(lord.pdict, :BMultipoleGroup)
        elegroup_bookkeeper!(lord, BMultipoleGroup, ChangedLedger(ref_group = true), NULL_ELE)
        for slave in lord.slaves
          slave.BMultipoleGroup = copy(lord.BMultipoleGroup)
          elegroup_bookkeeper!(slave, BMultipoleGroup, ChangedLedger(ref_group = true), NULL_ELE)
        end
      end

      if haskey(lord.pdict, :EMultipoleGroup)
        elegroup_bookkeeper!(lord, EMultipoleGroup, ChangedLedger(ref_group = true), NULL_ELE)
        for slave in lord.slaves
          slave.EMultipoleGroup = copy(lord.EMultipoleGroup)
          elegroup_bookkeeper!(slave, EMultipoleGroup, ChangedLedger(ref_group = true), NULL_ELE)
        end
      end

      pop!(cdict, :ReferenceGroup)
    end
  end 
end

#---------------------------------------------------------------------------------------------------
# start_superimpose_bookkeeper!(lat)

"""
    Internal: start_superimpose_bookkeeper!(lat)

Bookkeeper to handle changes in super lord elements. Used by `bookkeeper!(::Lattice)`
""" start_superimpose_bookkeeper!

function start_superimpose_bookkeeper!(lat)
  sbranch = lat_branch(lat, SuperLordBranch)
  for lord in sbranch.ele

  end 
end

#---------------------------------------------------------------------------------------------------
# end_superimpose_bookkeeper!(lat)

"""
    Internal: end_superimpose_bookkeeper!(lat)

Bookkeeper to handle changes in super lord elements. Used by `bookkeeper!(::Lattice)`
""" end_superimpose_bookkeeper!

function end_superimpose_bookkeeper!(lat)
  autob = lat.autobookkeeping
  lat.autobookkeeping = false
  sbranch = lat_branch(lat, SuperLordBranch)
  for lord in sbranch.ele
    lord.pdict[:LengthGroup].s = lord.slaves[1].s
    lord.pdict[:LengthGroup].s_downstream = lord.slaves[end].s_downstream
  end
  lat.autobookkeeping = autob
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Branch)

"""
    Internal: bookkeeper!(branch::Branch)

Branch bookkeeping. This routine is called by `bookkeeper!(lat::Lattice)`.
Only tracking branches are examined. Lord branches are ignored.
""" bookkeeper!(branch::Branch)

function bookkeeper!(branch::Branch)
  if branch.pdict[:type] == LordBranch; return; end

  ix_min = branch.pdict[:ix_ele_min_changed]
  if ix_min > length(branch.ele); return; end
  ix_min == 1 ? previous_ele = NULL_ELE : previous_ele = branch[ix_min-1].ele
  ix_max = branch.pdict[:ix_ele_max_changed]
  changed = ChangedLedger()

  for ele in branch.ele[ix_min:end]
    bookkeeper!(ele, changed, previous_ele)
    previous_ele = ele
    if ix_max > 0 && ele.ix_ele == ix_max && changed == ChangedLedger(); break; end
  end

  branch.pdict[:ix_ele_min_changed] = typemax(Int)
  branch.pdict[:ix_ele_max_changed] = 0
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Ele)

"""
    Internal: bookkeeper!(ele::Ele, ..., previous_ele::Ele)

Ele bookkeeping. For example, propagating the floor geometry from one element to the next. 
These low level routines (there are several with this signature) are called via `bookkeeper!(lat::Lattice)`.

### Output

- `ele`           -- Element to do bookkeeping on.
- `previous_ele`  -- Element in the branch before `ele`. Will be `NULL_ELE` if this is the first branch element.
""" bookkeeper!(ele::Ele)

function bookkeeper!(ele::Ele, changed::ChangedLedger, previous_ele::Ele)
  for group in PARAM_GROUPS_LIST[typeof(ele)]
    if !haskey(ELE_PARAM_GROUP_INFO, group) || !ELE_PARAM_GROUP_INFO[group].bookkeeping_needed; continue; end

    try
      elegroup_bookkeeper!(ele, group, changed, previous_ele)
    catch er
      reinstate_changed!(ele, group)    # Try to undo the dammage.
      rethrow(er)
    end
  end

  # Throw out changed parameters that don't need bookkeeping

  for param in copy(keys(ele.pdict[:changed]))
    pinfo = ele_param_info(param)
    if isnothing(pinfo); continue; end
    group = pinfo.parent_group
    if group ∉ keys(ELE_PARAM_GROUP_INFO); continue; end
    if !ELE_PARAM_GROUP_INFO[group].bookkeeping_needed; pop!(ele.pdict[:changed], param); end
  end

  # Check for unbookkeeped parameters
  for param in keys(ele.pdict[:changed])
    println("Unbookkeeped parameter $param in element $(ele_name(ele))")
  end
end

#---------------------------------------------------------------------------------------------------
# index_and_s_bookkeeper!(Branch)

"""
    Internal: index_and_s_bookkeeper!(branch::Branch)

Does "quick" element index and s-position bookkeeping for a given branch.
Used by lattice manipulation routines that need reindexing but don't need a full bookkeeping.
""" index_and_s_bookkeeper!

function index_and_s_bookkeeper!(branch::Branch)
  for (ix, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix
    ele.pdict[:branch] = branch
  end

  if branch.type <: LordBranch; return; end
  s_now = branch.ele[1].s

  for (ix, ele) in enumerate(branch.ele)
    set_param!(ele, :s, s_now)
    s_now = s_now + ele.L
    set_param!(ele, :s_downstream, s_now)
  end
end

#---------------------------------------------------------------------------------------------------
# param_conflict_check

"""
    param_conflict_check(ele::Ele, syms...)

Checks if there is a symbol conflict in `ele`.
A symbol conflict occurs when two keys in `ele.changed[]` are not allowed to both be simultaneously set.
For example, `rho` and `g` for a `Bend` cannot be simultaneously set since it is not clear how
to handle this case (since `rho` * `g` = 1 they are not independent variables).

Returns an array of the names of the parameters present. 
"""  param_conflict_check

function param_conflict_check(ele::Ele, syms...)
  sym_in = []

  for sym in syms
    if haskey(ele.changed, sym); push!(sym_in, sym); end
  end
  if length(sym_in) > 1; error(f"Conflict: {s[1]} and {s[2]} cannot both " * 
                                    f"be specified for a {typeof(ele)} element: {ele.name}"); end
  return sym_in
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{T}, ...)
# Essentially no bookkeeping is needed for groups not covered by a specific method.

function elegroup_bookkeeper!(ele::Ele, group::Type{T}, changed::ChangedLedger, 
                                      previous_ele::Ele) where T <: EleParameterGroup
  clear_changed!(ele, group)
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{TrackingGroup}, ...)
# Low level LengthGroup bookkeeping.

function elegroup_bookkeeper!(ele::Ele, group::Type{TrackingGroup}, changed::ChangedLedger, previous_ele::Ele)
  tg = ele.TrackingGroup
  cdict = ele.changed

  if haskey(cdict, :num_steps)
    pop!(cdict, :num_steps)
    tg.ds_step = ele.L / tg.num_steps
  end

  if haskey(cdict, :ds_step)
    pop!(cdict, :ds_step)
    tg.num_steps = ele.L / tg.ds_step
  end
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{LengthGroup}, ...)
# Low level LengthGroup bookkeeping.

function elegroup_bookkeeper!(ele::Ele, group::Type{LengthGroup}, changed::ChangedLedger, previous_ele::Ele)
  lg = ele.LengthGroup
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
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, ...)
# ReferenceGroup bookkeeping

# Note: RF reference bookkeeping, which is complicated and needs information from other structures, 
# is handled by the RFGroup bookkeeping code. So this routine simply ignores this complication.

function elegroup_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, changed::ChangedLedger, previous_ele::Ele)
  rg = ele.ReferenceGroup
  cdict = ele.changed

  if has_changed(ele, ReferenceGroup); changed.ref_group = true; end

  if is_null(previous_ele)   # implies BeginningEle
    if rg.species_ref == Species("NotSet"); error(f"Species not set for first element in branch: {ele_name(ele)}"); end
    rg.species_ref_exit = rg.species_ref

    rg.time_ref_downstream = rg.time_ref + rg.dtime_ref

    if haskey(cdict, :pc_ref) && haskey(cdict, :E_tot_ref)
      error(f"Beginning element has both pc_ref and E_tot_ref set in {ele_name(ele)}")
    elseif haskey(cdict, :E_tot_ref)
      rg.pc_ref = pc(rg.species_ref, E_tot = rg.E_tot_ref)
    elseif  haskey(cdict, :pc_ref)
      rg.E_tot_ref = E_tot(rg.species_ref, pc = rg.pc_ref)
    elseif rg.pc_ref == NaN && rg.E_tot_ref == NaN
      error(f"Neither pc_ref nor E_tot_ref set for: {ele_name(ele)}")
    end

    rg.pc_ref_downstream = rg.pc_ref
    rg.E_tot_ref_downstream = rg.E_tot_ref

    rg.β_ref            = rg.pc_ref / rg.E_tot_ref
    rg.β_ref_downstream = rg.pc_ref_downstream / rg.E_tot_ref_downstream

    clear_changed!(ele, ReferenceGroup)
    return
  end

  # Propagate from previous ele

  if !changed.this_ele_length && !changed.ref_group; return; end
  changed.ref_group = true

  rg.species_ref      = previous_ele.species_ref_exit
  rg.species_ref_exit = rg.species_ref
  rg.pc_ref           = previous_ele.pc_ref_downstream
  rg.E_tot_ref        = previous_ele.E_tot_ref_downstream
  rg.time_ref         = previous_ele.time_ref_downstream
  rg.β_ref            = rg.pc_ref / rg.E_tot_ref


  if typeof(ele) == LCavity
    rg.pc_ref_downstream      = rg.pc_ref + ele.dvoltage_ref
    rg.E_tot_ref_downstream   = E_tot_from_pc(rg.pc_ref_downstream, rg.species_ref)
    rg.time_ref_downstream    = rg.time_ref + rg.dtime_ref + ele.L *
             (rg.E_tot_ref + rg.E_tot_ref_downstream) / (c_light * (rg.pc_ref + rg.pc_ref_downstream))
  else
    rg.pc_ref_downstream      = rg.pc_ref
    rg.E_tot_ref_downstream   = rg.E_tot_ref
    rg.time_ref_downstream    = rg.time_ref + rg.dtime_ref + ele.L / (c_light * rg.pc_ref / rg.E_tot_ref)
  end

  rg.β_ref_downstream = rg.pc_ref_downstream / rg.E_tot_ref_downstream

  # Lord bookkeeping

  if ele.slave_status == Slave.MULTIPASS
    lord = ele.pdict[:multipass_lord]
    if lord.pdict[:slaves][1] === ele 
      lord.ReferenceGroup = rg
      haskey(lord.pdict, :changed) ? lord.changed = Dict(:ReferenceGroup => "changed") : lord.changed[:ReferenceGroup] = "changed" 
    end
  end

  if ele.slave_status == Slave.SUPER
    for lord in ele.super_lords
      if !(lord.pdict[:slaves][1] === ele); continue; end
      lord.ReferenceGroup = rg
      haskey(lord.pdict, :changed) ? lord.changed = Dict(:ReferenceGroup => "changed") : lord.changed[:ReferenceGroup] = "changed" 
    end
  end

  clear_changed!(ele, ReferenceGroup)
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, ...)
# FloorPositionGroup bookkeeper

function elegroup_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, 
                                              changed::ChangedLedger, previous_ele::Ele)
  fpg = ele.FloorPositionGroup
  cdict = ele.changed

  if has_changed(ele, FloorPositionGroup) || changed.this_ele_length; changed.floor_position = true; end
  if !changed.floor_position; return; end

  ele.FloorPositionGroup = propagate_ele_geometry(previous_ele)
  clear_changed!(ele, FloorPositionGroup)
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{BendGroup}, ...)
# BendGroup bookkeeping.

function elegroup_bookkeeper!(ele::Ele, group::Type{BendGroup}, changed::ChangedLedger, previous_ele::Ele)
  bg = ele.BendGroup
  cdict = ele.changed

  if !has_changed(ele, BendGroup) && !changed.this_ele_length && !changed.ref_group; return; end

  sym1 = param_conflict_check(ele, :L, :L_chord)
  sym2 = param_conflict_check(ele, :g, :rho)
  param_conflict_check(ele, :e1, :e1_rect)
  param_conflict_check(ele, :e2, :e2_rect)

  if haskey(cdict, :angle) && length(sym1) + length(sym2) == 2; error(f"Conflict: {sym1[1]} " *
                         f"{sym2[1]} cannot both be specified for a Bend element: {ele.name}"); end

  if haskey(cdict, :L_sagitta); error(f"DependentParam: L_sagitta is a dependent parameter and " *
                                                     f"is not settable for: {ele_name(ele)}"); end

  if haskey(cdict, :rho); bg.g = 1.0 / bg.rho; end

  if  haskey(cdict, :angle) && haskey(cdict, :g)
    L = bg.g * bg.angle
  elseif haskey(cdict, :angle) && haskey(cdict, :L_chord)
    if bg.L_chord == 0 && bg.angle != 0; 
                        error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
    bg.angle == 0 ? bg.g = 0.0 : bg.g = 2.0 * sin(bg.angle/2) / bg.L_chord
    L = bg.angle * bg.g
  elseif haskey(cdict, :angle)
    L = ele.L
    if L == 0 && bg.angle != 0; error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
    bg.angle == 0 ? bg.g = 0 : bg.g = bg.angle / L
  elseif changed.this_ele_length
    L = ele.L
    bg.angle = L * bg.g
  end

  bg.g_tot = bg.g + ele.Kn0
  bg.g == 0 ? bg.rho = Inf : bg.rho = 1.0 / bg.g

  bg.bend_field = bg.g * ele.pc_ref / (c_light * charge(ele.species_ref))
  bg.bend_field_tot = bg.g_tot * ele.pc_ref / (c_light * charge(ele.species_ref))

  if haskey(cdict, :L_chord)
    bg.angle = 2 * asin(bg.L_chord * bg.g / 2)
    bg.g == 0 ? bg.L =  bg.L_chord : bg.L = bg.rho * bg.angle
  else
    bg.angle = L * bg.g
    bg.g == 0 ? bg.L_chord = L : bg.L_chord = 2 * bg.rho * sin(bg.angle/2) 
  end

  bg.g == 0 ? bg.L_sagitta = 0.0 : bg.L_sagitta = -bg.rho * cos_one(bg.angle/2)

  if ele.L != L
    ele.L = L
    elegroup_bookkeeper!(ele, LengthGroup, changed, previous_ele)
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

  if bg.fiducial_pt == FiducialPt.NONE || bg.fiducial_pt == FiducialPt.CENTER
    bg.L_rectangle = bg.L_chord
  else
    bg.L_rectangle = bg.L * sinc(bg.angle)
  end

  clear_changed!(ele, BendGroup)
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{SolenoidGroup}, ...)
# SolenoidGroup bookkeeping.

function elegroup_bookkeeper!(ele::Ele, group::Type{SolenoidGroup}, changed::ChangedLedger, previous_ele::Ele)
  sg = ele.SolenoidGroup
  cdict = ele.changed
  if !has_changed(ele, SolenoidGroup) && !changed.ref_group; return; end

  ff = ele.pc_ref / (c_light * charge(ele.species_ref))

  if has_key(cdict, :Ksol)
    sg.Bsol = sg.Ksol * ff
  elseif has_key(cdict, :Bsol)
    sg.Ksol = sg.Bsol / ff
  elseif ele.field_master   # Ref energy has changed
    sg.Ksol = sg.Bsol / ff
  else
    sg.Bsol = sg.Ksol * ff
  end

  clear_changed!(ele, SolenoidGroup)
end

#---------------------------------------------------------------------------------------------------
# elegroup_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, ...)
# BMultipoleGroup bookkeeping.

function elegroup_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, changed::ChangedLedger, previous_ele::Ele)
  bmg = ele.BMultipoleGroup
  cdict = ele.changed
  if !has_changed(ele, BMultipoleGroup) && !changed.this_ele_length && !changed.ref_group; return; end

  ff = ele.pc_ref / (c_light * charge(ele.species_ref))

  for param in keys(cdict)
    (mtype, order, group) = multipole_type(param)
    if isnothing(group) || group != BMultipoleGroup || mtype == "tilt"; continue; end
    mul = multipole!(bmg, order)

    if     mtype[1:2] == "Kn"; mul.Bn = mul.Kn * ff
    elseif mtype[1:2] == "Ks"; mul.Bs = mul.Ks * ff
    elseif mtype[1:2] == "Bn"; mul.Kn = mul.Bn / ff
    elseif mtype[1:2] == "Bs"; mul.Ks = mul.Bs / ff
    end
  end    

  # Update multipoles if the reference energy has changed.
  if changed.ref_group
    if ele.field_master
      for mul in bmg.vec
        mul.Kn = mul.Bn / ff
        mul.Ks = mul.Bs / ff
      end
    else
      for mul in bmg.vec
        mul.Bn = mul.Kn * ff
        mul.Bs = mul.Ks * ff
      end
    end
  end

  clear_changed!(ele, BMultipoleGroup)
end

#---------------------------------------------------------------------------------------------------
# has_changed

"""
Has any parameter in `group` changed since the last bookkeeping?
"""

function has_changed(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  for param in keys(ele.changed)
    info = ele_param_info(param, ele, throw_error = false)
    if isnothing(info); continue; end
    if info.parent_group == group; return true; end
  end

  return false
end

#---------------------------------------------------------------------------------------------------
# clear_changed!

"""
     clear_changed!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

Clear any parameter as having been changed that is associated with `group`.
""" clear_changed!

function clear_changed!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  for param in keys(ele.changed)
    info = ele_param_info(param, ele, throw_error = false)
    if isnothing(info) || info.parent_group != group; continue; end
    pop!(ele.changed, param)
  end
end

#---------------------------------------------------------------------------------------------------
# reinstate_changed

"""
Reinstate values for parameters associated with `group`.
This is used to try to back out of changes that cause an error.
"""

function reinstate_changed!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  for param in keys(ele.changed)
    info = ele_param_info(param, ele, throw_error = false)
    if isnothing(info) || info.parent_group != group; continue; end
    Base.setproperty!(ele, param, ele.changed[param])
  end
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
  multipass_branch = lat.branch["multipass_lord"]

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
      if haskey(ele.pdict, :MasterGroup); ele.field_master = true; end
      push!(lord.pdict[:slaves], ele)
    end
  end
end

