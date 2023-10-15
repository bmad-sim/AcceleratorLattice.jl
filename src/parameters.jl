"""
Possible kind values: String, Int, Real, Vector{Real}, Bool, Switch, Struct, Pointer

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

A Struct is a struct. For example, the :floor parameter holds a FloorPosition struct
"""


abstract type Struct end
abstract type Pointer end

@kwdef mutable struct ParamInfo
  parent_group::T where T <: Union{DataType,Union}  # Use the parent_group function to get the parent group.
  kind::Union{T, Union} where T <: DataType         # Something like ApertureTypeSwitch is a Union.
  description::String = ""
  units::String = ""
  private::Bool = false
end

ParamInfo(parent::Union{DataType,Union}, kind::Union{DataType, Union}, description::String) = 
                                                    ParamInfo(parent, kind, description, "", false)
ParamInfo(parent::Union{DataType,Union}, kind::Union{DataType, Union}, description::String, units::String) = 
                                                    ParamInfo(parent, kind, description, units, false)

ap = Union{AlignmentGroup,PatchGroup}

"""
Dictionary of parameter types. Keys are inbox names (which can be different from group names. 
EG: theta_floor inbox name corresponds to theta in the FloorPositionGroup.
"""
ele_param_info_dict = Dict(
  :name             => ParamInfo(Nothing,        String,    "Name of the element."),
  :ix_ele           => ParamInfo(Nothing,        Int,       "Index of element in containing branch.ele array."),
  :orientation      => ParamInfo(Nothing,        Int,       "Longitudinal orientation of element. May be +1 or -1."),
  :branch           => ParamInfo(Nothing,        Pointer,   "Pointer to branch element is in."),

  :type             => ParamInfo(StringGroup,    String,    "Type of element. Set by User and ignored the code."),
  :alias            => ParamInfo(StringGroup,    String,    "Alias name. Set by User and ignored by the code."),
  :description      => ParamInfo(StringGroup,    String,    "Descriptive info. Set by User and ignored by the code."),

  :len              => ParamInfo(LengthGroup,    Real,      "Element length.", "m"),
  :s                => ParamInfo(LengthGroup,    Real,      "Longitudinal s-position.", "m"),
  :s_exit           => ParamInfo(LengthGroup,    Real,      "Longitudinal s-position at exit end.", "m"),

  :field_master     => ParamInfo(MasterGroup,    Bool,      
                                  "Used when varying ref energy. True -> fields are fixed and normalized fields vary."),

  :species_ref      => ParamInfo(ReferenceGroup, Species,   "Reference species."),
  :species_ref_exit => ParamInfo(ReferenceGroup, Species,   "Reference species at exit end."),
  :pc_ref           => ParamInfo(ReferenceGroup, Real,      "Reference momentum * c.", "eV"),
  :E_tot_ref        => ParamInfo(ReferenceGroup, Real,      "Reference total energy.", "eV"),
  :time_ref         => ParamInfo(ReferenceGroup, Real,      "Reference time.", "sec"),
  :pc_ref_exit      => ParamInfo(ReferenceGroup, Real,      "Reference momentum * c at exit end.", "eV"),
  :E_tot_ref_exit   => ParamInfo(ReferenceGroup, Real,      "Reference total energy at exit end.", "eV"),
  :time_ref_exit    => ParamInfo(ReferenceGroup, Real,      "Reference total energy at exit end.", "eV"),

  :angle            => ParamInfo(BendGroup,      Real,      "Design bend angle", "rad"),
  :bend_field       => ParamInfo(BendGroup,      Real,      "Design bend field corresponding to g bending", "T"),
  :rho              => ParamInfo(BendGroup,      Real,      "Design bend radius", "m"),
  :g                => ParamInfo(BendGroup,      Real,      "Design bend strength (1/rho)", "1/m"),
  :e1               => ParamInfo(BendGroup,      Real,      "Bend entrance face angle.", "rad"),
  :e2               => ParamInfo(BendGroup,      Real,      "Bend exit face angle.", "rad"),
  :e1_rect          => ParamInfo(BendGroup,      Real,      "bend entrance face angles relative to a rectangular geometry.", "rad"),
  :e2_rect          => ParamInfo(BendGroup,      Real,      "bend exit face angles relative to a rectangular geometry.", "rad"),
  :len_chord        => ParamInfo(BendGroup,      Real,      "Bend chord length.", "m"),
  :ref_tilt         => ParamInfo(BendGroup,      Real,      "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint             => ParamInfo(BendGroup,      Real,      "Used to set fint1 and fint2 both at once.", ""),
  :fint1            => ParamInfo(BendGroup,      Real,      "Bend entrance edge field integral.", ""),
  :fint2            => ParamInfo(BendGroup,      Real,      "Bend exit edge field integral.", ""),
  :hgap             => ParamInfo(BendGroup,      Real,      "Used to set hgap1 and hgap2 both at once.", ""),
  :hgap1            => ParamInfo(BendGroup,      Real,      "Bend entrance edge pole gap height.", "m"),
  :hgap2            => ParamInfo(BendGroup,      Real,      "Bend exit edge pole gap height.", "m"),
  :bend_type        => ParamInfo(BendGroup,      BendTypeSwitch, "Sets how face angles varies with bend angle."),

  :offset           => ParamInfo(ap,             Vector{Real}, "3-Vector of [x, y, z] element offsets.", "m"),
  :x_pitch          => ParamInfo(ap,             Real,         "X-pitch element orientation.", "rad"),
  :y_pitch          => ParamInfo(ap,             Real,         "Y-pitch element orientation.", "rad"),
  :tilt             => ParamInfo(ap,             Real,         "Element tilt.", "rad"),

  :offset_tot       => ParamInfo(AlignmentGroup, Vector{Real}, "Offset including Girder orientation.", "m"),
  :x_pitch_tot      => ParamInfo(AlignmentGroup, Real,         "X-pitch element orientation including Girder orientation.", "rad"),
  :y_pitch_tot      => ParamInfo(AlignmentGroup, Real,         "Y-pitch element orientation including Girder orientation.", "rad"),
  :tilt_tot         => ParamInfo(AlignmentGroup, Real,         "Element tilt including Girder orientation.", "rad"),

  :E_tot_offset     => ParamInfo(PatchGroup,     Float64,      "Reference energy offset.", "eV"),
  :E_tot_exit       => ParamInfo(PatchGroup,     Float64,      "Reference energy at exit end.", "eV"),
  :pc_exit          => ParamInfo(PatchGroup,     Float64,      "Reference momentum at exit end.", "eV"),
  :flexible         => ParamInfo(PatchGroup,     Bool,         "Flexible patch?"),
  :user_sets_length => ParamInfo(PatchGroup,     Bool,         "Does Bmad calculate the patch length?"),
  :ref_coords       => ParamInfo(PatchGroup,     EleEndLocationSwitch, "Patch coords with respect to EntranceEnd or ExitEnd?"),

  :voltage          => ParamInfo(RFFieldGroup,   Real,          "RF voltage.", "volt"),
  :gradient         => ParamInfo(RFFieldGroup,   Real,          "RF gradient.", "volt/m"),
  :phase            => ParamInfo(RFFieldGroup,   Real,          "RF phase.", "rad"),

  :auto_amp         => ParamInfo(RFGroup,        Real,      
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :auto_phase       => ParamInfo(RFGroup,        Real,          "Correction RF phase calculated by the auto scale code.", "rad"),
  :multipass_phase  => ParamInfo(RFGroup,        Real,      
                                  "RF phase which can differ from multipass element to multipass element.", "rad"),
  :frequency        => ParamInfo(RFGroup,        Real,             "RF frequency.", "Hz"),
  :harmon           => ParamInfo(RFGroup,        Real,             "RF frequency harmonic number.", ""),
  :cavity_type      => ParamInfo(RFGroup,        CavityTypeSwitch, "Type of cavity."),
  :n_cell           => ParamInfo(RFGroup,        Int,              "Number of RF cells."),

  :voltage_ref      => ParamInfo(LCavityGroup,   Real,          "Reference RF voltage.", "volt"),
  :voltage_err      => ParamInfo(LCavityGroup,   Real,          "RF voltage error.", "volt"),
  :voltage_tot      => ParamInfo(LCavityGroup,   Real,          "Actual RF voltage (ref + err).", "volt"),
  :gradient_ref     => ParamInfo(LCavityGroup,   Real,          "Reference RF gradient.", "volt/m"),
  :gradient_err     => ParamInfo(LCavityGroup,   Real,          "RF gradient error.", "volt/m"),
  :gradient_tot     => ParamInfo(LCavityGroup,   Real,          "Actual RF gradient (ref + err).", "volt/m"),
  :phase_ref        => ParamInfo(LCavityGroup,   Real,          "Reference RF phase.", "rad"),
  :phase_err        => ParamInfo(LCavityGroup,   Real,          "RF phase error.", "rad"),
  :phase_tot        => ParamInfo(LCavityGroup,   Real,          "Actual RF phase. (ref + err)", "rad"),

  :voltage_master   => ParamInfo(RFMasterGroup,  Bool,          "Voltage or gradient is constant with length changes?"),
  :do_auto_amp      => ParamInfo(RFMasterGroup,  Bool,          "Autoscale voltage/gradient?"),
  :do_auto_phase    => ParamInfo(RFMasterGroup,  Bool,          "Autoscale phase?"),
  :do_auto_scale    => ParamInfo(RFMasterGroup,  Bool,          "Used to set do_auto_amp and do_auto_phase both at once."),

  :tracking_method  => ParamInfo(TrackingGroup,  TrackingMethodSwitch,  "Nominal method used for tracking."),
  :field_calc       => ParamInfo(TrackingGroup,  FieldCalcMethodSwitch, "Nominal method used for calculating the EM field."),
  :num_steps        => ParamInfo(TrackingGroup,  Int,                   "Nominal number of tracking steps."),
  :ds_step          => ParamInfo(TrackingGroup,  Real,                  "Nominal distance between tracking steps.", "m"),

  :aperture_type    => ParamInfo(ApertureGroup,  ApertureTypeSwitch,    "Type of aperture."),
  :aperture_at      => ParamInfo(ApertureGroup,  EleBodyLocationSwitch, "Where the aperture is."),
  :offset_moves_aperture 
                    => ParamInfo(ApertureGroup,  Bool,               "Does moving the element move the aperture?"),
  :x_limit          => ParamInfo(ApertureGroup,  Vector{Real},       "2-Vector of horizontal aperture limits.", "m"),
  :y_limit          => ParamInfo(ApertureGroup,  Vector{Real},       "2-Vector of vertical aperture limits.", "m"),

  :r_floor          => ParamInfo(FloorPositionGroup, Vector{Real},       "3-vector of floor position.", "m"),
  :q_floor          => ParamInfo(FloorPositionGroup, Vector{Real},       "Quaternion orientation.", ""),
  :theta            => ParamInfo(FloorPositionGroup, Real,               "Floor theta angle orientation", "rad"),
  :phi              => ParamInfo(FloorPositionGroup, Real,               "Floor phi angle orientation", "rad"),
  :psi              => ParamInfo(FloorPositionGroup, Real,               "Floor psi angle orientation", "rad"),
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

function parent_group(info::ParamInfo, ele::Ele)
  if typeof(info.parent_group) == DataType; return info.parent_group; end

  if info.parent_group == Union{AlignmentGroup,PatchGroup}
    typeof(ele) == Patch ? (return PatchGroup) : (return AlignmentGroup)
  end

  error("??? Error in parent_group. Please report this error!")
end

"""
An alias is something like `hgap` which gets mapped to `hgap1` and `hgap2`
"""
param_alias = Dict(
  :hgap           => [:hgap1, :hgap2],
  :fint           => [:fint1, :fint2],
  :do_auto_scale  => [:do_auto_amp, :do_auto_phase]
)

"""
"""
function info(sym::Union{Symbol,String})
  if typeof(sym) == String; sym = Symbol(sym); end
  for (param, info) in ele_param_info_dict
    if sym == param
      println(f"  Element parameter:       {param}")
      println(f"  Element group:   {info.parent_group}")
      println(f"  Parameter type:  {info.kind}")
      if info.units != ""; println(f"  Units:           {info.units}"); end
      println(f"  Description:     {info.description}")
      return 
   end
  end

  println(f"No information found on: {sym}")
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

"""
Returns param_info or `default`.
If the value `no_info_return` is `Error` (the default), an error is thrown.
Otherwise the value of `no_info_return` is returned


""" ele_param_info

function ele_param_info(sym::Symbol; no_info_return = Error)
  if haskey(ele_param_info_dict, sym); return ele_param_info_dict[sym]; end
  (mtype, order) = multipole_type(sym)
  if isnothing(mtype)
    if no_info_return == Error; error(f"Unrecognized element parameter: {sym}"); end
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
# ele_param_groups

"""
Table of what element groups are associated with what element types.
Order is important. Bookkeeping routines rely on: 
  LengthGroup being first.
  BendGroup after ReferenceGroup and MasterGroup.
  BMultipoleGroup and EMultipoleGroup after MasterGroup.
  RFGroup comes last (triggers autoscale/autophase and ReferenceGroup correction)
"""

base_group_list = [LengthGroup, StringGroup, ReferenceGroup, FloorPositionGroup, TrackingGroup]
alignment_group_list = [AlignmentGroup, ApertureGroup]
multipole_group_list = [MasterGroup, BMultipoleGroup, EMultipoleGroup]
general_group_list = vcat(base_group_list, alignment_group_list, multipole_group_list)

ele_param_groups = Dict(  
  Dict(
    BeginningEle   => base_group_list,
    Bend           => vcat(general_group_list, BendGroup),
    Drift          => base_group_list,
    LCavity        => vcat(general_group_list, RFMasterGroup, LCavityGroup, RFGroup),
    Marker         => base_group_list,
    Octupole       => general_group_list,
    Patch          => vcat(base_group_list, PatchGroup),
    Quadrupole     => general_group_list,
    RFCavity       => vcat(general_group_list, RFMasterGroup, RFFieldGroup, RFGroup),
    Sextupole      => general_group_list,
  )
)

#---------------------------------------------------------------------------------------------------

struct ParamState
  settable::Bool
end

#---------------------------------------------------------------------------------------------------
# ele_param_by_ele_type

"""
Table of what parameters are associated with what element types.
"""

base_dict = merge(Dict{Symbol,Any}([v => ParamState(false) for v in [:s, :ix_ele, :branch]]),
                  Dict{Symbol,Any}([v => ParamState(true)  for v in [:len, :name]]))

ele_param_by_ele_type = Dict{DataType,Dict{Symbol,Any}}()
for (ele_type, group_list) in ele_param_groups
  ele_param_by_ele_type[ele_type] = base_dict
  for group in group_list
    if group in [BMultipoleGroup, EMultipoleGroup]; continue; end
    ele_param_by_ele_type[ele_type] = merge(ele_param_by_ele_type[ele_type], 
                            Dict{Symbol,Any}([v => ParamState(true) for v in fieldnames(group)]))
  end
end
ele_param_by_ele_type[BeginningEle][:s] = ParamState(true)


function has_param(type::Union{T,Type{T}}, sym::Symbol) where T <: Ele
  if typeof(type) != DataType; type = typeof(type); end
  if haskey(ele_param_by_ele_type[type], sym); return true; end
  # Rule: If BMultipoleGroup is in ele then EMultipoleGroup is in ele. (Is this really wise?)
  if BMultipoleGroup in ele_param_groups[type] && multipole_type(sym)[1] != nothing; return true; end
  return false
end

#---------------------------------------------------------------------------------------------------
# is_settable

"""

"""

function is_settable(ele::T, sym::Symbol) where T <: Ele
  if haskey(ele_param_by_ele_type[typeof(ele)], sym); return ele_param_by_ele_type[typeof(ele)][sym].settable; end

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
Dictionary of parameters in the Branch.pdict dict.
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
# isa_eleparametergroup

function isa_eleparametergroup(sym::Symbol)
  try
    global val = eval(sym)
  catch
    return false
  end

  if typeof(val) != DataType; return; end
  return val <: EleParameterGroup
end

#---------------------------------------------------------------------------------------------------


"""
Dictionary of parameters in the Lat.pdict dict.
"""

lat_param = Dict(
)

