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
  ref_energy::Bool = false
  ref_time:: Bool = false
  floor::Bool = false
end

const AllChanged = ChangedLedger(true, true, true, true, true)

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

Branch bookkeeping. This routine is called by `bookkeeper!(lat::Lat)` and is not meant for general use.
""" bookkeeper!(branch::Branch)

function bookkeeper!(branch::Branch)
  # Set ix_ele and branch pointer for elements.
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix_ele
    ele.pdict[:branch] = branch
  end

  if branch.pdict[:type] == LordBranch; return; end

  # Not a lord branch...
  changed = ChangedLedger()
  previous_ele = nothing

  for (ix, ele) in enumerate(branch.ele)
    bookkeeper!(ele, changed, previous_ele) 
    previous_ele = ele
  end
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Ele)

"""
    Internal: bookkeeper!(ele::Ele, ..., previous_ele::Union{Ele,Nothing})

Ele bookkeeping. For example, propagating the floor geometry from one element to the next. 
These low level routines (there are several with this signature) are called via `bookkeeper!(lat::Lat)` 
and these routines are not meant for general use.

### Output

- `ele`           -- Element to do bookkeeping on.
- `previous_ele`  -- Element in the branch before `ele`. Will be `Nothing` if this is the first branch element.
""" bookkeeper!(ele::Ele)

function bookkeeper!(ele::Ele, changed::ChangedLedger, previous_ele::Union{Ele,Nothing})
  sort_ele_inbox!(ele)
  for group in ele_param_groups[typeof(ele)]
    ele_group_bookkeeper!(ele, group, changed, previous_ele)
  end
end

#---------------------------------------------------------------------------------------------------
# index_bookkeeper!(Branch)

"""
    Internal: function index_bookkeeper!(branch::Branch)

Does Element index and s-position bookkeeping for a given branch.
""" index_bookkeeper!

function index_bookkeeper!(branch::Branch)
  ele1 = branch.ele[1]
  if haskey(ele1.inbox, :s)
    s_old = pop!(ele1.inbox, :s)
    ele1.pdict[:LengthGroup] = LengthGroup(0.0_rp, s_old, s_old)
  else
    s_old = ele1.s_exit
  end

  for (ix, ele) in enumerate(branch.ele)
    ele.ix_ele = ix
    if branch.type == LordBranch; continue; end
    if ix == 1; continue; end
    haskey(ele.inbox, :L) ? len = pop!(ele.inbox, :L) : len = ele.L
    ele1.pdict[:LengthGroup] = LengthGroup(len, s_old, s_old+len)
    s_old = s_old + len
  end
end

#---------------------------------------------------------------------------------------------------
# sort_ele_inbox!

"""
  Internal: sort_ele_inbox!(ele::Union{Ele,Nothing})

Move parameters in `ele.param[:inbox]` such that the value at `ele.param[:inbox][:XXX]` is transfered 
to `ele.param[:inbox][:GGG][:XXX]` where `GGG` is the element parameter group for `XXX` and `ele.param[:inbox][:GGG]`
is a Dict (not an instance of the parameter group).

This is a Low level routine used by `bookkeeper!(lat::Lat)`. Not meant for general use.
""" sort_ele_inbox!

function sort_ele_inbox!(ele::Union{Ele,Nothing})
  if isnothing(ele); return; end

  pdict = ele.pdict
  if !haskey(pdict, :inbox); return; end
  inbox = pdict[:inbox]

  for sym in copy(keys(inbox))  # Need copy since keys will be added to inbox.
    # In theory, the inbox should originally not contain any parameter group keys. However, if there has been
    # a problem, there might be some such keys so just ignore.
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
  Internal: function ele_inbox_group
""" ele_inbox_group

function ele_inbox_group(pdict, group::Symbol)
  if !haskey(pdict, :inbox) || !haskey(pdict[:inbox], group); return nothing; end
  return pdict[:inbox][group]
end

#---------------------------------------------------------------------------------------------------
# update_ele_group!

"""
  Internal: update_ele_group!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

Updates an element parameter group at `ele.param[:group]` with changed parameters from `ele.param[:inbox][:group]`.

""" update_ele_group!

function update_ele_group!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  pdict = ele.pdict
  sg = Symbol(group)
  gin = inbox(pdict, sg)
  if isnothing(gin); return; end

  if haskey(pdict, sg)
    g = Dict(k => getfield(gin, k) for k in fieldnames(group))
    g = merge(g, gin)
  else
    g = gin
  end

  eval( :(pdict[sg] = $(group)(; g)) )
  pop!(pdict[:inbox], sg)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, ...)
# Low level LengthGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, changed::ChangedLedger, previous_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  lgin = ele_inbox_group(pdict, :LengthGroup)
  if !changed.s_position && isnothing(lgin); return; end

  if isnothing(previous_ele)
    s = 0
    if !isnothing(lgin) && haskey(lgin, :s)
      s = lgin[:s]
    elseif haskey(pdict, :LengthGroup)
      s = pdict[:LengthGroup].s
    end
  else
    s = previous_ele.s_exit
  endif

  L = 0
  if !isnothing(lgin) && haskey(lgin, :L)
    L = lgin[:L]
    changed.this_ele_length = true
  elseif haskey(pdict, :LengthGroup)
    L = pdict[:LengthGroup].L
    changed.this_ele_length = false
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

function ele_group_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, changed::ChangedLedger, previous_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  rgin = ele_inbox_group(pdict, :ReferenceGroup)
  haskey(pdict, :ReferenceGroup) ? rgnow = pdict[:ReferenceGroup] : rgnow = nothing
  
  if !changed.this_ele_length && !changed.ref_energy && !isnothing(rgin); return; end
  changed.ref_energy = true

  if isnothing(previous_ele)   # implies BeginningEle
    # rgin must exist in this case
    if isnothing(rgin) && isnothing(rgnow)
      error(f"Reference parameters not set for element: {ele_name(ele)}")
    end

    if !haskey(rgin, :species_ref)
      if isnothing(rgnow) ? error(f"Species not set for: {ele_name(ele)}") : rgin[:species_ref] = rgnow[:species_ref]
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
      rgin[:E_tot_ref] = E_tot_from_pc(rgin[:pc_ref], rgin.species_ref)
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
  species_exit = species

  L = pdict[:LengthGroup].L
  dt = L * pc / E_tot

  pdict[:ReferenceGroup] = ReferenceGroup(pc_ref = pc, pc_ref_exit = pc,
                       E_tot_ref = E_tot, E_tot_ref_exit = E_tot, time_ref = time, time_ref_exit = time+dt, 
                       species_ref = species, species_exit = species_exit)
  if !isnothing(rgin)
    pop!(pdict[:inbox], :ReferenceGroup)
    error(f"ReferenceGroup parameters cannot be set for this element: {ele_name(ele)}")
  end
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, ...)
# FloorPositionGroup bookkeeper

function ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, changed::ChangedLedger, previous_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  fpin = ele_inbox_group(pdict, :FloorPositionGroup)
  if !changed.this_ele_length && !changed.floor && isnothing(fpin); return; end

  changed.floor = true
  pdict[:FloorPositionGroup] = propagate_ele_geometry(previous_ele.FloorPositionGroup, previous_ele)
  if haskey(inbox, :FloorPositionGroup); pop!(inbox, :FloorPositionGroup); end
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{T}, ...)
# Bookkeeping for everything else not covered by a specific function.

function ele_group_bookkeeper!(ele::Ele, group::Type{T}, changed::ChangedLedger, 
                                      previous_ele::Union{Ele,Nothing}) where T <: EleParameterGroup
  update_ele_group!(ele, group)
end

###+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, ...)
# BendGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, changed::ChangedLedger, previous_ele::Ele)
  pdict = ele.pdict
  bgin = ele_inbox_group(pdict, :BendGroup)
  L = pdict[:LengthGroup].L

  if !isnothing(bgin)
    pdict[:LengthGroup] = BendGroup(L_chord = L)
    return
  end

  bg = pdict[:inbox][:BendGroup]
  bg[:L] = L
  if L != 0; param_conflict_check(ele, bg, :L, :L_chord); end
  param_conflict_check(ele, bg, :bend_field, :g, :rho, :angle)
  param_conflict_check(ele, bg, :e1, :e1_rect)
  param_conflict_check(ele, bg, :e2, :e2_rect)

  if haskey(bg, :bend_type)
    bend_type = bf[:bend_type]
  elseif haskey(bg, :L_chord) || haskey(bg, :e1_rect) || haskey(bg, :e2_rect)
    bend_type = RBend
  else
    bend_type = SBend
  end

  if haskey(bg, :L_chord); L_chord::Float64 = bg[:L_chord]; end

  if haskey(bg, :bend_field)
    bend_field::Float64 = bg[:bend_field]
    g = bend_field * charge(pdict[:ReferenceGroup].species_ref) * c_light / pdict[:ReferenceGroup].pc_ref
    g = 0 ? rho = Inf : rho = 1 / g
  elseif haskey(bg, :rho)
    rho::Float64
    g = 1.0 / rho
  elseif haskey(bg, :angle)
    angle::Float64 = bg[:angle]
    if haskey(bg, :L_chord)
      if L_chord == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
      angle == 0 ? g = 0.0 : g = 2.0 * sin(angle/2) / L_chord
    else
      if L == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele_name(ele)}"); end
      angle == 0 ? g = 0 : g = angle / L
    end
  elseif haskey(bg, :g)
    g = bg[:g]
  end

  bend_field = g * pdict[:ReferenceGroup].pc_ref / (c_light * charge(pdict[:ReferenceGroup].species_ref))
  g == 0 ? rho = Inf : rho = 1.0 / g
  if haskey(bg, :L_chord)
    angle = 2 * asin(L_chord * g / 2)
    g = 0 ? L =  L_chord : L = rho * angle
  else
    angle = L * g
    g = 0 ? L_chord = L : L_chord = 2 * rho * sin(angle/2) 
  end

  g = 0 ? L_sagitta = 0.0 : L_sagitta = -rho * cos_one(angle/2)

  if haskey[bg, :e1]
    e1::Float64 = bg[:e1]
    e1_rect = e1 - 0.5 * angle
  elseif haskey[bg, :e1_rect]
    e1_rect::Float64 = bg[:e1_rect]
    e1 = e1_rect + 0.5 * angle
  elseif bend_type == SBend
    e1 = 0.0
    e1_rect = 0.5 * angle
  else
    e1 = -0.5 * angle
    e1_rect = 0.0
  end

  if haskey(bg, :e2)
    e2::Float64 = bg[:e2]
    e2_rect = e2 - 0.5 * angle
  elseif haskey(bg, :e2_rect)
    e2_rect::Float64 = bg[:e2_rect]
    e2 = e2_rect + 0.5 * angle
  elseif bend_type == SBend
    e2 = 0.0
    e2_rect = 0.5 * angle
  else
    e2 = -0.5 * angle
    e2_rect = 0.0
  end

  pdict[:BendGroup] = BendGroup(angle, rho, g, bend_field, L_chord, L_sagitta, 
            get(bg, :ref_tilt, 0.0), e1, e2, e1_rect, e2_rect, get(bg, :fint1, 0.5),
            get(bg, :fint2, 0.5), get(bg, :hgap1, 0.5))
  pop!(pdict[:inbox], :BendGroup)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, ...)
# BMultipoleGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, previous_ele::Ele)
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if !haskey(inbox, :BMultipoleGroup); return; end

  vdict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in inbox[:BMultipoleGroup]
    mstr, order = multipole_type(p)
    haskey(vdict, order) ? push!(vdict[order], Symbol(mstr) => value) : vdict[order] = Dict{Symbol,Any}(Symbol(mstr) => value) 
  end

  for (order, v1) in vdict
    integrated = NotSet
    for msym in copy(keys(v1))  # copy since keys are modified in loop.
      mstr = String(msym)
      if mstr[1] == 'K' || mstr[1] == 'B'
        if integrated == NotSet; integrated = occursin("L", mstr); end
        if integrated != occursin("L", mstr)
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
        end
        if integrated
          msym2 = Symbol(replace(mstr, "L" => ""))
          v1[msym2] = pop!(v1, msym)
        end
      end
    end
    v1[:integrated] = integrated
    v1[:order] = order
  end

  f = pdict[:ReferenceGroup].pc_ref / (c_light * charge(pdict[:ReferenceGroup].species_ref))
  vec = Vector{BMultipole1}()
  for order in sort(collect(keys(vdict)))
    v1 = vdict[order]  
 
    if haskey(v1, :K) && haskey(v1, :B)
      error(f"Combining K and B multipoles for a given order not permitted: {ele_name(ele)}")
    elseif haskey(v1, :K)
      v1[:B] = v1[:K] * f
    elseif haskey(v1, :B)
      v1[:K] = v1[:B] / f
    else
      v1[:K] = 0.0; v1[:B] = 0.0
    end

    if :Ks in keys(v1) && :Bs in keys(v1)
      error(f"Combining Ks and Bs multipoles for a given order not permitted: {ele_name(ele)}")
    elseif haskey(v1, :Ks)
      v1[:Bs] = v1[:Ks] * f
    elseif haskey(v1, :Bs)
      v1[:Ks] = v1[:Bs] / f
    else
      v1[:Ks] = 0.0; v1[:Bs] = 0.0
    end

    push!(vec, BMultipole1(; v1...))
  end

  pdict[:BMultipoleGroup] = BMultipoleGroup(vec)
  pop!(inbox, :BMultipoleGroup)
end

#---------------------------------------------------------------------------------------------------
# ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, ...)
# EMultipoleGroup bookkeeping.

function ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, previous_ele::Ele)
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if !haskey(inbox, :EMultipoleGroup); return; end

  vdict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in inbox[:EMultipoleGroup]
    mstr, order = multipole_type(p)
    haskey(vdict, order) ? push!(vdict[order], Symbol(mstr) => value) : 
                             vdict[order] = Dict{Symbol,Any}(Symbol(mstr) => value) 
  end

  for (order, v1) in vdict
    integrated = NotSet
    for msym in copy(keys(v1))  # copy since keys are modified in loop.
      mstr = String(msym)
      if mstr[1] == 'E' && mstr != "Etilt"
        if integrated == NotSet; integrated = occursin("L", mstr); end
        if integrated != occursin("L", mstr)
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele_name(ele)}")
        end
        if integrated
          msym2 = Symbol(replace(mstr, "L" => ""))
          v1[msym2] = pop!(v1, msym)
        end
      end
    end
    v1[:integrated] = integrated
    v1[:order] = order
  end

  f = pdict[:ReferenceGroup].pc_ref / (c_light * charge(pdict[:ReferenceGroup].species_ref))
  vec = Vector{EMultipole1}()
  for order in sort(collect(keys(vdict)))
    v1 = vdict[order]  
    if !haskey(v1, :E); v1[:E] = 0.0; end
    if !haskey(v1, :Es); v1[:Es] = 0.0; end
    push!(vec, EMultipole1(; v1...))
  end

  pdict[:EMultipoleGroup] = EMulitipoleGroup(vec)
  pop!(inbox, :EMultipoleGroup)
end
end
end

