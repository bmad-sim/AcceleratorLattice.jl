"""
Dictionaries of parameters defined in a lattice
"""

"""
Possible kind values: String, Int, Real, RealVec, Bool, Switch, Struct, Pointer

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

A Struct is a struct. For example, the :floor parameter holds a FloorPosition struct
"""


abstract type Struct end
abstract type Pointer end
abstract type RealVec end

@kwdef struct ParamInfo
  parent_group::T where T <: DataType
  kind::Union{T, Union} where T <: DataType  # Something like ApertureTypeSwitch is a Union.
  description::String = ""
  units::String = ""
  private::Bool = false
end

ParamInfo(parent::DataType, kind::Union{DataType, Union}, description::String) = ParamInfo(parent, kind, description, "", false)
ParamInfo(parent::DataType, kind::Union{DataType, Union}, description::String, units::String) = ParamInfo(parent, kind, description, units, false)

"""
Dictionary of parameters in the Ele.param dict.
"""

ele_param_dict = Dict(
  :type             => ParamInfo(StringGroup,    String,    "Type of element. Set by User and ignored the code."),
  :alias            => ParamInfo(StringGroup,    String,    "Alias name. Set by User and ignored by the code."),
  :description      => ParamInfo(StringGroup,    String,    "Descriptive info. Set by User and ignored by the code."),

  :angle            => ParamInfo(BendGroup,      Real,      "Design bend angle", "rad"),
  :bend_field       => ParamInfo(BendGroup,      Real,      "Design bend field corresponding to g bending", "T"),
  :rho              => ParamInfo(BendGroup,      Real,      "Design bend radius", "m"),
  :g                => ParamInfo(BendGroup,      Real,      "Design bend strength (1/rho)", "1/m"),
  :e                => ParamInfo(BendGroup,      RealVec,   "2-Vector of bend entrance and exit face angles.", "rad"),
  :e_rec            => ParamInfo(BendGroup,      RealVec,   
                                  "2-Vector of bend entrance and exit face angles relative to a rectangular geometry.", "rad"),
  :len              => ParamInfo(BendGroup,      Real,      "Element length.", "m"),
  :len_chord        => ParamInfo(BendGroup,      Real,      "Bend chord length.", "m"),
  :ref_tilt         => ParamInfo(BendGroup,      Real,      "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint             => ParamInfo(BendGroup,      RealVec,   "2-Vector of bend [entrance, exit] edge field integrals.", ""),
  :hgap             => ParamInfo(BendGroup,      RealVec,   "2-Vector of bend [entrance, exit] edge pole gap heights.", "m"),

  :offset           => ParamInfo(AlignmentGroup, RealVec,   "3-Vector of [x, y, z] element offsets.", "m"),
  :x_pitch          => ParamInfo(AlignmentGroup, Real,      "X-pitch element orientation.", "rad"),
  :y_pitch          => ParamInfo(AlignmentGroup, Real,      "Y-pitch element orientation.", "rad"),
  :tilt             => ParamInfo(AlignmentGroup, Real,      "Element tilt.", "rad"),

  :voltage          => ParamInfo(RFGroup,        Real,      "RF voltage.", "volt"),
  :gradient         => ParamInfo(RFGroup,        Real,      "RF gradient.", "volt/m"),
  :auto_amp_scale   => ParamInfo(RFGroup,        Real,      
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :phase            => ParamInfo(RFGroup,        Real,      "RF phase.", "rad"),
  :auto_phase       => ParamInfo(RFGroup,        Real,      "Correction RF phase calculated by the auto scale code.", "rad"),
  :multipass_phase  => ParamInfo(RFGroup,        Real,      
                                  "RF phase which can differ from multipass element to multipass element.", "rad"),
  :frequency        => ParamInfo(RFGroup,        Real,      "RF frequency.", "Hz"),
  :harmon           => ParamInfo(RFGroup,        Real,      "RF frequency harmonic number.", ""),
  :cavity_type      => ParamInfo(RFGroup,        CavityTypeSwitch, "Type of cavity."),
  :n_cell           => ParamInfo(RFGroup,        Int,       "Number of RF cells."),

  :tracking_method  => ParamInfo(TrackingGroup,  TrackingMethodSwitch,  "Nominal method used for tracking."),
  :field_calc       => ParamInfo(TrackingGroup,  FieldCalcMethodSwitch, "Nominal method used for calculating the EM field."),
  :num_steps        => ParamInfo(TrackingGroup,  Int,                   "Nominal number of tracking steps."),
  :ds_step          => ParamInfo(TrackingGroup,  Real,                  "Nominal distance between tracking steps.", "m"),

  :aperture_type    => ParamInfo(ApertureGroup,  ApertureTypeSwitch, "Type of aperture."),
  :aperture_at      => ParamInfo(ApertureGroup,  EleBodyLocationSwitch, "Where the aperture is."),
  :offset_moves_aperture 
                    => ParamInfo(ApertureGroup,  Bool, "Does moving the element move the aperture?"),
  :x_limit          => ParamInfo(ApertureGroup,  RealVec,   "2-Vector of horizontal aperture limits.", "m"),
  :y_limit          => ParamInfo(ApertureGroup,  RealVec,   "2-Vector of vertical aperture limits.", "m"),

  :r_floor          => ParamInfo(FloorPositionGroup, RealVec,   "3-vector of floor position.", "m"),
  :q_floor          => ParamInfo(FloorPositionGroup, RealVec,   "Quaternion orientation.", ""),

  :name             => ParamInfo(Nothing,        String,    "Name of the element."),
  :s                => ParamInfo(Nothing,        Real,      "Longitudinal s-position.", "m"),
  :ix_ele           => ParamInfo(Nothing,        Int,       "Index of element in containing branch.ele array."),
  :orientation      => ParamInfo(Nothing,        Int,       "Longitudinal orientation of element. May be +1 or -1."),
  :branch           => ParamInfo(Nothing,        Pointer,   "Pointer to branch element is in."),
  :bookkeeping_on   => ParamInfo(Nothing,        Bool,      "Is bookkeeping code active?", "", true),
  :map_params_to_groups 
                    => ParamInfo(Nothing,        Bool,      "Map element params to element groups?", "", true),
)

function units(key)
  param_info = ele_param_info(key)
  if param_info == nothing; return "???"; end
  return param_info.units
end

function description(key)
  param_info = ele_param_info(key)
  if param_info == nothing; return "???"; end
  return param_info.description
end

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

"""Returns param_info or nothing""" ele_param_info

function ele_param_info(sym::Symbol)
  if haskey(ele_param_dict, sym); return ele_param_dict[sym]; end
  (mtype, order) = multipole_type(sym)
  if mtype == nothing; return nothing; end

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


#-----------------------------------------------------------------------------------------

struct EleParamKey
  description::String
end

ele_param_group = Dict(
  FloorPositionGroup    => EleParamKey("Global floor position and orientation"),
  BMultipoleGroup       => EleParamKey("Magnetic multipoles."),
  EMultipoleGroup       => EleParamKey("Electric multipoles."),
  AlignmentGroup        => EleParamKey("Vacuum chamber aperture."),
  BendGroup             => EleParamKey("Bend element parameters."),
  ApertureGroup         => EleParamKey("Vacuum chamber aperture."),
  StringGroup           => EleParamKey("Informational strings."),
  RFGroup               => EleParamKey("RF parameters."),
  TrackingGroup         => EleParamKey("Default tracking settings."),
  ChamberWallGroup      => EleParamKey("Vacuum chamber wall."),
)


#-----------------------------------------------------------------------------------------
# ele_param_groups

"""
Table of what element groups are associated with what element types.
"""

base_group_list = [StringGroup, AlignmentGroup, FloorPositionGroup, ApertureGroup, TrackingGroup]
multipole_group_list = [BMultipoleGroup, EMultipoleGroup]

ele_param_groups = Dict(  
  Dict(
    Bend           => vcat(base_group_list, multipole_group_list, BendGroup),
    Drift          => [StringGroup, FloorPositionGroup, TrackingGroup],
    Marker         => copy(base_group_list),
    Quadrupole     => vcat(base_group_list, multipole_group_list),
    BeginningEle   => [],
  )
)

#-----------------------------------------------------------------------------------------

struct ParamState
  settable::Bool
end

base_dict = merge(Dict{Symbol,Any}([v => ParamState(false) for v in [:s, :ix_ele, :branch]]),
                  Dict{Symbol,Any}([v => ParamState(true)  for v in [:len, :name, :bookkeeping_on, :map_params_to_groups]]))

#-----------------------------------------------------------------------------------------
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
  # Rule: If BMultipoleGroup is in ele then EMultipoleGroup is in ele. (really?)
  if BMultipoleGroup in ele_param_groups[type] && multipole_type(sym)[1] != nothing; return true; end
  return false
end

function is_settable(ele::T, sym::Symbol) where T <: Ele
  if haskey(ele_param_by_struct[typeof(ele)], sym); return ele_param_by_struct[type][key].settable; end

  pinfo = ele_param_info(sym)
  if pinfo == nothing; throw(f"No info on: {sym}"); end

  if pinfo.parent_group == BMultipoleGroup
    if !haskey(ele.param, :BMultipoleGroup); return true; end
    vec = ele.param[:BultipoleGroup]
    (mtype, order) = multipole_type(sym)
    if length(vec) < order|| vec[order] == nothing || mtype == "tilt"; return true; end
    v = vec[order]
    if (mtype[end] == 'l' && !v.integrated) || (mtype[end] != 'l' &&  v.integrated); return false; end
    if (mtype[1] == 'K' && isnan(v.B) && isnan(v.Bs)) || (mtype[1] == 'B' && isnan(v.K) && isnan(v.Ks)); return true; end
    return false
  end
end

#-----------------------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------------------


"""
Dictionary of parameters in the Lat.param dict.
"""

lat_param = Dict(
)

