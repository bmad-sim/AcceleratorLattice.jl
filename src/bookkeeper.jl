#---------------------------------------------------------------------------------------------------
# init_bookkeeper!(Lat, superimpose)

"""
    init_bookkeeper!(lat::Lat, superimpose::Vector{T}) where T <: Ele
    init_bookkeeper!(branch::Branch, superimpose::Vector{T}) where T <: Ele
    init_bookkeeper!(ele::Ele, old_ele::Union{Ele,Nothing})

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

  old_ele = nothing
  for ele in branch.ele
    init_bookkeeper!(ele, old_ele)
    old_ele = ele
  end

  for ele in superimpose
    superimpose_branch!(branch, ele)
  end
end

#---------------------------------------------------------------------------------------------------
# init_bookkeeper!(Ele, old_ele)

function init_bookkeeper!(ele::Ele, old_ele::Union{Ele,Nothing})
  sort_ele_inbox!(ele)
  for group in ele_param_groups[typeof(ele)]
    init_ele_group_bookkeeper!(ele, group, old_ele)
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

  for (ix, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix
    ele.pdict[:branch] = branch
    init_ele_bookkeeper!(ele)
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
        append!(loc, LatEleLocation.(ele_finder(lat, ele_id)))
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
  # Sort slaves
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
# init_ele_group_from_inbox!

"""
    init_ele_group_from_inbox!(ele::Ele, group::Type{T}) where T <: EleParameterGroup

Transfers parameters from `inbox` dict to a particular element `group`.

""" init_ele_group!

function init_ele_group_from_inbox!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  gsym = Symbol(group)
  pdict = ele.pdict
  inbox = pdict[:inbox]
  if !haskey(pdict[:inbox], gsym)
    pdict[gsym] = eval(Meta.parse("$group()"))
    return
  end

  input = pdict[:inbox][gsym]
  gdict = Dict{Symbol, Any}()

  # Load gdict with symbols in ele.pdict[:input]
  for field in fieldnames(group)
    if !haskey(input, field); continue; end
    gdict[field] = input[field]
  end
  pop!(pdict[:inbox], gsym)

  str = ""
  for (field, value) in gdict
    str = str * ", $field = $(repr(value))"  # Need repr() for string fields
  end

  # Take advantage of the fact that the group has been defined using @kwargs.
  pdict[gsym] = eval(Meta.parse("$group($(str[3:end]))"))
  
end

#---------------------------------------------------------------------------------------------------
# init_ele_group_bookkeeper!

"""
    init_ele_group_bookkeeper!(ele::Ele, group::Type{T}, old_ele::Union{Ele,Nothing}) where T <: EleParameterGroup

""" init_ele_group_bookkeeper!

function init_ele_group_bookkeeper!(ele::Ele, group::Type{T}, old_ele::Union{Ele,Nothing}) where T <: EleParameterGroup
  init_ele_group_from_inbox!(ele, group)
end

#---------------------------------------------------------------------------------------------------
"""
"""

function init_ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  isnothing(old_ele) ? s = 0.0 : s = old_ele.pdict[:LengthGroup].s_exit

  if haskey(inbox, :LengthGroup) 
    L::Float64 = get(inbox[:LengthGroup], :L, 0.0)
    pop!(pdict[:inbox], :LengthGroup)
  else
    L = 0.0
  end

  pdict[:LengthGroup] = LengthGroup(L = L, s = s, s_exit = s+L)
end

#---------------------------------------------------------------------------------------------------
"""
If there is a reference energy change (LCavity), this will be handled when bookkeeping of the RFGroup is done.
"""
function init_ele_group_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  haskey(pdict, :branch) ? branch_name = pdict[:branch].name : branch_name = "No-Associated-Branch"

  # BeginningEle bookkeeping
  if isnothing(old_ele)
    if !haskey(inbox, :ReferenceGroup); error(f"species_ref parameter not set for branch: {branch_name}"); end
    rg = inbox[:ReferenceGroup]
    if !haskey(rg, :species_ref); error(f"Species not set in branch: {branch_name}"); end

    if haskey(rg, :pc_ref) && haskey(rg, :E_tot_ref)
      error(f"Beginning element has both pc_ref and E_tot_ref set in branch: {branch_name}")
    elseif !haskey(rg, :pc_ref) && !haskey(rg, :E_tot_ref)
      error(f"pc_ref and E_tot_ref not set for beginning element in branch: {branch_name}")
    elseif haskey(rg, :pc_ref)
      pc = rg[:pc_ref]
      E_tot = E_tot_from_pc(pc, rg[:species_ref])
    else
      E_tot = rg[:E_tot_ref]
      pc = pc_from_E_tot(E_tot, rg[:species_ref])
    end
    haskey(rg, :time_ref) ? time = rg[:time_ref] : time = 0.0
    species = rg[:species_ref]
    species_exit = species
    pop!(inbox, :ReferenceGroup)

  # Not BeginningEle
  else
    if haskey(pdict, :ReferenceGroup); error(f"ReferenceGroup parameters should not be in inbox! for: {ele.name}"); end
    old_rg = old_ele.pdict[:ReferenceGroup]
    pc           = old_rg.pc_ref_exit
    E_tot        = old_rg.E_tot_ref_exit
    time         = old_rg.time_ref_exit
    species      = old_rg.species_ref_exit
    species_exit = old_rg.species_ref_exit
  end

  L = pdict[:LengthGroup].L
  dt = L * pc / E_tot

  ele.ReferenceGroup = ReferenceGroup(pc_ref = pc, pc_ref_exit = pc,
              E_tot_ref = E_tot, E_tot_ref_exit = E_tot, time_ref = time, time_ref_exit = time+dt, 
              species_ref = species, species_ref_exit = species_exit)
end

#---------------------------------------------------------------------------------------------------
"""
"""

function init_ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, old_ele::Ele)
  pdict = ele.pdict
  L = pdict[:LengthGroup].L

  if !haskey(pdict[:inbox], :BendGroup)
    pdict[:BendGroup] = BendGroup(L_chord = L)
    return
  end

  bg = pdict[:inbox][:BendGroup]
  bg[:L] = L
  if L != 0; param_conflict_check(ele, bg, :L, :L_chord); end
  param_conflict_check(ele, bg, :bend_field, :g, :rho, :angle)
  param_conflict_check(ele, bg, :e1, :e1_rect)
  param_conflict_check(ele, bg, :e2, :e2_rect)

  if !haskey(bg, :bend_type) && (haskey(bg, :L_chord) || haskey(bg, :e1_rect) || haskey(bg, :e2_rect))
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
      if L_chord == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele.name}"); end
      angle == 0 ? g = 0.0 : g = 2.0 * sin(angle/2) / L_chord
    else
      if L == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele.name}"); end
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

  pdict[:BendGroup] = BendGroup(angle, rho, g, bend_field, L_chord, L_sagitta, 
            get(bg, :ref_tilt, 0.0), e1, e2, e1_rect, e2_rect, get(bg, :fint1, 0.5),
            get(bg, :fint2, 0.5), get(bg, :hgap1, 0.5))
  pop!(pdict[:inbox], :BendGroup)
end

#---------------------------------------------------------------------------------------------------
"""
"""

function init_ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, old_ele::Ele)
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
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele.name}")
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
      error(f"Combining K and B multipoles for a given order not permitted: {ele.name}")
    elseif haskey(v1, :K)
      v1[:B] = v1[:K] * f
    elseif haskey(v1, :B)
      v1[:K] = v1[:B] / f
    else
      v1[:K] = 0.0; v1[:B] = 0.0
    end

    if :Ks in keys(v1) && :Bs in keys(v1)
      error(f"Combining Ks and Bs multipoles for a given order not permitted: {ele.name}")
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
"""
"""
function init_ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, old_ele::Ele)
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if !haskey(inbox, :EMultipoleGroup); return; end

  vdict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in inbox[:EMultipoleGroup]
    mstr, order = multipole_type(p)
    haskey(vdict, order) ? push!(vdict[order], Symbol(mstr) => value) : vdict[order] = Dict{Symbol,Any}(Symbol(mstr) => value) 
  end

  for (order, v1) in vdict
    integrated = NotSet
    for msym in copy(keys(v1))  # copy since keys are modified in loop.
      mstr = String(msym)
      if mstr[1] == 'E' && mstr != "Etilt"
        if integrated == NotSet; integrated = occursin("L", mstr); end
        if integrated != occursin("L", mstr)
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele.name}")
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

#---------------------------------------------------------------------------------------------------

"""
"""
function init_ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if isnothing(old_ele)
    init_ele_group_from_inbox!(ele, FloorPositionGroup)
    fpg = Dict(k => getfield(pdict[:FloorPositionGroup], k) for k in fieldnames(FloorPositionGroup))
    fpg[:q_floor] = QuatRotation(fpg[:theta], fpg[:phi], fpg[:psi])
    pdict[:FloorPositionGroup] = FloorPositionGroup(; fpg...)
  else
    if haskey(inbox,:FloorPositionGroup); error(f"Setting floor position parameters not allowed in {ele.name}"); end
    pdict[:FloorPositionGroup] = propagate_ele_geometry(old_ele.FloorPositionGroup, old_ele)
  end
end

#---------------------------------------------------------------------------------------------------
# sort_ele_inbox!

"""

"""
function sort_ele_inbox!(ele::Union{Ele,Nothing})
  if isnothing(ele); return; end

  pdict = ele.pdict
  inbox = pdict[:inbox]

  for sym in copy(keys(inbox))
    pinfo = ele_param_info(sym, no_info_return = nothing)
    if isnothing(pinfo); error(f"No information on: {sym}."); end
    parent = Symbol(parent_group(pinfo, ele))
    if !haskey(inbox, parent); inbox[parent] = Dict{Symbol,Any}(); end

    # Check if parmeter value in inbox is different from value in group.
    # This may happen with vectors since something like "q1.r_floor = [...]" does not get processed
    # by `Base.setproperty!(ele::T, s::Symbol, value) where T <: Ele`.
    if haskey(pdict, parent) && hasfield(pdict[parent], param) && inbox[sym] == getfield(pdict[parent], sym)
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
# change struct

"""
When bookkeeping a branch, element-by-element, starting from the beginning of the branch,
the ledger keeps track of what has changed so that the change can propagate to the 
following elements. 

Ledger parameters, when toggled to true, will never be reset for the remainder of the branch bookkeeping.
The exception is the `this_ele_length` parameter which is reset for each element.
"""
@kwdef mutable struct ChangedLedger
  this_ele_length::Bool = false
  s_position::Bool = false
  ref_energy::Bool = false
  ref_time:: Bool = false
  floor::Bool = false
end  

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# bookkeeper!(Lat)

function bookkeeper!(lat::Lat)
  

  for (ix, branch) in enumerate(lat.branch)
    branch.pdict[:ix_branch] = ix
    bookkeeper!(branch)
  end
  # Put stuff like ref energy in lords
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Branch)

function bookkeeper!(branch::Branch)
  # Set ix_ele and branch pointer for elements.
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.pdict[:ix_ele] = ix_ele
    ele.pdict[:branch] = branch
  end

  if branch.pdict[:type] == LordBranch; return; end

  # Not a lord branch...
  changed = ChangedLedger()
  old_ele = nothing

  for (ix, ele) in enumerate(branch.ele)
    bookkeeper!(ele, changed, old_ele) 
    old_ele = ele
  end
end

#---------------------------------------------------------------------------------------------------
# bookkeeper!(Ele)

function bookkeeper!(ele::Ele, changed::ChangedLedger, old_ele::Union{Ele,Nothing})
  sort_ele_inbox!(ele)
  for group in ele_param_groups[typeof(ele)]
    bookkeeper!(ele, group, changed, old_ele)
  end
end

"""
  LengthGroup
"""
function bookkeeper!(ele::Ele, group::Type{LengthGroup}, changed::ChangedLedger, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  if !changed.s_position && !haskey(inbox, :LengthGroup); return; end

  isnothing(old_ele) ? s = pdict[:LengthGroup].s : s = old_ele.s_exit

  if haskey(inbox, :LengthGroup)
    L = inbox[:LengthGroup][:L]
    changed.this_ele_length = true
    pop!(inbox, :LengthGroup)
  else
    L = pdict[:LengthGroup].L
    changed.this_ele_length = false
  end

  pdict[:LengthGroup] = LengthGroup(L, s, s + L)
  changed.s_position = true
end


#---------------------------------------------------------------------------------------------------
"""
  ReferenceGroup

Note: RF reference bookkeeping, which is complicated and needs information from other structures, 
is handled by the RFGroup bookkeeping code. So this routine simply ignores this complication.
"""
function bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, changed::ChangedLedger, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  if !changed.this_ele_length && !changed.ref_energy && !haskey(inbox, :ReferenceGroup); return; end
  changed.ref_energy = true

  if isnothing(old_ele)   # implies BeginningEle
    rg = pdict[:ReferenceGroup]
    rgin = inbox[:ReferenceGroup]
    if !haskey(rgin, :species_ref); rgin[:species_ref] = rg.species_ref; end
    if !haskey(rgin, :time_ref); rgin[:time] = rg.time_ref; end

    if haskey(rgin, :pc_ref) && haskey(rgin, :E_tot_ref)
      error(f"Beginning element has both pc_ref and E_tot_ref set in {ele.name}")
    elseif haskey(rgin, :E_tot_ref)
      rgin[:pc_ref] = pc_from_E_tot(rgin[:E_tot_ref], rgin[:species_ref])
    elseif  haskey(rgin, :pc_ref)
      rgin[:E_tot_ref] = E_tot_from_pc(rgin[:pc_ref], rgin.species_ref)
    else
      rgin[:E_tot_ref] = rg.E_tot_ref
      rgin[:pc_ref] = rg.pc_ref
    end

    rgin[:pc_ref_exit] = rgin[:pc_ref]
    rgin[:E_tot_ref_exit] = rgin[:E_tot_ref]
    rgin[:time_ref_exit] = rgin[:time_ref]
    rgin[:species_ref_exit] = rgin[:species_ref]

    pdict[:ReferenceGroup] = ReferenceGroup(; rgin...)
    pop!(inbox, :ReferenceGroup)
  end

  # Has old_ele case
  if haskey(pdict, :ReferenceGroup); error(f"ReferenceGroup parameters should not be in inbox! for: {ele.name}"); end
  old_rg = old_ele.pdict[:ReferenceGroup]
  pc = old_rg.pc_ref_exit
  E_tot = old_rg.E_tot_ref_exit
  time    = old_rg.time_ref_exit
  species = old_rg.species_ref_exit
  species_exit = species

  L = pdict[:LengthGroup].L
  dt = L * pc / E_tot

  ele.ReferenceGroup = ReferenceGroup(pc_ref = pc, pc_ref_exit = pc,
                       E_tot_ref = E_tot, E_tot_ref_exit = E_tot, time_ref = time, time_ref_exit = time+dt, 
                       species_ref = species, species_exit = species_exit)
end

#---------------------------------------------------------------------------------------------------

"""
  FloorPositionGroup
"""
function bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, changed::ChangedLedger, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  if !changed.this_ele_length && !changed.floor && !haskey(inbox, :FloorPositionGroup); return; end

  changed.floor = true
  pdict[:FloorPositionGroup] = propagate_ele_geometry(old_ele.FloorPositionGroup, old_ele)
  if haskey(inbox, :FloorPositionGroup); pop!(inbox, :FloorPositionGroup); end
end

#---------------------------------------------------------------------------------------------------

"""
Everything else not covered by a specific function.
"""
function bookkeeper!(ele::Ele, group::Type{T}, changed::ChangedLedger, old_ele::Union{Ele,Nothing}) where T <: EleParameterGroup
  update_ele_group!(ele, group)
end

#---------------------------------------------------------------------------------------------------

function update_ele_group!(ele::Ele, group::Type{T}) where T <: EleParameterGroup
  pdict = ele.pdict
  inbox = pdict[:inbox]
  gs = Symbol(group)
  if !haskey(inbox, gs); return; end

  if haskey(pdict, gs)
    g = Dict(k => getfield(inbox[gs], k) for k in fieldnames(group))
    g = merge(g, inbox[gs])
  else
    g = inbox[gs]
  end

  eval( :(pdict[gs] = $(group)(; g)) )
  pop!(inbox, gs)
end


"""
"""
function ele_group_bookkeeper!(ele::Ele, group::Type{LengthGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  if !haskey(pdict[:inbox], :LengthGroup)
    pdict[:LengthGroup] = LengthGroup()
 
  else
    lg = pdict[:inbox][:LengthGroup]
    s = get(lg, :s, 0.0)
    pdict[:LengthGroup] = LengthGroup(L = 0.0, s = s, s_exit = s)
    pop!(pdict[:inbox], :LengthGroup)
  end
end

#---------------------------------------------------------------------------------------------------

"""
If there is a reference energy change (LCavity), this will be handled when bookkeeping of the RFGroup is done.
"""
function ele_group_bookkeeper!(ele::Ele, group::Type{ReferenceGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]
  haskey(pdict, :branch) ? branch_name = pdict[:branch].name : branch_name = "No-Associated-Branch"

  # BeginningEle bookkeeping
  if isnothing(old_ele)
    if !haskey(inbox, :ReferenceGroup); error(f"species_ref not set for branch: {branch_name}"); end
    rg = inbox[:ReferenceGroup]
    if !haskey(rg, :species_ref); error(f"Species not set in branch: {branch_name}"); end

    if haskey(rg, :pc_ref) && haskey(rg, :E_tot_ref)
      error(f"Beginning element has both pc_ref and E_tot_ref set in branch: {branch_name}")
    elseif !haskey(rg, :pc_ref) && !haskey(rg, :E_tot_ref)
      error(f"pc_ref and E_tot_ref not set for beginning element in branch: {branch_name}")
    elseif haskey(rg, :pc_ref)
      pc = rg[:pc_ref]
      E_tot = E_tot_from_pc(pc, rg[:species_ref])
    else
      E_tot = rg[:E_tot_ref]
      pc = pc_from_E_tot(E_tot, rg[:species_ref])
    end
    haskey(rg, :time_ref) ? time = rg[:time_ref] : time = 0.0
    species = rg[:species_ref]
    pop!(inbox, :ReferenceGroup)

  # Not BeginningEle
  else
    if haskey(pdict, :ReferenceGroup); error(f"ReferenceGroup parameters should not be in inbox! for: {ele.name}"); end
    old_rg = old_ele.pdict[:ReferenceGroup]
    pc      = old_rg.pc_ref_exit
    E_tot   = old_rg.E_tot_ref_exit
    time    = old_rg.time_ref_exit
    species = old_rg.species_ref
  end

  L = pdict[:LengthGroup].L
  dt = L * pc / E_tot

  ele.ReferenceGroup = ReferenceGroup(pc_ref = pc, pc_ref_exit = pc,
                       E_tot_ref = E_tot, E_tot_ref_exit = E_tot,
                       time_ref = time, time_ref_exit = time+dt, species_ref = species)
end

#---------------------------------------------------------------------------------------------------

"""
"""

function ele_group_bookkeeper!(ele::Ele, group::Type{BendGroup}, old_ele::Ele)
  pdict = ele.pdict
  L = pdict[:LengthGroup].L

  if !haskey(pdict[:inbox], :BendGroup)
    pdict[:LengthGroup] = BendGroup(L_chord = L)
    return
  end

  bg = pdict[:inbox][:BendGroup]
  bg[:L] = L
  if L != 0; param_conflict_check(ele, bg, :L, :L_chord); end
  param_conflict_check(ele, bg, :bend_field, :g, :rho, :angle)
  param_conflict_check(ele, bg, :e1, :e1_rect)
  param_conflict_check(ele, bg, :e2, :e2_rect)

  if !haskey(bg, :bend_type) && (haskey(bg, :L_chord) || haskey(bg, :e1_rect) || haskey(bg, :e2_rect))
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
      if L_chord == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele.name}"); end
      angle == 0 ? g = 0.0 : g = 2.0 * sin(angle/2) / L_chord
    else
      if L == 0 && angle != 0; error(f"Bend cannot have finite angle and zero length: {ele.name}"); end
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

  pdict[:BendGroup] = BendGroup(angle, rho, g, bend_field, L_chord, L_sagitta, 
            get(bg, :ref_tilt, 0.0), e1, e2, e1_rect, e2_rect, get(bg, :fint1, 0.5),
            get(bg, :fint2, 0.5), get(bg, :hgap1, 0.5))
  pop!(pdict[:inbox], :BendGroup)
end

#---------------------------------------------------------------------------------------------------

"""
"""

function ele_group_bookkeeper!(ele::Ele, group::Type{BMultipoleGroup}, old_ele::Ele)
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
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele.name}")
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
      error(f"Combining K and B multipoles for a given order not permitted: {ele.name}")
    elseif haskey(v1, :K)
      v1[:B] = v1[:K] * f
    elseif haskey(v1, :B)
      v1[:K] = v1[:B] / f
    else
      v1[:K] = 0.0; v1[:B] = 0.0
    end

    if :Ks in keys(v1) && :Bs in keys(v1)
      error(f"Combining Ks and Bs multipoles for a given order not permitted: {ele.name}")
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

"""
"""
function ele_group_bookkeeper!(ele::Ele, group::Type{EMultipoleGroup}, old_ele::Ele)
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if !haskey(inbox, :EMultipoleGroup); return; end

  vdict = Dict{Int,Dict{Symbol,Any}}()
  for (p, value) in inbox[:EMultipoleGroup]
    mstr, order = multipole_type(p)
    haskey(vdict, order) ? push!(vdict[order], Symbol(mstr) => value) : vdict[order] = Dict{Symbol,Any}(Symbol(mstr) => value) 
  end

  for (order, v1) in vdict
    integrated = NotSet
    for msym in copy(keys(v1))  # copy since keys are modified in loop.
      mstr = String(msym)
      if mstr[1] == 'E' && mstr != "Etilt"
        if integrated == NotSet; integrated = occursin("L", mstr); end
        if integrated != occursin("L", mstr)
          error(f"Combining integrated and non-integrated multipole values for a given order not permitted: {ele.name}")
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

#---------------------------------------------------------------------------------------------------

"""
"""
function ele_group_bookkeeper!(ele::Ele, group::Type{FloorPositionGroup}, old_ele::Union{Ele,Nothing})
  pdict = ele.pdict
  inbox = pdict[:inbox]

  if isnothing(old_ele)
    ele_group_from_inbox!(ele, FloorPositionGroup)
    fpg = Dict(k => getfield(pdict[:FloorPositionGroup], k) for k in fieldnames(FloorPositionGroup))
    fpg[:q_floor] = QuatRotation(fpg[:theta], fpg[:phi], fpg[:psi])
    pdict[:FloorPositionGroup] = FloorPositionGroup(; fpg...)
  else
    if haskey(inbox,:FloorPositionGroup); error(f"Setting floor position parameters not allowed in {ele.name}"); end
    pdict[:FloorPositionGroup] = propagate_ele_geometry(old_ele.FloorPositionGroup, old_ele)
  end
end
