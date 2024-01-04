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
  this_ele_length_set::Bool = false
  s_position::Bool = false
  ref_energy::Bool = false
  ref_time:: Bool = false
  floor::Bool = false
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Lat)

"""
    function bookkeeper!(lat::Lat)

All Lat bookkeeping. For example, if the reference energy is changed at the start of a branch the bookkeeping code will propagate that change through the reset of the lattice. Also controller bookkeeping will be done. 

This routine needs to be called after any lattice changes and before any tracking is done.
""" bookkeeper!(lat::Lat)

function bookkeeper!(lat::Lat)
  for (ix, branch) in enumerate(lat.branch)
    branch.pdict[:ix_branch] = ix
    bookkeeper!(branch)
  end
  # Put stuff like ref energy in lords
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Branch)

"""
    Internal: function bookkeeper!(branch::Branch)

Branch bookkeeping. This routine is called by `bookkeeper!(lat::Lat)`.
""" bookkeeper!(branch::Branch)

function bookkeeper!(branch::Branch)
  if branch.pdict[:type] == LordBranch; return; end

  # Not a lord branch...
  changed = ChangedLedger()
  previous_ele = NULL_ELE

  for (ix, ele) in enumerate(branch.ele)
    bookkeeper!(ele, changed, previous_ele) 
    previous_ele = ele
  end
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Ele)

"""
    Internal: bookkeeper!(ele::Ele, ..., previous_ele::Ele)

Ele bookkeeping. For example, propagating the floor geometry from one element to the next. 
These low level routines (there are several with this signature) are called via `bookkeeper!(lat::Lat)`.

### Output

- `ele`           -- Element to do bookkeeping on.
- `previous_ele`  -- Element in the branch before `ele`. Will be `NULL_ELE` if this is the first branch element.
""" bookkeeper!(ele::Ele)

function bookkeeper!(ele::Ele, changed::ChangedLedger, previous_ele::Ele)
  sort_ele_inbox!(ele)
  for group in ele_param_groups[typeof(ele)]
    ele_group_bookkeeper!(ele, group, changed, previous_ele)
  end
end

#---------------------------------------------------------------------------------------------------
# index_bookkeeper!(Branch)

"""
    Internal: function index_bookkeeper!(branch::Branch)

Does "quick" element index bookkeeping for a given branch.
Used by lattice manipulation routines that need reindexing but don't need a full bookkeeping.
""" index_bookkeeper!

function index_bookkeeper!(branch::Branch)
  for (ix, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix
    ele.pdict[:branch] = branch
  end
end

#---------------------------------------------------------------------------------------------------
# s_bookkeeper!(Branch)

"""
    Internal: function s_bookkeeper!(branch::Branch)

Does "quick" element s-position bookkeeping for a given branch.
Used by lattice manipulation routines that need an s recalc but don't need a full bookkeeping.

Note: Parameters in an element's inbox are not removed (unlike a full bookkeeping) so this
routine will not interfere with a full bookkeeping.
""" s_bookkeeper!

function s_bookkeeper!(branch::Branch)
  if branch.type == LordBranch; return; end

  pdict = branch.ele[1].pdict
  if haskey(pdict, :inbox) && haskey(pdict[:inbox], :s)
    s_old = pdict[:inbox][:s]
    ele1.pdict[:LengthGroup] = LengthGroup(0.0_rp, s_old, s_old)
  else
    s_old = ele1.s_downstream
  end

  for (ix, ele) in enumerate(branch.ele)
    if ix == 1; continue; end
    haskey(pdict, :inbox) && haskey(pdict[:inbox], :L) ? len = pdict[:inbox][:L] : len = ele.L
    ele1.pdict[:LengthGroup] = LengthGroup(len, s_old, s_old+len)
    s_old = s_old + len
  end
end

#---------------------------------------------------------------------------------------------------
# sort_ele_inbox!

"""
  Internal: sort_ele_inbox!(ele::Ele)

Move parameters in `ele.param[:inbox]` such that the value at `ele.param[:inbox][:XXX]` is transfered 
to `ele.param[:inbox][:GGG][:XXX]` where `GGG` is the element parameter group for `XXX` and `ele.param[:inbox][:GGG]`
is a Dict (not an instance of the parameter group).

This is a Low level routine used by `bookkeeper!(lat::Lat)`.
""" sort_ele_inbox!

function sort_ele_inbox!(ele::Ele)
  if is_null(ele); return; end

  pdict = ele.pdict
  if !haskey(pdict, :inbox); return; end
  inbox = pdict[:inbox]

  for sym in copy(keys(inbox))  # Need copy since keys will be added to inbox.
    # In theory, the inbox should originally not contain any parameter group keys. However, if there 
    # has been a problem, there might be some such keys so just ignore.
    if sym in keys(ele_param_group_list); continue; end

    pinfo = ele_param_info(sym, no_info_return = nothing)
    if isnothing(pinfo); error(f"No information on: {sym}."); end
    parent = Symbol(parent_group(pinfo, ele))
    if !haskey(inbox, parent); inbox[parent] = Dict{Symbol,Any}(); end

    # Check if parmeter value in inbox is different from value in group.
    # This may happen with vectors since something like "q1.r_floor = [...]" does not get processed
    # by `Base.setproperty!(ele::T, sym::Symbol, value) where T <: Ele`.

    if haskey(pdict, parent) && hasproperty(pdict[parent], sym) && inbox[sym] == getfield(pdict[parent], sym)
      pop!(inbox, sym)
      continue
    end

    value = pop!(inbox, sym)

    # An alias is something like hgap which gets mapped to hgap1 and hgap2
    if haskey(param_alias, sym)
      for sym2 in param_alias[sym]
        inbox[parent][sym2] = value
      end
    else
      inbox[parent][sym] = value
    end
  end
end

#---------------------------------------------------------------------------------------------------
# ele_inbox_group

"""
  Internal: function ele_inbox_group(pdict, group::Symbol)

  Return the the Dict `pdict[:inbox][group]` if it exists otherwise return `nothing`
""" ele_inbox_group

function ele_inbox_group(pdict, group::Symbol)
  if !haskey(pdict, :inbox) || !haskey(pdict[:inbox], group); return nothing; end
  return pdict[:inbox][group]
end

#---------------------------------------------------------------------------------------------------
# function value_of_ele_param

"""
    function value_of_ele_param (pdict, group::Symbol, param::Symbol, default)

Return:
 - `pdict[inbox][group][param]` if it exists. If not try:
 - `pdict[group].param` if it exists. If not return:
 - `default`

Where: `pdict` is an instance of an `ele.pdict` Dict.
""" value_of_ele_param

function value_of_ele_param(pdict, group::Symbol, param::Symbol, default)
  if haskey(pdict, :inbox) && haskey(pdict[:inbox], group) && haskey(pdict[:inbox][group], param)
    return pdict[inbox][group][param]
  end

  if haskey(pdict, group); return getfield(pdict[group], param); end
  return default
end

#---------------------------------------------------------------------------------------------------
# param_conflict_check

"""
    param_conflict_check(ele::Ele, gdict::Dict{Symbol, Any}, syms...)

Checks if there is a symbol conflict in `gdict`. `gdict` is a Dict o parameter sets for an element.
A symbol conflict occurs when two keys in `gdict` are not allowed to both be simultaneously set.
For example, `rho` and `g` for a `Bend` cannot be simultaneously set since it is not clear how
to handle this case (since `rho` * `g` = 1 they are not independent variables).



"""  param_conflict_check

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
# update_ele_group_from_inbox

function update_ele_group_from_inbox(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  pdict = ele.pdict
  sg = Symbol(group)
  gin = ele_inbox_group(pdict, sg)
  if !haskey(pdict, sg); pdict[sg] = eval( :($(group)()) ); end
  gnow = pdict[sg]

  if isnothing(gin); return; end

  g = Dict(k => getfield(gnow, k) for k in fieldnames(group))
  g = merge(g, gin)

  pdict[sg] = eval_str("$group")(; g...)
  pop!(pdict[:inbox], sg)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{T}, ...)
# Bookkeeping for everything else not covered by a specific function.

function ele_group_bookkeeper!(ele::Ele, group::Type{T}, changed::ChangedLedger, 
                                      previous_ele::Ele) where T <: EleParameterGroup
  update_ele_group_from_inbox(ele, group)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, ...)
# Low level LengthGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  lgin = ele_inbox_group(pdict, :LengthGroup)

  if is_null(previous_ele) && isnothing(lgin)
    if !haskey(pdict, :LengthGroup)
      pdict[:LengthGroup] = LengthGroup()
      changed.s_position = true
      changed.this_ele_length_set = true
    end
    return
  end

  if !changed.s_position && isnothing(lgin); return; end

  if is_null(previous_ele)
    s = 0
    if haskey(lgin, :s)
      s = lgin[:s]
    elseif haskey(pdict, :LengthGroup)
      s = pdict[:LengthGroup].s
    end
  else
    s = previous_ele.s_downstream
  end

  L = 0
  if !isnothing(lgin) && haskey(lgin, :L)
    L = lgin[:L]
    changed.this_ele_length_set = true
  elseif haskey(pdict, :LengthGroup)
    L = pdict[:LengthGroup].L
    changed.this_ele_length_set = false
  end

  if !isnothing(lgin); delete!(pdict[:inbox], :LengthGroup); end
  pdict[:LengthGroup] = LengthGroup(L, s, s + L)
  changed.s_position = true
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, ...)
# ReferenceGroup bookkeeping

# Note: RF reference bookkeeping, which is complicated and needs information from other structures, 
# is handled by the RFGroup bookkeeping code. So this routine simply ignores this complication.

function ele_group_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  rgin = ele_inbox_group(pdict, :ReferenceGroup)
  haskey(pdict, :ReferenceGroup) ? rgnow = pdict[:ReferenceGroup] : rgnow = nothing
  
  if !changed.this_ele_length_set && !changed.ref_energy && isnothing(rgin); return; end
  changed.ref_energy = true

  if is_null(previous_ele)   # implies BeginningEle
    # rgin must exist in this case
    if isnothing(rgin) && isnothing(rgnow)
      error(f"Reference parameters not set for element: {ele_name(ele)}")
    end

    if !haskey(rgin, :species_ref)
      isnothing(rgnow) ? error(f"Species not set for: {ele_name(ele)}") : rgin[:species_ref] = rgnow[:species_ref]
    end
    rgin[:species_ref_exit] = rgin[:species_ref]

    if !haskey(rgin, :time_ref) 
      if isnothing(rgnow)
        rgin[:time_ref] = 0
      else
        rgin[:time_ref] = rgnow.time_ref
      end
    end
    rgin[:time_ref_exit] = rgin[:time_ref]

    if haskey(rgin, :pc_ref) && haskey(rgin, :E_tot_ref)
      error(f"Beginning element has both pc_ref and E_tot_ref set in {ele_name(ele)}")
    elseif haskey(rgin, :E_tot_ref)
      rgin[:pc_ref] = pc_from_E_tot(rgin[:E_tot_ref], rgin[:species_ref])
    elseif  haskey(rgin, :pc_ref)
      rgin[:E_tot_ref] = E_tot_from_pc(rgin[:pc_ref], rgin[:species_ref])
    elseif isnothing(rgnow)
        error(f"pc_ref nor E_tot_ref set for: {ele_name(ele)}")
    else
      rgin[:pc_ref] = rgnow.pc_ref
      rgin[E_tot_ref] = rgnow.E_tot_ref
    end

    rgin[:pc_ref_exit] = rgin[:pc_ref]
    rgin[:E_tot_ref_exit] = rgin[:E_tot_ref]

    pdict[:ReferenceGroup] = ReferenceGroup(; rgin...)
    pop!(pdict[:inbox], :ReferenceGroup)
    return
  end

  # Propagate from previous ele

  old_rg = previous_ele.pdict[:ReferenceGroup]
  pc      = old_rg.pc_ref_exit
  E_tot   = old_rg.E_tot_ref_exit
  time    = old_rg.time_ref_exit
  species = old_rg.species_ref_exit
  species_downstream = species
  dt = pdict[:LengthGroup].L / (c_light * pc / E_tot)

  pdict[:ReferenceGroup] = ReferenceGroup(species_ref = species, species_ref_exit = species_downstream, 
                       pc_ref = pc, pc_ref_exit = pc, E_tot_ref = E_tot, E_tot_ref_exit = E_tot, 
                       time_ref = time, time_ref_exit = time+dt)
  if !isnothing(rgin)
    delete!(pdict[:inbox], :ReferenceGroup)
    error(f"ReferenceGroup parameters cannot be set for this element: {ele_name(ele)}")
  end
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, ...)
# FloorPositionGroup bookkeeper

function ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, 
                                              changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  fpin = ele_inbox_group(pdict, :FloorPositionGroup)

  if is_null(previous_ele)
    update_ele_group_from_inbox(ele, group)
    if !isnothing(fpin); changed.floor = true; end
    return
  end

  if !changed.this_ele_length_set && !changed.floor && isnothing(fpin)
    if !haskey(pdict, :FloorPositionGroup); pdict[:FloorPositionGroup] = previous_ele.FloorPositionGroup; end
    return
  end

  changed.floor = true
  pdict[:FloorPositionGroup] = propagate_ele_geometry(previous_ele.FloorPositionGroup, previous_ele)
  delete!(pdict[:inbox], :FloorPositionGroup)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, ...)
# BendGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  bgin = ele_inbox_group(pdict, :BendGroup)
  haskey(pdict, :BendGroup) ? bgnow = pdict[:BendGroup] : bgnow = nothing

  if isnothing(bgin)
    if isnothing(bgnow)
      pdict[:BendGroup] = BendGroup()
      return
    end
    if !changed.ref_energy && !changed.this_ele_length_set; return; end

    if !haskey(pdict, :inbox); pdict[:inbox] = Dict{Symbol,Any}(); end
    bgin = pdict[:inbox]
  end

  if changed.this_ele_length_set; bgin[:L] = pdict[:LengthGroup].L; end
  param_conflict_check(ele, bgin, :L, :L_chord)
  param_conflict_check(ele, bgin, :bend_field, :g, :rho, :angle)
  param_conflict_check(ele, bgin, :e1, :e1_rect)
  param_conflict_check(ele, bgin, :e2, :e2_rect)

  if haskey(bgin, :bend_type)
    bend_type = bgin[:bend_type]
  elseif !isnothing(bgnow)
    bend_type = bgnow.bend_type
  elseif haskey(bgin, :L_chord)
    bend_type = RBend
  else
    bend_type = SBend
  end

  if haskey(bgin, :bend_field)
    bgin[:g] = bgin[:bend_field] * charge(pdict[:ReferenceGroup].species_ref) * c_light / pdict[:ReferenceGroup].pc_ref
  elseif haskey(bgin, :rho)
    bgin[:g] = 1.0 / bgin[:rho]
  elseif haskey(bgin, :angle)
    if haskey(bgin, :L_chord)
      if bgin[:L_chord] == 0 && bgin[:angle] != 0; error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
      bgin[:angle] == 0 ? bgin[:g] = 0.0 : bgin[:g] = 2.0 * sin(bgin[:angle]/2) / bgin[:L_chord]
    else
      if bg[:L] == 0 && bg[:angle] != 0; error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
      bg[:angle] == 0 ? bg[:g] = 0 : bg[:g] = bg[:angle] / bg[:L]
    end
  elseif !haskey(bgin, :g)
    if isnothing(bgnow)
      bgin[:g] = 0
    elseif changed.ref_energy & pdict[:MasterGroup].field_master 
      bgin[:g] = bgin[:bend_field] * charge(pdict[:ReferenceGroup].species_ref) * c_light / pdict[:ReferenceGroup].pc_ref
    else
      bgin[:g] = bgnow.g
    end
  end

  bgin[:bend_field] = bgin[:g] * pdict[:ReferenceGroup].pc_ref / (c_light * charge(pdict[:ReferenceGroup].species_ref))
  bgin[:g] == 0 ? bgin[:rho] = Inf : bgin[:rho] = 1.0 / bgin[:g]

  if haskey(bgin, :L_chord)
    bgin[:angle] = 2 * asin(bgin[:L_chord] * bgin[:g] / 2)
    bgin[:g] == 0 ? bgin[:L] =  bgin[:L_chord] : bgin[:L] = bgin[:rho] * bgin[:angle]
  else
    bgin[:angle] = bgin[:L] * bgin[:g]
    bgin[:g] == 0 ? bgin[:L_chord] = bgin[:L] : bgin[:L_chord] = 2 * bgin[:rho] * sin(bgin[:angle]/2) 
  end

  bgin[:g] == 0 ? bgin[:L_sagitta] = 0.0 : bgin[:L_sagitta] = -bgin[:rho] * cos_one(bgin[:angle]/2)

  if ele.L != bgin[:L]
    pdict[:inbox][:LengthGroup] = Dict{Symbol,Any}([:L => bgin[:L]])
    ele_group_bookkeeper!(ele, LengthGroup, changed, previous_ele)
  end

  if haskey(bgin, :e1)
    bgin[:e1_rect] = bgin[:e1] - 0.5 * bgin[:angle]
  elseif haskey(bgin, :e1_rect)
    bgin[:e1] = bgin[:e1_rect] + 0.5 * bgin[:angle]
  elseif bend_type == SBend
    bgin[:e1] = 0.0
    bgin[:e1_rect] = 0.5 * bgin[:angle]
  else
    bgin[:e1] = -0.5 * bgin[:angle]
    bgin[:e1_rect] = 0.0
  end

  if haskey(bgin, :e2)
    bgin[:e2_rect] = bgin[:e2] - 0.5 * bgin[:angle]
  elseif haskey(bgin, :e2_rect)
    bgin[:e2] = bgin[:e2_rect] + 0.5 * bgin[:angle]
  elseif bend_type == SBend
    bgin[:e2] = 0.0
    bgin[:e2_rect] = 0.5 * bgin[:angle]
  else
    bgin[:e2] = -0.5 * bgin[:angle]
    bgin[:e2_rect] = 0.0
  end

  pdict[:BendGroup] = BendGroup(bend_type, bgin[:angle], bgin[:rho], bgin[:g], bgin[:bend_field], 
            bgin[:L_chord], bgin[:L_sagitta], value_of_ele_param(pdict, :BendGroup, :ref_tilt, 0.0), 
            bgin[:e1], bgin[:e2], bgin[:e1_rect], bgin[:e2_rect], 
            value_of_ele_param(pdict, :BendGroup, :fint1, 0.5), value_of_ele_param(pdict, :BendGroup, :fint2, 0.5), 
            value_of_ele_param(pdict, :BendGroup, :hgap1, 0.0), value_of_ele_param(pdict, :BendGroup, :hgap2, 0.0))
  pop!(pdict[:inbox], :BendGroup)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, ...)
# BMultipoleGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  bmin = ele_inbox_group(pdict, :BMultipoleGroup)
  if !haskey(pdict, :BMultipoleGroup); pdict[:BMultipoleGroup] = BMultipoleGroup(); end
  bmnow = pdict[:BMultipoleGroup]
  ff = pdict[:ReferenceGroup].pc_ref / (c_light * charge(pdict[:ReferenceGroup].species_ref))

  # Update existing multipoles if the reference energy has changed.
  if changed.ref_energy
    for (ix, v) in enumerate(bmnow.vec)
      if pdict[:MasterGroup].field_master
        bmnow.vec[ix] = BMultipole1(v.B/ff, v.Bs/ff, v.B, v.Bs, v.tilt, v.order, v.integrated)
      else
        bmnow.vec[ix] = BMultipole1(v.K, v.Ks, v.K*ff, v.Ks*ff, v.tilt, v.order, v.integrated)
      end
    end
  end

  # If there is nothing in the inbox then nothing to be done
  if isnothing(bmin); return; end

  # Transfer parameters from inbox to vin_dict[order][msym] = value where msym is something like :KsL or :Etilt
  # And integrated/not integrated will be put in vin_dict[order][:integrated] = bool or missing.
  vin_dict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in bmin
    mstr, order = multipole_type(p)
    if !haskey(vin_dict, order); vin_dict[order] = Dict{Symbol,Any}(:integrated => missing); end
    v = vin_dict[order]

    if mstr[1] == 'K' || mstr[1] == 'B'
      if mstr[end] == 'L'
        mstr = mstr[1:end-1]
        if !ismissing(v[:integrated]) && v[:integrated] == false
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
        end
        v[:integrated] = true
      else
        if !ismissing(v[:integrated]) && v[:integrated] == true
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
          v[:integrated] = false
        end
      end

      if mstr == "K"
        v[:B] = value * ff
      elseif mstr == "Ks"  
        v[:Bs] = value * ff
      elseif mstr == "B"
        v[:K] = value / ff
      elseif mstr == "Bs"
        v[:Ks] = value / ff
      end
    end

    v[Symbol(mstr)] = value
  end

  # Combine existing multipoles into vin_dict 
  for (ix, vnow) in enumerate(bmnow.vec)
    if vnow.order in keys(vin_dict)
      vin = vin_dict[order]
      if ismissing(vin.integrated); vin[:integrated] = vnow.integrated; end

      if vin[:integrated] && !vnow.integrated
        lf = ele.L
      elseif !vin[:integrated] && vnow.integrated
        lf = 1 / ele.L
      else
        lf = 1
      end

      if !haskey(vin, :K)
        vin[:K] = vnow.K * lf
        vin[:B] = vnow.B * lf
      end

      if !haskey(vin, :Ks)
        vin[:Ks] = vnow.Ks * lf
        vin[:Bs] = vnow.Bs * lf
      end

      if !haskey(vin, :tilt); vin[:tilt] = vnow.tilt; end

    else
      vin_dict[vnow.order] = vnow
    end
  end

  #Transfer vin_dict to pdict[:BMultipoleGroup]
  resize!(bmnow.vec, length(vin_dict))
  for (ix, order) in enumerate(sort(collect(keys(vin_dict))))
    v = vin_dict[order]
    if typeof(vin_dict[order]) == BMultipole1
      bmnow.vec[ix] = v
    else
      if !haskey(v, :K); v[:K] = 0.0; v[:B] = 0.0; end
      if !haskey(v, :Ks); v[:Ks] = 0.0; v[:Bs] = 0.0; end
      if !haskey(v, :tilt); v[:tilt] = 0.0; end
      if ismissing(v[:integrated]); v[:integrated] = false; end
      bmnow.vec[ix] = BMultipole1(v[:K], v[:Ks], v[:B], v[:Bs], v[:tilt], order, v[:integrated])
    end
  end

  pop!(pdict[:inbox], :BMultipoleGroup)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, ...)
# EMultipoleGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  emin = ele_inbox_group(pdict, :EMulitipoleGroup)
  if !haskey(pdict, :EMultipoleGroup); pdict[:EMultipoleGroup] = EMultipoleGroup(); end
  bmnow = pdict[:EMultipoleGroup]

  # If there is nothing in the inbox then nothing to be done
  if isnothing(emin); return; end

  # Transfer parameters from inbox to vin_dict[order][msym] = value where msym is something like :EsL or :Etilt
  # And integrated/not integrated will be put in vin_dict[order][:integrated] = bool or missing.
  vin_dict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in emin
    mstr, order = multipole_type(p)
    if !haskey(vin_dict, order); vin_dict[order] = Dict{Symbol,Any}(:integrated => missing); end
    v = vin_dict[order]

    if mstr[1] == 'E'
      if mstr[end] == 'L'
        mstr = mstr[1:end-1]
        if !ismissing(v[:integrated]) && v[:integrated] == false
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
        end
        v[:integrated] = true
      else
        if !ismissing(v[:integrated]) && v[:integrated] == true
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
          v[:integrated] = false
        end
      end
    end

    v[Symbol(mstr)] = value
  end

  # Combine existing multipoles into vin_dict 
  for (ix, vnow) in enumerate(bmnow.vec)
    if vnow.order in keys(vin_dict)
      vin = vin_dict[order]
      if ismissing(vin.integrated); vin[:integrated] = vnow.integrated; end

      if vin[:integrated] && !vnow.integrated
        lf = ele.L
      elseif !vin[:integrated] && vnow.integrated
        lf = 1 / ele.L
      else
        lf = 1
      end

      if !haskey(vin, :E);  vin[:E]  = vnow.E  * lf; end
      if !haskey(vin, :Es); vin[:Es] = vnow.Es * lf; end
      if !haskey(vin, :tilt); vin[:tilt] = vnow.tilt; end

    else
      vin_dict[vnow.order] = vnow
    end
  end

  #Transfer vin_dict to pdict[:BMultipoleGroup]
  resize!(emnow.vec, length(vin_dict))
  for (ix, order) in enumerate(sort(collect(keys(vin_dict))))
    v = vin_dict[order]
    if typeof(vin_dict[order]) == EMultipole1
      bmnow.vec[ix] = v
    else
      if !haskey(v, :E); v[:E] = 0.0; end
      if !haskey(v, :Es); v[:Es] = 0.0; end
      if !haskey(v, :Etilt); v[:Etilt] = 0.0; end
      if ismissing(v[:integrated]); v[:integrated] = false; end
      bmnow.vec[ix] = EMultipole1(v[:E], v[:Es], v[:tilt], order, v[:integrated])
    end
  end

  pop!(pdict[:inbox], :EMultipoleGroup)
end
