#---------------------------------------------------------------------------------------------------
# ParamInfo

"""
Possible `kind` values: String, Int, Number, Vector{Number}, Bool, Pointer, etc.

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.
""" ParamInfo

abstract type Pointer end

@kwdef mutable struct ParamInfo
  parent_group::T where T <: Union{DataType,Vector}  # Use the parent_group function to get the parent group.
  kind::Union{T, Union} where T <: DataType         # Something like ApertureTypeSwitch is a Union.
  description::String = ""
  units::String = ""
  struct_sym::Symbol                                # Symbol associated with parent struct.
  user_sym::Symbol                                  # Symbol used to construct elements.
end

# Used for constructing the ele_param_info_dict.
# ":XXX" indicates that the struct_sym will be the same as the key in ele_param_info_dict.
# And ":Z" is always replaced by the key in ele_param_info_dict.

ParamInfo(parent, kind, description) = ParamInfo(parent, kind, description, "", :XXX, :Z)
ParamInfo(parent, kind, description, units) = ParamInfo(parent, kind, description, units, :XXX, :Z)
ParamInfo(parent, kind, description, units, struct_sym) = ParamInfo(parent, kind, description, units, struct_sym, :Z)

#---------------------------------------------------------------------------------------------------
# ele_param_info_dict

# Note: ":XXX" will get replaced by the key (user name) below so that, for example, 
# ele_param_info_dict[:field_master].struct_sym will have the value :field_master.

"""
Dictionary of parameter types. Keys are user names (which can be different from corresponding group name). 
EG: theta_floor user name corresponds to theta in the FloorPositionGroup.
""" ele_param_info_dict

ele_param_info_dict = Dict(
  :name               => ParamInfo(Nothing,        String,      "Name of the element."),
  :ix_ele             => ParamInfo(Nothing,        Int,         "Index of element in containing branch.ele[] array."),
  :branch             => ParamInfo(Nothing,        Branch,      "Pointer to branch element is in."),
  :multipass_lord     => ParamInfo(Nothing,        Ele,         "Element's multipass_lord. Will not be present if no lord exists."),
  :super_lords        => ParamInfo(Nothing,        Vector{Ele}, "Array of element's super_lords. Will not be present if no lords exist."),
  :slaves             => ParamInfo(Nothing,        Vector{Ele}, "Array of slaves of element. Will not be present if no slaves exist."),

  :type               => ParamInfo(StringGroup,    String,      "Type of element. Set by User and ignored the code."),
  :alias              => ParamInfo(StringGroup,    String,      "Alias name. Set by User and ignored by the code."),
  :description        => ParamInfo(StringGroup,    String,      "Descriptive info. Set by User and ignored by the code."),

  :L                  => ParamInfo(LengthGroup,    Number,      "Element length.", "m"),
  :orientation        => ParamInfo(LengthGroup,    Int,         "Longitudinal orientation of element. May be +1 or -1."),
  :s                  => ParamInfo(LengthGroup,    Number,      "Longitudinal s-position at the upstream end.", "m"),
  :s_downstream       => ParamInfo(LengthGroup,    Number,      "Longitudinal s-position at the downstream end.", "m"),

  :is_on              => ParamInfo(MasterGroup,    Bool,        "Element fields on/off."),
  :field_master       => ParamInfo(MasterGroup,    Bool,        "True: fields are fixed and normalized values change when varying ref energy."),

  :species_ref        => ParamInfo(ReferenceGroup, Species,     "Reference species."),
  :species_ref_exit   => ParamInfo(ReferenceGroup, Species,     "Reference species at exit end."),
  :pc_ref             => ParamInfo(ReferenceGroup, Number,      "Reference momentum * c.", "eV"),
  :E_tot_ref          => ParamInfo(ReferenceGroup, Number,      "Reference total energy.", "eV"),
  :time_ref           => ParamInfo(ReferenceGroup, Number,      "Reference time.", "sec"),
  :pc_ref_exit        => ParamInfo(ReferenceGroup, Number,      "Reference momentum * c at exit end.", "eV"),
  :E_tot_ref_exit     => ParamInfo(ReferenceGroup, Number,      "Reference total energy at exit end.", "eV"),
  :time_ref_exit      => ParamInfo(ReferenceGroup, Number,      "Reference time at exit end.", "sec"),

  :angle              => ParamInfo(BendGroup,      Number,      "Design bend angle", "rad"),
  :bend_field         => ParamInfo(BendGroup,      Number,      "Design bend field corresponding to g bending", "T"),
  :rho                => ParamInfo(BendGroup,      Number,      "Design bend radius", "m"),
  :g                  => ParamInfo(BendGroup,      Number,       "Design bend strength (1/rho)", "1/m"),
  :e1                 => ParamInfo(BendGroup,      Number,      "Bend entrance face angle.", "rad"),
  :e2                 => ParamInfo(BendGroup,      Number,      "Bend exit face angle.", "rad"),
  :e1_rect            => ParamInfo(BendGroup,      Number,      "Bend entrance face angles relative to a rectangular geometry.", "rad"),
  :e2_rect            => ParamInfo(BendGroup,      Number,      "Bend exit face angles relative to a rectangular geometry.", "rad"),
  :L_chord            => ParamInfo(BendGroup,      Number,      "Bend chord length.", "m"),
  :L_sagitta          => ParamInfo(BendGroup,      Number,      "Bend sagitta length.", "m"),
  :ref_tilt           => ParamInfo(BendGroup,      Number,      "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint               => ParamInfo(Nothing,        Number,      "Used to set fint1 and fint2 both at once.", ""),
  :fint1              => ParamInfo(BendGroup,      Number,      "Bend entrance edge field integral.", ""),
  :fint2              => ParamInfo(BendGroup,      Number,      "Bend exit edge field integral.", ""),
  :hgap               => ParamInfo(Nothing,        Number,      "Used to set hgap1 and hgap2 both at once.", ""),
  :hgap1              => ParamInfo(BendGroup,      Number,      "Bend entrance edge pole gap height.", "m"),
  :hgap2              => ParamInfo(BendGroup,      Number,      "Bend exit edge pole gap height.", "m"),
  :bend_type          => ParamInfo(BendGroup,      BendTypeSwitch, "Sets how face angles varies with bend angle."),

  :offset   => ParamInfo([AlignmentGroup,PatchGroup], Vector{Number}, "3-Vector of [x, y, z] element offsets.", "m"),
  :x_pitch  => ParamInfo([AlignmentGroup,PatchGroup], Number,         "X-pitch element orientation.", "rad"),
  :y_pitch  => ParamInfo([AlignmentGroup,PatchGroup], Number,         "Y-pitch element orientation.", "rad"),
  :tilt     => ParamInfo([AlignmentGroup,PatchGroup], Number,         "Element tilt.", "rad"),

  :offset_tot         => ParamInfo(AlignmentGroup, Vector{Number}, "Offset including Girder orientation.", "m"),
  :x_pitch_tot        => ParamInfo(AlignmentGroup, Number,         "X-pitch element orientation including Girder orientation.", "rad"),
  :y_pitch_tot        => ParamInfo(AlignmentGroup, Number,         "Y-pitch element orientation including Girder orientation.", "rad"),
  :tilt_tot           => ParamInfo(AlignmentGroup, Number,         "Element tilt including Girder orientation.", "rad"),

  :E_tot_offset       => ParamInfo(PatchGroup,     Number,         "Reference energy offset.", "eV"),
  :E_tot_exit         => ParamInfo(PatchGroup,     Number,         "Reference energy at exit end.", "eV"),
  :pc_exit            => ParamInfo(PatchGroup,     Number,         "Reference momentum at exit end.", "eV"),
  :flexible           => ParamInfo(PatchGroup,     Bool,           "Flexible patch?"),
  :user_sets_length   => ParamInfo(PatchGroup,     Bool,           "Does Bmad calculate the patch length?"),
  :ref_coords         => ParamInfo(PatchGroup,     BodyLocationSwitch, "Patch coords with respect to EntranceEnd or ExitEnd?"),

  :voltage            => ParamInfo(RFFieldGroup,   Number,        "RF voltage.", "volt"),
  :gradient           => ParamInfo(RFFieldGroup,   Number,        "RF gradient.", "volt/m"),
  :phase              => ParamInfo(RFFieldGroup,   Number,        "RF phase.", "rad"),

  :multipass_phase    => ParamInfo(RFGroup,        Number,    
                                  "RF phase which can differ from multipass element to multipass element.", "rad"),
  :frequency          => ParamInfo(RFGroup,        Number,           "RF frequency.", "Hz"),
  :harmon             => ParamInfo(RFGroup,        Number,           "RF frequency harmonic number.", ""),
  :cavity_type        => ParamInfo(RFGroup,        CavityTypeSwitch, "Type of cavity."),
  :n_cell             => ParamInfo(RFGroup,        Int,              "Number of RF cells."),

  :voltage_ref        => ParamInfo(LCavityGroup,   Number,        "Reference RF voltage.", "volt"),
  :voltage_err        => ParamInfo(LCavityGroup,   Number,        "RF voltage error.", "volt"),
  :voltage_tot        => ParamInfo(LCavityGroup,   Number,        "Actual RF voltage (ref + err).", "volt"),
  :gradient_ref       => ParamInfo(LCavityGroup,   Number,        "Reference RF gradient.", "volt/m"),
  :gradient_err       => ParamInfo(LCavityGroup,   Number,        "RF gradient error.", "volt/m"),
  :gradient_tot       => ParamInfo(LCavityGroup,   Number,        "Actual RF gradient (ref + err).", "volt/m"),
  :phase_ref          => ParamInfo(LCavityGroup,   Number,        "Reference RF phase.", "rad"),
  :phase_err          => ParamInfo(LCavityGroup,   Number,        "RF phase error.", "rad"),
  :phase_tot          => ParamInfo(LCavityGroup,   Number,        "Actual RF phase. (ref + err)", "rad"),

  :voltage_master     => ParamInfo(RFMasterGroup,  Bool,          "Voltage or gradient is constant with length changes?"),
  :auto_amp           => ParamInfo(RFMasterGroup,  Number,    
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :auto_phase         => ParamInfo(RFMasterGroup,  Number,        "Correction RF phase calculated by the auto scale code.", "rad"),
  :do_auto_amp        => ParamInfo(RFMasterGroup,  Bool,          "Autoscale voltage/gradient?"),
  :do_auto_phase      => ParamInfo(RFMasterGroup,  Bool,          "Autoscale phase?"),
  :do_auto_scale      => ParamInfo(Nothing,        Bool,          "Used to set do_auto_amp and do_auto_phase both at once.", ""),

  :tracking_method    => ParamInfo(TrackingGroup,  TrackingMethodSwitch,  "Nominal method used for tracking."),
  :field_calc         => ParamInfo(TrackingGroup,  FieldCalcMethodSwitch, "Nominal method used for calculating the EM field."),
  :num_steps          => ParamInfo(TrackingGroup,  Int,                   "Nominal number of tracking steps."),
  :ds_step            => ParamInfo(TrackingGroup,  Number,                "Nominal distance between tracking steps.", "m"),

  :aperture_type      => ParamInfo(ApertureGroup,  ApertureTypeSwitch,    "Type of aperture. Default is Elliptical."),
  :aperture_at        => ParamInfo(ApertureGroup,  BodyLocationSwitch, "Where the aperture is. Default is EntranceEnd."),
  :offset_moves_aperture 
                      => ParamInfo(ApertureGroup,  Bool,                  "Does moving the element move the aperture?"),
  :x_limit            => ParamInfo(ApertureGroup,  Vector{Number},        "2-Vector of horizontal aperture limits.", "m"),
  :y_limit            => ParamInfo(ApertureGroup,  Vector{Number},        "2-Vector of vertical aperture limits.", "m"),

  :r_floor            => ParamInfo(FloorPositionGroup, Vector{Number},    "3-vector of element floor position.", "m", :r),
  :q_floor            => ParamInfo(FloorPositionGroup, Vector{Number},    "Element quaternion orientation.", "", :q),
  :theta_floor        => ParamInfo(FloorPositionGroup, Number,            "Element floor theta angle orientation", "rad", :theta),
  :phi_floor          => ParamInfo(FloorPositionGroup, Number,            "Element floor phi angle orientation", "rad", :phi),
  :psi_floor          => ParamInfo(FloorPositionGroup, Number,            "Element floor psi angle orientation", "rad", :psi),

  :origin_ele         => ParamInfo(GirderGroup,     Ele,                  "Coordinate reference element."),
  :origin_ele_ref_pt  => ParamInfo(GirderGroup,     StreamLocationSwitch,     "Reference location on reference element. Default is Center."),
  :dr_girder          => ParamInfo(GirderGroup,     Vector{Number},       "3-vector of girder position with respect to ref ele.", "m", :dr),
  :dtheta_girder      => ParamInfo(GirderGroup,     Number,               "Theta angle orientation with respect to ref ele.", "rad", :dtheta),
  :dphi_girder        => ParamInfo(GirderGroup,     Number,               "Phi angle orientation with respect to ref ele.", "rad", :dphi),
  :dpsi_girder        => ParamInfo(GirderGroup,     Number,               "Psi angle orientation with respect to ref ele.", "rad", :dpsi),

  :ksol               => ParamInfo(SolenoidGroup,   Number,               "Solenoid strength.", "1/m"),
  :bsol_field         => ParamInfo(SolenoidGroup,   Number,               "Solenoid field.", "T"),

  :slave              => ParamInfo(ControlSlaveGroup, Vector{ControlSlave}, "Controlled parameters info."),
  :variable           => ParamInfo(ControlVarGroup,   Vector{ControlVar},   "Controller variables."),

  :slave_status       => ParamInfo(LordSlaveGroup,    SlaveStatusSwitch,    "Slave status."),
  :lord_status        => ParamInfo(LordSlaveGroup,    LordStatusSwitch,     "Lord status."),

  :twiss              => ParamInfo(InitTwissGroup,    InitTwissGroup,           "Initial Twiss parameters."),

  :spin               => ParamInfo(InitParticleGroup,   Vector{Number},     "Initial particle spin"),
  :orbit              => ParamInfo(InitParticleGroup,   Vector{Number},     "Initial particle position."),
)

for (key, info) in ele_param_info_dict
  if info.struct_sym == :XXX; info.struct_sym = key; end
  info.user_sym = key
end

#---------------------------------------------------------------------------------------------------
# has_parent_group

function has_parent_group(pinfo::ParamInfo, group::Type{T}) where T <: EleParameterGroup
  if typeof(pinfo.parent_group) <: Vector
    return group in pinfo.parent_group
  else
    return group == pinfo.parent_group
  end
end

#---------------------------------------------------------------------------------------------------
# struct_sym_to_user_sym

"""
Map struct symbol to user symbol(s). Example: `:r` => `[:r_floor]`.
A vector is used since the struct symbol maps to multiple user symbols.
This mapping only covers stuff in ele_param_info_dict so this mapping does not, for example, cover multipoles.
""" struct_sym_to_user_sym

struct_sym_to_user_sym = Dict{Symbol,Any}()

for (param, info) in ele_param_info_dict
  if info.struct_sym in keys(struct_sym_to_user_sym)
    push!(struct_sym_to_user_sym[info.struct_sym], param)
  else
    struct_sym_to_user_sym[info.struct_sym] = [param]
  end
end

#---------------------------------------------------------------------------------------------------
# units

"""
    units(param::Symbol) -> units::String
    units(param::Symbol, eletype::Type{T}) where T <: Ele -> units::String

Returns the units associated with symbol. EG: `m` (meters) for `param` = `:L`.
`param` may correspond to either a user symbol or struct symbol.
""" units

function units(param::Symbol)
  info = ele_param_info(param, throw_error = false, include_struct_syms = true)
  if isnothing(info); (return "?units?"); end
  return info.units
end

#-

function units(param::Symbol, eletype::Type{T}) where T <: Ele
  if eletype == Controller || eletype == Ramper
    return ""
  else
    return units(param)
  end
end

#---------------------------------------------------------------------------------------------------
# description

function description(key)
  param_info = ele_param_info(key)
  if isnothing(param_info); return "???"; end
  return param_info.description
end

function description(key, eletype::Type{T}) where T <: Ele
  if eletype == Controller || eletype == Ramper
    return "" 
  else
    return description(key)
  end
end

#---------------------------------------------------------------------------------------------------
# multipole_type

"""
    function multipole_type(sym::Symbol) -> (type::String, order::Int, group::Type{T}
    function multipole_type(str::AbstractString}) -> (type::String, order::Int, group::Type{T}
                                   where T <: Union{BMultipoleGroup,EMultipoleGroup,Nothing}

If `str` is a multipole parameter name like `Kn2L` or `Etilt`,
`order` will be the multipole order and `type` will be one of:
 - "Kn", "KnL", "Ks" "KsL", "Bn", "BnL", "Bs", "BsL", "tilt", "En", "EnL", "Es", "EsL", or "Etilt"

If `str` is not a valid multipole parameter name, returned will be `("", -1, Nothing)`.
""" multipole_type

function multipole_type(str::AbstractString) 
  isbad = ("", -1, Nothing)
  if length(str) < 3 ; isbad; end

  if length(str) > 4 && str[1:4] == "tilt"
    order = tryparse(Int,   str[5:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("tilt", order, BMultipoleGroup)
  elseif length(str) > 5 && str[1:5] == "Etilt"
    order = tryparse(Int,   str[6:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("Etilt", order, EMultipoleGroup)
  end

  if str[1:2] in Set(["Kn", "Ks", "Bn", "Bs"])
    group = BMultipoleGroup
  elseif str[1:2] in Set(["En", "Es"])
    group = EMultipoleGroup
  else
    return isbad
  end

  if str[end] == 'L'
    order = tryparse(Int,   str[3:end-1]) 
    str = str[1:2] * 'L'
  else
    order = tryparse(Int,   str[3:end]) 
    str = str[1:2]
  end

  isnothing(order) || order < 0 ? (return is_bad) : return (str, order, group)
end

!-

multipole_type(sym::Symbol) = multipole_type(string(sym))

#---------------------------------------------------------------------------------------------------
# multipole_param_info

"""

""" multipole_param_info

function multipole_param_info(sym::Symbol)
  (mtype, order, group) = multipole_type(sym)
  if group == Nothing; return nothing; end

  n = length(mtype)
  if n == 4 && mtype[1:4] == "tilt"
    return ParamInfo(BMultipoleGroup, Number, f"Magnetic multipole tilt for order {order}", "rad", :tilt, sym)
  end
  if n == 5 && mtype[1:5] == "Etilt"
    return ParamInfo(EMultipoleGroup, Number, f"Electric multipole tilt for order {order}", "rad", :tilt, sym)
  end

  mtype[2] == "s" ? str = "Skew," : str = "Normal (non-skew)"
  insym = Symbol(mtype[1:2])

  if mtype[end] == 'L'
    str = str * " length-integrated,"
    order = order - 1
  end

  if mtype[1] == 'K'
    if order == -1; units = ""
    else;           units = f"1/m^{order+1}"
    end

    return ParamInfo(BMultipoleGroup, Number, f"{str}, momentum-normalized magnetic multipole.", units, insym, sym)

  elseif mtype[1] == 'B'
    if order == -1;    units = "T*m"
    elseif order == 0; units = "T"
    else;              units = f"T/m^{order}"
    end

    return ParamInfo(BMultipoleGroup, Number, f"{str} magnetic field multipole.", units, insym, sym)

  elseif mtype[1] == 'E'
    if order == -1; units = "V"
    else;           units = f"V/m^{order+1}"
    end

    return ParamInfo(EMultipoleGroup, Number, f"{str} electric field multipole.", units, insym, sym) 
  end
end

!-

multipole_param_info(str::AbstractString) = multipole_param_info(Symbol(str))

#---------------------------------------------------------------------------------------------------
# ele_param_info

"""
    ele_param_info(sym::Symbol; throw_error = true, include_struct_syms = false)

Returns information on the element parameter `sym`.
Returns a `ParamInfo` struct. If no information on `sym` is found, an error is thrown
or `nothing` is returned.
""" ele_param_info(sym::Symbol; throw_error = true, include_struct_syms = false)

function ele_param_info(sym::Symbol; throw_error = true, include_struct_syms = false)
  if haskey(ele_param_info_dict, sym); (return ele_param_info_dict[sym]); end
  if include_struct_syms && sym in keys(struct_sym_to_user_sym)
    return ele_param_info_dict[struct_sym_to_user_sym[sym][1]]
  end

  # Is a multipole? Otherwise unrecognized.
  info = multipole_param_info(sym)
  if isnothing(info) && throw_error; error(f"Unrecognized element parameter: {sym}"); end
  return info
end

#-

"""
    ele_param_info(sym::Symbol, ele::Ele; throw_error = true)

Returns information on the element parameter `sym`.
Returns a `ParamInfo` struct. If no information on `sym` is found or `sym` is not a parameter of `ele`, 
an error is thrown or `nothing` is returned.
""" ele_param_info(sym::Symbol, ele::Ele; throw_error = true)

function ele_param_info(sym::Symbol, ele::Ele; throw_error = true)
  param_info = ele_param_info(sym, throw_error = throw_error)

  if typeof(param_info.parent_group) <: Vector
    for parent in param_info.parent_group
      if parent in param_groups_list[typeof(ele)]
        param_info.parent_group = parent
        return param_info
      end
    end
    
    error(f"Symbol {sym} not in element {ele_name(ele)} which is of type {typeof(ele)}")

  else
    if param_info.parent_group in param_groups_list[typeof(ele)] || 
                                        param_info.parent_group == Nothing; return param_info; end
    error(f"Symbol {sym} not in element {ele_name(ele)} which is of type {typeof(ele)}")   
  end
end

#---------------------------------------------------------------------------------------------------
# set_integrated!

"""
Set whether multipoles values correspond to integrated or non-integrated.
The existing multipole values will be translated appropriately.

If there are no multipoles corresponding to `order`, nothing is done.
"""

function set_integrated!(ele::Ele, group::BMultipoleGroup, order::Int, integrated::Bool)
  mul = multipole!(BMultipoleGroup, order)
  if isnothing(mul); return; end
  if integrated == mul.integrated; return; end

  L = ele.L
  if integrated
    mul.Kn = mul.Kn * L
    mul.Ks = mul.Ks * L
    mul.Bn = mul.Bn * L
    mul.Bs = mul.Bs * L
  else
    if L == 0
      error(f"Cannot convert from integrated multipole to non-integrated for element of zero length: {ele_name(ele)}")
    end
    mul.Kn = mul.Kn / L
    mul.Ks = mul.Ks / L
    mul.Bn = mul.Bn / L
    mul.Bs = mul.Bs / L
  end

  mul.integrated = integrated
end

function set_integrated!(ele::Ele, group::EMultipoleGroup, order::Int, integrated::Bool)
  mul = multipole!(EMultipoleGroup, order)
  if isnothing(mul); return; end
  if integrated == mul.integrated; return; end

  L = ele.L
  if integrated
    mul.En = mul.En * L
    mul.Es = mul.Es * L
  else
    if L == 0
      error(f"Cannot convert from integrated multipole to non-integrated for element of zero length: {ele_name(ele)}")
    end
    mul.En = mul.En / L
    mul.Es = mul.Es / L
  end

  mul.integrated = integrated
end

#---------------------------------------------------------------------------------------------------
# param_groups_list

"""
Table of what element groups are associated with what element types.
Order is important. Bookkeeping routines rely on: 
 - `LengthGroup` being first (`LengthGroup` bookkeeping may be done a second time if `BendGroup` modifies `L`).
 - `BendGroup` after `ReferenceGroup` and `MasterGroup` (in case the reference energy is changing).
 - `BMultipoleGroup` and `EMultipoleGroup` after `MasterGroup` (in case the reference energy is changing).
 - `RFGroup` comes last (triggers autoscale/autophase and `ReferenceGroup` correction).
""" param_groups_list

base_group_list = [LengthGroup, LordSlaveGroup, StringGroup, ReferenceGroup, FloorPositionGroup, TrackingGroup]
alignment_group_list = [AlignmentGroup, ApertureGroup]
multipole_group_list = [MasterGroup, BMultipoleGroup, EMultipoleGroup]
general_group_list = [base_group_list..., alignment_group_list..., multipole_group_list...]

param_groups_list = Dict(  
  Dict(
    BeginningEle   => [base_group_list..., InitTwissGroup, InitParticleGroup],
    Bend           => [general_group_list..., BendGroup],
    Controller     => [ControlVarGroup, ControlSlaveGroup],
    Drift          => [base_group_list...],
    LCavity        => [general_group_list..., RFMasterGroup, LCavityGroup, RFGroup],
    Marker         => [base_group_list...],
    Octupole       => [general_group_list...],
    Patch          => [base_group_list..., PatchGroup],
    Quadrupole     => [general_group_list...],
    RFCavity       => [general_group_list..., RFMasterGroup, RFFieldGroup, RFGroup],
    Sextupole      => [general_group_list...],
    UnionEle       => [base_group_list..., alignment_group_list...],
  )
)

param_group_info = Dict(
  AlignmentGroup        => "Element position/orientation shift.",
  ApertureGroup         => "Vacuum chamber aperture.",
  BendGroup             => "Bend element parameters.",
  BMultipoleGroup       => "Magnetic multipoles.",
  BMultipole1           => "Magnetic multipole of given order. Contained in BMultipoleGroup",
  ChamberWallGroup      => "Vacuum chamber wall.",
  ControlSlaveGroup     => "Controller or Ramper slave parameters.",
  ControlVarGroup       => "Controller or Ramper Variables.",
  EMultipoleGroup       => "Electric multipoles.",
  EMultipole1           => "Electric multipole of given order. Contained in EMultipoleGroup.",
  FloorPositionGroup    => "Global floor position and orientation.",
  GirderGroup           => "Girder parameters.",
  InitParticleGroup     => "Initial particle position and spin.",
  InitTwissGroup        => "Initial Twiss and coupling parameters.",
  LCavityGroup          => "Accelerating cavity parameters.",
  LengthGroup           => "Length and s-position parameters.",
  LordSlaveGroup        => "Element lord and slave status.",
  MasterGroup           => "Contains field_master parameter.",
  PatchGroup            => "Patch parameters.",
  ReferenceGroup        => "Reference energy and species.",
  RFGroup               => "RF parameters.",
  RFMasterGroup         => "Contains voltage_master, do_auto_map, and do_auto_phase.",
  SolenoidGroup         => "Solenoid parameters.",
  StringGroup           => "Informational strings.",
  TrackingGroup         => "Default tracking settings.",
)

#---------------------------------------------------------------------------------------------------
# multipole!

"""
    multipole!(mgroup, order; insert::Bool = false) -> 

Finds multipole of a given order.

Returns `nothing` if `vec` array does not contain element with n = `order` and `insert` = `nothing`.
""" multipole!

function multipole!(mgroup, order; insert::Bool = false)
  if order < 0; return nothing; end
  ix = multipole_index(mgroup.vec, order)

  if !insert
    if ix > length(mgroup.vec) || order != mgroup.vec[ix].order; return nothing; end
    return mgroup.vec[ix]
  end

  if ix > length(mgroup.vec) 
    ix = length(mgroup.vec) + 1
    insert!(mgroup.vec, ix, eltype(mgroup.vec)())
    mgroup.vec[ix].order = order
  elseif mgroup.vec[ix].order != order
    insert!(mgroup.vec, ix, eltype(mgroup.vec)())
    mgroup.vec[ix].order = order
  end

  return mgroup.vec[ix]
end

#---------------------------------------------------------------------------------------------------
# multipole_index

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
    if vec[ix].order >= order; return ix; end
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
  :ix_branch   => ParamInfo(Nothing, Int,               "Index of branch in containing lat .branch[] array"),
  :geometry    => ParamInfo(Nothing, EleGeometrySwitch, "Open or closed Geometry"),
  :lat         => ParamInfo(Nothing, Pointer,           "Pointer to lattice containing the branch."),
  :type        => ParamInfo(Nothing, BranchType,        "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => ParamInfo(Nothing, Pointer,           "Element that forks to this branch."),
  :live_branch => ParamInfo(Nothing, Bool,              "Used by programs to turn on/off tracking in a branch."),
  :ref_species => ParamInfo(Species, String,            "Reference tracking species."),
)

#---------------------------------------------------------------------------------------------------
# Bases.copy(x::T) where {T <: EleParameterGroup} 

"""
Copy for a normal element parameter group is equivalent to a deep copy.
The only reason not to have copy != deepcopy is when the group has a lot of data. Think field table.
"""

Base.copy(x::T) where {T <: EleParameterGroup} = T([deepcopy(getfield(x, k)) for k ∈ fieldnames(T)]...)

