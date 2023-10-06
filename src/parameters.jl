"""
Dictionaries of parameters defined in a lattice
"""

#---------------------------------------------------------------------------------------------------
# multipole_type

"""
`type` will be "K", "Kl", "Ks" "Ksl", "B", "Bl", "Bs", "Bsl", "tilt", "E", "El", "Es", "Esl", "Etilt"

  `str` can be symbol.
"""

function multipole_type(str::Union{AbstractString,Symbol})
  if str isa Symbol; str = string(str); end
  if length(str) < 2 || !any(str[1] .== ['K', 'B', 'E', 't']); return (nothing, -1); end

  if length(str) > 4 && str[1:4] == "tilt"
    order = tryparse(UInt64, str[5:end]) 
    order == nothing ? (return nothing, -1) : (return "tilt", Int64(order))
  elseif length(str) > 5 && str[1:5] == "Etilt"
    order = tryparse(UInt64, str[6:end]) 
    order == nothing ? (return nothing, -1) : (return "Etilt", Int64(order))
  end

  if str[end-1:end] == "sl"
    out_str = str[1] * str[end-1:end]
    str = str[2:end-2]
  elseif str[end] == 'l'
    out_str = str[1] * str[end]
    str = str[2:end-1]
  elseif str[end] == 's'
    out_str = str[1] * str[end]
    str = str[2:end-1]
  else
    out_str = str[1:1]
    str = str[2:end]
  end

  order = tryparse(UInt64, str) 
  order == nothing ? (return nothing, -1) : (return out_str, Int64(order))
end

#---------------------------------------------------------------------------------------------------
# ele_param_info

"""
Returns param_info or `default`.
If the value `no_info_return` is `missing` (the default), an error is thrown 


""" ele_param_info

function ele_param_info(sym::Symbol; no_info_return = missing)
  if haskey(ele_param_dict, sym); return ele_param_dict[sym]; end
  (mtype, order) = multipole_type(sym)
  if mtype == nothing
    if ismissing(no_info_return); error(f"Unrecognized element parameter: {sym}"); end
    return no_info_return
  end

  # Must be a multipole
  n = length(mtype)
  if mtype == nothing; return nothing; end
  if n == 4 && mtype[1:4] == "tilt";  return ParamInfo(BMultipoleGroup, Real, f"Magnetic multipole tilt for order {order}", "rad"); end
  if n == 5 && mtype[1:5] == "Etilt"; return ParamInfo(EMultipoleGroup, Real, f"Electric multipole tilt for order {order}", "rad"); end

  occursin("s", mtype) ? str = "Skew," : str = "Normal (non-skew)"
  if occursin("l", mtype)
    str = str * " length-integrated,"
    order = order - 1
  end

  if mtype[1:1] == "K"
    if order == -1; units = "";
    else           units = f"1/m^{order+1}"; end
    return ParamInfo(BMultipoleGroup, Real, f"{str}, momentum-normalized magnetic multipole.", units)

  elseif mtype[1:1] == "B"
    if order == -1;    units = "T*m";
    elseif order == 0; units = "T"
    else               units = f"T/m^{order}"; end
    return ParamInfo(BMultipoleGroup, Real, f"{str} magnetic field multipole.", units)

  elseif mtype[1:1] == "E"
    if order == -1; units = "V";
    else            units = f"V/m^{order+1}"; end
    return ParamInfo(EMultipoleGroup, Real, f"{str} electric field multipole.", units) 
  end
end


#---------------------------------------------------------------------------------------------------

struct EleParamKey
  description::String
end

ele_param_group = Dict(
  AlignmentGroup        => EleParamKey("Vacuum chamber aperture."),
  ApertureGroup         => EleParamKey("Vacuum chamber aperture."),
  BendGroup             => EleParamKey("Bend element parameters."),
  BMultipoleGroup       => EleParamKey("Magnetic multipoles."),
  ChamberWallGroup      => EleParamKey("Vacuum chamber wall."),
  EMultipoleGroup       => EleParamKey("Electric multipoles."),
  FloorPositionGroup    => EleParamKey("Global floor position and orientation."),
  LengthGroup           => EleParamKey("Length parameter."),
  ReferenceGroup        => EleParamKey("Reference energy and species."),
  RFGroup               => EleParamKey("RF parameters."),
  StringGroup           => EleParamKey("Informational strings."),
  TrackingGroup         => EleParamKey("Default tracking settings."),
)


#---------------------------------------------------------------------------------------------------
# ele_param_groups

"""
Table of what element groups are associated with what element types.
"""

base_group_list = [LengthGroup, StringGroup, ReferenceGroup, AlignmentGroup, FloorPositionGroup, ApertureGroup, TrackingGroup]
multipole_group_list = [BMultipoleGroup, EMultipoleGroup]

ele_param_groups = Dict(  
  Dict(
    BeginningEle   => [StringGroup, ReferenceGroup, FloorPositionGroup, ApertureGroup, TrackingGroup],
    Bend           => vcat(base_group_list, multipole_group_list, BendGroup),
    Drift          => [StringGroup, ReferenceGroup, FloorPositionGroup, TrackingGroup],
    Marker         => copy(base_group_list),
    Quadrupole     => vcat(base_group_list, multipole_group_list),
  )
)

#---------------------------------------------------------------------------------------------------

struct ParamState
  settable::Bool
end

base_dict = merge(Dict{Symbol,Any}([v => ParamState(false) for v in [:s, :ix_ele, :branch]]),
                  Dict{Symbol,Any}([v => ParamState(true)  for v in [:len, :name]]))

#---------------------------------------------------------------------------------------------------
# ele_param_by_struct

function to_dict_from_groups(ele_type::Type{T}, groups) where T <: Ele
  dict = Dict{Symbol,Any}()
  for group in groups
    if group in [BMultipoleGroup, EMultipoleGroup]; continue; end
    dict = merge(dict, Dict{Symbol,Any}([v => ParamState(true) for v in fieldnames(group)]))
  end

  if ele_type != BeginningEle
    for key in [:theta, :phi, :psi]
      if haskey(dict, key); dict[key] = ParamState(false); end
    end
  end

  if ele_type == Bend; pop!(dict, :tilt); end

  return dict
end


"""
Table of what parameters are associated with what element types.
"""

ele_param_by_struct = Dict(  
  Dict(
    Bend           => merge(base_dict, to_dict_from_groups(Bend, ele_param_groups[Bend])),
    Drift          => merge(base_dict, to_dict_from_groups(Drift, ele_param_groups[Drift])),
    Marker         => merge(base_dict, to_dict_from_groups(Marker, ele_param_groups[Marker])),
    Quadrupole     => merge(base_dict, to_dict_from_groups(Quadrupole, ele_param_groups[Quadrupole])),
    BeginningEle   => base_dict,
  )
)

function has_param(type::Union{T,Type{T}}, sym::Symbol) where T <: Ele
  if typeof(type) != DataType; type = typeof(type); end
  if haskey(ele_param_by_struct[type], sym); return true; end
  # Rule: If BMultipoleGroup is in ele then EMultipoleGroup is in ele. (Is this really wise?)
  if BMultipoleGroup in ele_param_groups[type] && multipole_type(sym)[1] != nothing; return true; end
  return false
end

#---------------------------------------------------------------------------------------------------
# is_settable

"""

"""

function is_settable(ele::T, sym::Symbol) where T <: Ele
  if haskey(ele_param_by_struct[typeof(ele)], sym); return ele_param_by_struct[typeof(ele)][sym].settable; end

  pinfo = ele_param_info(sym)
  if pinfo == nothing; error(f"No info on: {sym}"); end

  return true
end

#---------------------------------------------------------------------------------------------------
# multipole

"""

Finds multipole of a given order.

Returns `nothing` if `vec` array does not contain element with n = `order` and `insert` = `nothing`.
""" multipole

function multipole!(mgroup, order; insert = nothing)
  if order < 0; return nothing; end
  ix = multipole_index(mgroup.vec, order)

  if insert == nothing
    if ix > length(mgroup.vec) || order != mgroup.vec[ix].n; return nothing; end
    return mgroup.vec[ix]
  end

  if ix > length(mgroup.vec) || mgroup.vec[ix].n != order
    vec = mgroup.vec
    insert!(vec, ix, insert)
    if typeof(mgroup) == BMultipoleGroup 
      mgroup = BMultipoleGroup(vec)
    else
      mgroup = EMultipoleGroup(vec)
    end
  end

  return mgroup.vec[ix]
end


"""
Find `vec` index where `order` should be. 
Example: If `vec[].n` has orders [1, 3, 6] then
  order     multipole_index
  < 0           0
  0 - 1         1
  2 - 3         2
  4 - 6         3
  > 6           4
"""

function multipole_index(vec, order)
  if order < 0; return 0; end
  if length(vec) == 0; return 1; end

  for ix in 1:length(vec)
    if vec[ix].n >= order; return ix; end
  end
  return length(vec) + 1
end  

#---------------------------------------------------------------------------------------------------
# branch_param_defaults

"""
Real parameters have default 0.0 if not specified.
Note: :geometry is not set for lord branches.
"""
branch_param_defaults = Dict(
  :ix_branch  => "-",
)

"""
Dictionary of parameters in the Branch.param dict.
"""

branch_param = Dict(
  :ix_branch   => ParamInfo(Nothing, Int,      "Index of branch in containing lat .branch[] array"),
  :geometry    => ParamInfo(Nothing, Switch,   "open_geom or closed_geom Geometry enums"),
  :lat         => ParamInfo(Nothing, Pointer,  "Pointer to lattice containing the branch."),
  :type        => ParamInfo(Nothing, Switch,   "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => ParamInfo(Nothing, Pointer,  "Element that forks to this branch."),
  :live_branch => ParamInfo(Nothing, Bool,     "Used by programs to turn on/off tracking in a branch."),
  :ref_species => ParamInfo(Species, String,   "Reference tracking species."),
)

#---------------------------------------------------------------------------------------------------
# ele_group_value

"""
This function assumes that `sym` is known to be in the group.
This function will return dependent values. EG: integrated multipole value even if stored value is not integrated.
""" ele_group_value

function ele_group_value(group::T, sym::Symbol) where T <: EleParameterGroup
  return getfield(group, sym)
end


function ele_group_value(group::BMultipoleGroup, sym::Symbol)
  (mtype, order) = multipole_type(sym)
  mul = multipole(group, order)
  if mul == nothing; return 0.0::Float64; end

  if mtype == "K" || mtype == "Kl";         value = mul.K
  elseif mtype == "Ks" || mtype == "Ksl";   value = mul.Ks
  elseif mtype == "B"  || mtype == "Bl";    value = mul.B
  elseif mtype == "Bs" || mtype == "Bsl";   value = mul.Bs
  elseif mtype == "tilt";                   value = mul.tilt
  end  
end

function ele_group_value(group::EMultipoleGroup, sym::Symbol)
  (mtype, order) = multipole_type(sym)
  mul = multipole(group, order)
  if mul == nothing; return 0.0::Float64; end

  if mtype == "E" || mtype == "El";         value = mul.E
  elseif mtype == "Es" || mtype == "Esl";   value = mul.Es
  elseif mtype == "Etilt";                   value = mul.tilt
  end  
end

#---------------------------------------------------------------------------------------------------


"""
Dictionary of parameters in the Lat.param dict.
"""

lat_param = Dict(
)

