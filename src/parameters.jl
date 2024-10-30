#---------------------------------------------------------------------------------------------------
# ParamInfo

"""
Holds information for a single element parameter.

Possible `kind` values: String, Int, Number, Vector{Number}, Bool, Pointer, etc.

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

`sub_struct` component of ParamInfo is needed, for example, for `a_beta` which needs to be mapped 
to `Twiss.a.beta` which is 2 levels down from parent struct Twiss.
""" ParamInfo

abstract type Pointer end

@kwdef mutable struct ParamInfo
  parent_group::T where T <: Union{DataType,Vector}    # Use the parent_group function to get the parent group.
  kind::Union{T, Union, UnionAll} where T <: DataType  # Something like Aperture is a Union.
  description::String = ""
  units::String = ""
  struct_sym::Symbol                                 # Symbol in struct.
  sub_struct::Union{Function, Nothing}               # Used if parameter parent is not parent_group. 
                                                     #    EG: Twiss.a.beta and sub_struct = T -> T.a
  user_sym::Symbol                                   # Symbol used to construct elements.
end


# `:XXX` indicates that the struct_sym will be the same as the key in ELE_PARAM_INFO_DICT.
# `:Z` is always replaced by the key in ELE_PARAM_INFO_DICT.

ParamInfo(parent, kind, description) = ParamInfo(parent, kind, description, "", :XXX, nothing, :Z)
ParamInfo(parent, kind, description, units) = ParamInfo(parent, kind, description, units, :XXX, nothing, :Z)
ParamInfo(parent, kind, description, units, struct_sym) = ParamInfo(parent, kind, description, units, struct_sym, nothing, :Z)
ParamInfo(parent, kind, description, units, struct_sym, sub_struct) = ParamInfo(parent, kind, description, units, struct_sym, sub_struct, :Z)

#---------------------------------------------------------------------------------------------------
# ELE_PARAM_INFO_DICT

# Note: ":XXX" will get replaced by the key (user name) below so that, for example, 
# ELE_PARAM_INFO_DICT[:field_master].struct_sym will have the value :field_master.

"""
Dictionary of parameter types. Keys are user names (which can be different from corresponding group name). 
EG: theta_floor user name corresponds to theta in the FloorPositionGroup.
""" ELE_PARAM_INFO_DICT

ELE_PARAM_INFO_DICT = Dict(
  :name               => ParamInfo(Nothing,        String,        "Name of the element."),
  :ix_ele             => ParamInfo(Nothing,        Int,           "Index of element in containing branch.ele[] array."),
  :branch             => ParamInfo(Nothing,        Branch,        "Pointer to branch element is in."),
  :multipass_lord     => ParamInfo(Nothing,        Ele,           "Element's multipass_lord. Will not be present if no lord exists."),
  :super_lords        => ParamInfo(Nothing,        Vector{Ele},   "Array of element's super_lords. Will not be present if no lords exist."),
  :slaves             => ParamInfo(Nothing,        Vector{Ele},   "Array of slaves of element. Will not be present if no slaves exist."),
  :amp_function       => ParamInfo(Nothing,        Function,      "Amplitude function."),

  :offset             => ParamInfo([AlignmentGroup,PatchGroup], Vector{Number}, "[x, y, z] element offset.", "m"),
  :x_rot              => ParamInfo([AlignmentGroup,PatchGroup], Number,         "X-axis element rotation.", "rad"),
  :y_rot              => ParamInfo([AlignmentGroup,PatchGroup], Number,         "Y-axis element rotation.", "rad"),
  :tilt               => ParamInfo([AlignmentGroup,PatchGroup], Number,         "Z-axis element rotation.", "rad"),

  :offset_tot         => ParamInfo(AlignmentGroup, Vector{Number}, "[x, y, z] element offset including Girder orientation.", "m"),
  :x_rot_tot          => ParamInfo(AlignmentGroup, Number,         "X-axis element rotation including Girder orientation.", "rad"),
  :y_rot_tot          => ParamInfo(AlignmentGroup, Number,         "Y-axis element rotation including Girder orientation.", "rad"),
  :tilt_tot           => ParamInfo(AlignmentGroup, Number,         "Z-axis element rotation including Girder orientation.", "rad"),

  :type               => ParamInfo(StringGroup,    String,        "Type of element. Set by User and ignored the code."),
  :alias              => ParamInfo(StringGroup,    String,        "Alias name. Set by User and ignored by the code."),
  :description        => ParamInfo(StringGroup,    String,        "Descriptive info. Set by User and ignored by the code."),

  :L                  => ParamInfo(LengthGroup,    Number,        "Element length.", "m"),
  :orientation        => ParamInfo(LengthGroup,    Int,           "Longitudinal orientation of element. May be +1 or -1."),
  :s                  => ParamInfo(LengthGroup,    Number,        "Longitudinal s-position at the upstream end.", "m"),
  :s_downstream       => ParamInfo(LengthGroup,    Number,        "Longitudinal s-position at the downstream end.", "m"),

  :is_on              => ParamInfo(MasterGroup,    Bool,          "Element fields on/off."),
  :field_master       => ParamInfo(MasterGroup,    Bool,          "True: fields are fixed and normalized values change when varying ref energy."),
  :multipass_lord_sets_ref_energy => ParamInfo(MasterGroup, Bool, "True: If element is a multipass lord, ref energy is set in lord."),

  :species_ref          => ParamInfo(ReferenceGroup, Species,     "Reference species."),
  :species_ref_exit     => ParamInfo(ReferenceGroup, Species,     "Reference species at exit end."),
  :pc_ref               => ParamInfo(ReferenceGroup, Number,      "Reference momentum * c.", "eV"),
  :E_tot_ref            => ParamInfo(ReferenceGroup, Number,      "Reference total energy.", "eV"),
  :time_ref             => ParamInfo(ReferenceGroup, Number,      "Reference time.", "sec"),
  :pc_ref_downstream    => ParamInfo(ReferenceGroup, Number,      "Reference momentum * c at downstream end.", "eV"),
  :E_tot_ref_downstream => ParamInfo(ReferenceGroup, Number,      "Reference total energy at downstream end.", "eV"),
  :time_ref_downstream  => ParamInfo(ReferenceGroup, Number,      "Reference time at downstream end.", "sec"),
  :β_ref                => ParamInfo(ReferenceGroup, Number,      "Reference velocity/c."),
  :β_ref_downstream     => ParamInfo(ReferenceGroup, Number,      "Reference velocity/c at downstream end."),

  :angle              => ParamInfo(BendGroup,      Number,        "Design bend angle", "rad"),
  :bend_field         => ParamInfo(BendGroup,      Number,        "Design bend field corresponding to g bending strength", "T"),
  :bend_field_tot     => ParamInfo(BendGroup,      Number,        "Total bend field corresponding to g_tot bending strength", "T"),
  :rho                => ParamInfo(BendGroup,      Number,        "Design bend radius", "m"),
  :g                  => ParamInfo(BendGroup,      Number,        "Design bend strength (1/rho)", "1/m"),
  :g_tot              => ParamInfo(BendGroup,      Number,        "Total bend strength", "1/m"),
  :e1                 => ParamInfo(BendGroup,      Number,        "Bend entrance face angle.", "rad"),
  :e2                 => ParamInfo(BendGroup,      Number,        "Bend exit face angle.", "rad"),
  :e1_rect            => ParamInfo(BendGroup,      Number,        "Bend entrance face angles relative to a rectangular geometry.", "rad"),
  :e2_rect            => ParamInfo(BendGroup,      Number,        "Bend exit face angles relative to a rectangular geometry.", "rad"),
  :L_chord            => ParamInfo(BendGroup,      Number,        "Bend chord length.", "m"),
  :L_sagitta          => ParamInfo(BendGroup,      Number,        "Bend sagitta length.", "m"),
  :L_rectangle        => ParamInfo(BendGroup,      Number,        "Rectangular length", "m"),
  :ref_tilt           => ParamInfo(BendGroup,      Number,        "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint               => ParamInfo(Nothing,        Number,        "Used to set fint1 and fint2 both at once.", ""),
  :fint1              => ParamInfo(BendGroup,      Number,        "Bend entrance edge field integral.", ""),
  :fint2              => ParamInfo(BendGroup,      Number,        "Bend exit edge field integral.", ""),
  :hgap               => ParamInfo(Nothing,        Number,        "Used to set hgap1 and hgap2 both at once.", ""),
  :hgap1              => ParamInfo(BendGroup,      Number,        "Bend entrance edge pole gap height.", "m"),
  :hgap2              => ParamInfo(BendGroup,      Number,        "Bend exit edge pole gap height.", "m"),
  :bend_type          => ParamInfo(BendGroup,      BendType.T,    "Sets the \"logical\" shape of a bend."),
  :fiducial_pt        => ParamInfo(BendGroup,      FiducialPt.T,  "Fiducial point used with variation of bend parameters."),
  :exact_multipoles   => ParamInfo(BendGroup,      ExactMultipoles.T, "Are multipoles treated exactly?"),

  :E_tot_offset       => ParamInfo(PatchGroup,     Number,         "Reference energy offset.", "eV"),
  :E_tot_exit         => ParamInfo(PatchGroup,     Number,         "Reference energy at exit end.", "eV"),
  :pc_exit            => ParamInfo(PatchGroup,     Number,         "Reference momentum at exit end.", "eV"),
  :L_user             => ParamInfo(PatchGroup,     Number,         "User set length.", "m"),
  :flexible           => ParamInfo(PatchGroup,     Bool,           "Flexible patch?"),
  :ref_coords         => ParamInfo(PatchGroup,     BodyLoc.T,      "Patch coords with respect to BodyLoc.ENTRANCE_END or BodyLoc.EXIT_END?"),

  :voltage            => ParamInfo(RFCavityGroup,   Number,        "RF voltage.", "volt"),
  :gradient           => ParamInfo(RFCavityGroup,   Number,        "RF gradient.", "volt/m"),
  :phase              => ParamInfo(RFCavityGroup,   Number,        "RF phase.", "rad"),

  :multipass_phase    => ParamInfo(RFCommonGroup,   Number,    
                                  "RF phase which can differ from multipass element to multipass element.", "rad"),
  :frequency          => ParamInfo(RFCommonGroup,   Number,        "RF frequency.", "Hz"),
  :harmon             => ParamInfo(RFCommonGroup,   Number,        "RF frequency harmonic number.", ""),
  :cavity_type        => ParamInfo(RFCommonGroup,   Cavity.T,      "Type of cavity."),
  :n_cell             => ParamInfo(RFCommonGroup,   Int,           "Number of RF cells."),

  :voltage_ref        => ParamInfo(LCavityGroup,   Number,         "Reference RF voltage.", "volt"),
  :voltage_err        => ParamInfo(LCavityGroup,   Number,         "RF voltage error.", "volt"),
  :voltage_tot        => ParamInfo(LCavityGroup,   Number,         "Actual RF voltage (ref + err).", "volt"),
  :gradient_ref       => ParamInfo(LCavityGroup,   Number,         "Reference RF gradient.", "volt/m"),
  :gradient_err       => ParamInfo(LCavityGroup,   Number,         "RF gradient error.", "volt/m"),
  :gradient_tot       => ParamInfo(LCavityGroup,   Number,         "Actual RF gradient (ref + err).", "volt/m"),
  :phase_ref          => ParamInfo(LCavityGroup,   Number,         "Reference RF phase.", "rad"),
  :phase_err          => ParamInfo(LCavityGroup,   Number,         "RF phase error.", "rad"),
  :phase_tot          => ParamInfo(LCavityGroup,   Number,         "Actual RF phase. (ref + err)", "rad"),

  :voltage_master     => ParamInfo(RFAutoGroup,    Bool,           "Voltage or gradient is constant with length changes?"),
  :auto_amp           => ParamInfo(RFAutoGroup,    Number,    
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :auto_phase         => ParamInfo(RFAutoGroup,    Number,         "Correction RF phase calculated by the auto scale code.", "rad"),
  :do_auto_amp        => ParamInfo(RFAutoGroup,    Bool,           "Autoscale voltage/gradient?"),
  :do_auto_phase      => ParamInfo(RFAutoGroup,    Bool,           "Autoscale phase?"),

  :num_steps          => ParamInfo(TrackingGroup,  Int,               "Nominal number of tracking steps."),
  :ds_step            => ParamInfo(TrackingGroup,  Number,            "Nominal distance between tracking steps.", "m"),

  :aperture_shape     => ParamInfo(ApertureGroup,  ApertureShape,     "Aperture shape. Default is ELLIPTICAL."),
  :aperture_at        => ParamInfo(ApertureGroup,  BodyLoc.T,         "Aperture location. Default is BodyLoc.ENTRANCE_END."),
  :misalignment_moves_aperture 
                      => ParamInfo(ApertureGroup,  Bool,              "Element movement moves aperture?"),
  :x_limit            => ParamInfo(ApertureGroup,  Vector{Number},    "Min/Max horizontal aperture limits.", "m"),
  :y_limit            => ParamInfo(ApertureGroup,  Vector{Number},    "Min/Max vertical aperture limits.", "m"),
  :section            => ParamInfo(ApertureGroup,  WallSection,       "Array of aperture vertices."),
  :custom_aperture    => ParamInfo(ApertureGroup,  Dict,              "Custom aperture info."),

  :r_floor            => ParamInfo(FloorPositionGroup, Vector{Number}, "3-vector of element floor position.", "m", :r),
  :q_floor            => ParamInfo(FloorPositionGroup, Quat,           "Element quaternion orientation.", "", :q),

  :eles               => ParamInfo(GirderGroup,     Vector{Ele},      "Array of supported elements."),
  :origin_ele         => ParamInfo(GirderGroup,     Ele,              "Coordinate reference element."),
  :origin_ele_ref_pt  => ParamInfo(GirderGroup,     Loc.T,            "Reference location on reference element. Default is Loc.CENTER."),
  :dr                 => ParamInfo(GirderGroup,     Vector{Number},   "3-vector of girder position with respect to ref ele.", "m"),
  :dq                 => ParamInfo(GirderGroup,     Quat,             "Quaternion orientation with respect to ref ele."),

  :Ksol               => ParamInfo(SolenoidGroup,   Number,           "Solenoid strength.", "1/m"),
  :Bsol               => ParamInfo(SolenoidGroup,   Number,           "Solenoid field.", "T"),

  :slave_status       => ParamInfo(LordSlaveStatusGroup,    Slave.T,        "Slave status."),
  :lord_status        => ParamInfo(LordSlaveStatusGroup,    Lord.T,         "Lord status."),

  :spin               => ParamInfo(InitParticleGroup, Vector{Number}, "Initial particle spin"),
  :orbit              => ParamInfo(InitParticleGroup, Vector{Number}, "Initial particle position."),

  :beta               => ParamInfo(Twiss1,      Number,             "Beta Twiss parameter.", "m"),
  :alpha              => ParamInfo(Twiss1,      Number,             "Alpha Twiss parameter.", ""),
  :gamma              => ParamInfo(Twiss1,      Number,             "Gamma Twiss parameter.", "1/m"),
  :phi                => ParamInfo(Twiss1,      Number,             "Betatron phase.", "rad"),
  :eta                => ParamInfo(Twiss1,      Number,             "Position dispersion.", "m"),
  :etap               => ParamInfo(Twiss1,      Number,             "Momentum dispersion.", ""),
  :deta_ds            => ParamInfo(Twiss1,      Number,             "Dispersion derivative.", ""),

  :twiss              => ParamInfo(TwissGroup,  TwissGroup,         "Initial Twiss parameters."),

  :beta_a             => ParamInfo(TwissGroup,  Number,             "A-mode beta Twiss parameter.", "m", :beta, T->T.a),
  :alpha_a            => ParamInfo(TwissGroup,  Number,             "A-mode alpha Twiss parameter.", "", :alpha, T->T.a),
  :gamma_a            => ParamInfo(TwissGroup,  Number,             "A-mode gamma Twiss parameter.", "1/m", :gamma, T->T.a),
  :phi_a              => ParamInfo(TwissGroup,  Number,             "A-mode betatron phase.", "rad", :phi, T->T.a),
  :eta_a              => ParamInfo(TwissGroup,  Number,             "A-mode position dispersion.", "m", :eta, T->T.a),
  :etap_a             => ParamInfo(TwissGroup,  Number,             "A-mode momentum dispersion.", "", :etap, T->T.a),
  :deta_ds_a          => ParamInfo(TwissGroup,  Number,             "A-mode dispersion derivative.", "", :deta_ds, T->T.a),

  :beta_b             => ParamInfo(TwissGroup,  Number,             "B-mode beta Twiss parameter.", "m", :beta, T->T.b),
  :alpha_b            => ParamInfo(TwissGroup,  Number,             "B-mode alpha Twiss parameter.", "", :alpha, T->T.b),
  :gamma_b            => ParamInfo(TwissGroup,  Number,             "B-mode gamma Twiss parameter.", "1/m", :gamma, T->T.b),
  :phi_b              => ParamInfo(TwissGroup,  Number,             "B-mode betatron phase.", "rad", :phi, T->T.b),
  :eta_b              => ParamInfo(TwissGroup,  Number,             "B-mode position dispersion.", "m", :eta, T->T.b),
  :etap_b             => ParamInfo(TwissGroup,  Number,             "B-mode momentum dispersion.", "", :etap, T->T.b),
  :deta_ds_b          => ParamInfo(TwissGroup,  Number,             "B-mode dispersion derivative.", "", :deta_ds, T->T.b),

  :beta_c             => ParamInfo(TwissGroup,  Number,             "C-mode beta Twiss parameter.", "m", :beta, T->T.c),
  :alpha_c            => ParamInfo(TwissGroup,  Number,             "C-mode alpha Twiss parameter.", "", :alpha, T->T.c),
  :gamma_c            => ParamInfo(TwissGroup,  Number,             "C-mode gamma Twiss parameter.", "1/m", :gamma, T->T.c),
  :phi_c              => ParamInfo(TwissGroup,  Number,             "C-mode betatron phase.", "rad", :phi, T->T.c),
  :eta_c              => ParamInfo(TwissGroup,  Number,             "C-mode position dispersion.", "m", :eta, T->T.c),
  :etap_c             => ParamInfo(TwissGroup,  Number,             "C-mode momentum dispersion.", "", :etap, T->T.c),
  :deta_ds_c          => ParamInfo(TwissGroup,  Number,             "C-mode dispersion derivative.", "", :deta_ds, T->T.c),

  :eta_x              => ParamInfo(TwissGroup,  Number,             "X-mode position dispersion.", "m", :eta, T->T.x),
  :etap_x             => ParamInfo(TwissGroup,  Number,             "X-mode momentum dispersion.", "", :etap, T->T.x),
  :deta_ds_x          => ParamInfo(TwissGroup,  Number,             "X-mode dispersion derivative.", "", :deta_ds, T->T.x),

  :eta_y              => ParamInfo(TwissGroup,  Number,             "Y-mode position dispersion.", "m", :eta, T->T.y),
  :etap_y             => ParamInfo(TwissGroup,  Number,             "Y-mode momentum dispersion.", "", :etap, T->T.y),
  :deta_ds_y          => ParamInfo(TwissGroup,  Number,             "Y-mode dispersion derivative.", "", :deta_ds, T->T.y),
)

for (key, info) in ELE_PARAM_INFO_DICT
  if info.struct_sym == :XXX; info.struct_sym = key; end
  info.user_sym = key
end

#---------------------------------------------------------------------------------------------------
# has_parent_group

function has_parent_group(pinfo::ParamInfo, group::Type{T}) where T <: BaseEleParameterGroup
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
This mapping only covers stuff in ELE_PARAM_INFO_DICT so this mapping does not, for example, cover multipoles.
""" struct_sym_to_user_sym

struct_sym_to_user_sym = Dict{Symbol,Any}()

for (param, info) in ELE_PARAM_INFO_DICT
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
  if param in Symbol.(keys(AcceleratorLattice.ELE_PARAM_GROUP_INFO)); return ""; end
  if isnothing(info); (return "?units?"); end
  return info.units
end

#-

function units(param::Symbol, eletype::Type{T}) where T <: Ele
  return units(param)
end

#---------------------------------------------------------------------------------------------------
# description

function description(key)
  param_info = ele_param_info(key)
  if isnothing(param_info); return "???"; end
  return param_info.description
end

function description(key, eletype::Type{T}) where T <: Ele
  return description(key)
end

#---------------------------------------------------------------------------------------------------
# multipole_type

"""
    function multipole_type(sym::Symbol) -> (type::String, order::Int, group_type::Type{T})
    function multipole_type(str::AbstractString}) -> (type::String, order::Int, group_type::Type{T})
                                   where T <: Union{BMultipoleGroup,EMultipoleGroup,Nothing}

If `str` is a multipole parameter name like `Kn2L` or `Etilt`,
`order` will be the multipole order and `type` will be one of:
 - "Kn", "KnL", "Ks" "KsL", "Bn", "BnL", "Bs", "BsL", "tilt", "integrated"
"En", "EnL", "Es", "EsL", "Etilt", "Eintegrated"

If `str` is not a valid multipole parameter name, returned will be `("", -1, Nothing)`.
""" multipole_type

function multipole_type(str::AbstractString)
  isbad = ("", -1, Nothing)
  if length(str) < 3 ; return isbad; end

  if length(str) > 4 && str[1:4] == "tilt"
    order = tryparse(Int,   str[5:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("tilt", order, BMultipoleGroup)
  elseif length(str) > 5 && str[1:5] == "Etilt"
    order = tryparse(Int,   str[6:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("Etilt", order, EMultipoleGroup)
  elseif length(str) > 10 && str[1:10] == "integrated"
    order = tryparse(Int,   str[11:end])
    isnothing(order) || order < 0 ? (return isbad) : return ("integrated", order, BMultipoleGroup)
  elseif length(str) > 11 && str[1:11] == "Eintegrated"
    order = tryparse(Int,   str[12:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("Eintegrated", order, EMultipoleGroup)
  end

  if str[1:2] in Set(["Kn", "Ks", "Bn", "Bs"])
    group_type = BMultipoleGroup
  elseif str[1:2] in Set(["En", "Es"])
    group_type = EMultipoleGroup
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

  isnothing(order) || order < 0 ? (return is_bad) : return (str, order, group_type)
end

!-

multipole_type(sym::Symbol) = multipole_type(string(sym))

#---------------------------------------------------------------------------------------------------
# multipole_param_info

"""
    multipole_param_info(sym::Symbol) -> ParamInfo

Returns `ParamInfo` information struct on a given multipole parameter corresponding to `sym`.

The `sub_struct` of the returned `ParamInfo` is set to nothing since the true sub-structure is 
complicated (something like `vec[J]` where `J` is not fixed).

""" multipole_param_info

function multipole_param_info(sym::Symbol)
  (mtype, order, group) = multipole_type(sym)
  if group == Nothing; return nothing; end

  if mtype == "tilt"
    return ParamInfo(BMultipoleGroup, Number, "Magnetic multipole tilt for order $order", "rad", :tilt, nothing, sym)
  elseif mtype == "Etilt"
    return ParamInfo(EMultipoleGroup, Number, "Electric multipole tilt for order $order", "rad", :tilt, nothing, sym)
  elseif mtype == "integrated"
    return ParamInfo(BMultipoleGroup, Bool, "Are stored multipoles integrated for order $order?", "", :integrated, nothing, sym)
  elseif mtype == "Eintegrated"
    return ParamInfo(EMultipoleGroup, Bool, "Are stored multipoles integrated for order $order?", "", :Eintegrated, nothing, sym)
  end

  mtype[2] == 's' ? str = "Skew" : str = "Normal (non-skew)"
  insym = Symbol(mtype[1:2])

  if mtype[end] == 'L'
    str = str * ", length-integrated"
    exp = order - 1
  else
    exp = order
  end

  if mtype[1] == 'K'
    if order == -1; units = ""
    else;           units = "1/m^$(exp+1)"
    end

    return ParamInfo(BMultipoleGroup, Number, "$str, momentum-normalized, magnetic multipole of order $order.", units, insym, nothing, sym)

  elseif mtype[1] == 'B'
    if order == -1;    units = "T*m"
    elseif order == 0; units = "T"
    else;              units = "T/m^$exp"
    end

    return ParamInfo(BMultipoleGroup, Number, "$str, magnetic field multipole of order $order.", units, insym, nothing, sym)

  elseif mtype[1] == 'E'
    if order == -1; units = "V"
    else;           units = "V/m^$(exp+1)"
    end

    return ParamInfo(EMultipoleGroup, Number, "$str, electric field multipole of order $order.", units, insym, nothing, sym) 
  end
end

!-

multipole_param_info(str::AbstractString) = multipole_param_info(Symbol(str))

#---------------------------------------------------------------------------------------------------
# ele_param_info

"""
    ele_param_info(sym::Symbol; throw_error = true, include_struct_syms = false) -> Union{ParamInfo, Nothing}
    ele_param_info(sym::Symbol, ele::Ele; throw_error = true) -> Union{ParamInfo, Nothing}

Returns information on the element parameter `sym`.
Returns a `ParamInfo` struct. If no information on `sym` is found, an error is thrown
or `nothing` is returned.
""" ele_param_info

function ele_param_info(sym::Symbol; throw_error = true, include_struct_syms = false)
  if haskey(ELE_PARAM_INFO_DICT, sym); (return ELE_PARAM_INFO_DICT[sym]); end
  if include_struct_syms && sym in keys(struct_sym_to_user_sym)
    return ELE_PARAM_INFO_DICT[struct_sym_to_user_sym[sym][1]]
  end

  # Is a multipole? Otherwise unrecognized.
  info = multipole_param_info(sym)
  if isnothing(info) && throw_error; error(f"Unrecognized element parameter: {sym}"); end
  return info
end

#

function ele_param_info(sym::Symbol, ele::Ele; throw_error = true)
  param_info = ele_param_info(sym, throw_error = throw_error)
  if isnothing(param_info); return nothing; end

  if typeof(param_info.parent_group) <: Vector
    for parent in param_info.parent_group
      if parent in PARAM_GROUPS_LIST[typeof(ele)]
        param_info.parent_group = parent
        return param_info
      end
    end
    
    error(f"Symbol {sym} not in element {ele_name(ele)} which is of type {typeof(ele)}")

  else
    if param_info.parent_group in PARAM_GROUPS_LIST[typeof(ele)] || 
                                        param_info.parent_group == Nothing; return param_info; end
    error(f"Symbol {sym} not in element {ele_name(ele)} which is of type {typeof(ele)}")   
  end
end

#---------------------------------------------------------------------------------------------------
# toggle_integrated!

"""
    toggle_integrated!(ele::Ele, field_type::FieldType, order::Int)


Set whether multipoles values correspond to integrated or non-integrated.
The existing multipole values will be translated appropriately.

If there are no multipoles corresponding to `order`, nothing is done.
""" toggle_integrated!

function toggle_integrated!(ele::Ele, ftype::Type{MAGNETIC}, order::Int)
  mul = multipole!(BMultipoleGroup, order)
  if isnothing(mul); return; end
  L = ele.L
  want_integrated = !mul.integrated

  if want_integrated
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

  mul.integrated = want_integrated
end

function toggle_integrated!(ele::Ele, ftype::Type{ELECTRIC}, order::Int)
  mul = multipole!(EMultipoleGroup, order)
  if isnothing(mul); return; end
  L = ele.L
  want_integrated = !mul.integrated

  if want_integrated
    mul.En = mul.En * L
    mul.Es = mul.Es * L
  else
    if L == 0
      error(f"Cannot convert from integrated multipole to non-integrated for element of zero length: {ele_name(ele)}")
    end
    mul.En = mul.En / L
    mul.Es = mul.Es / L
  end

  mul.integrated = want_integrated
end

#---------------------------------------------------------------------------------------------------
# PARAM_GROUPS_LIST

"""
    Dict PARAM_GROUPS_LIST

Table of what element groups are associated with what element types.
Order is important. Bookkeeping routines rely on: 
 - `LengthGroup` being first (`LengthGroup` bookkeeping may be done a second time if `BendGroup` modifies `L`).
 - `BendGroup` after `ReferenceGroup` and `MasterGroup` (in case the reference energy is changing).
 - `BMultipoleGroup` and `EMultipoleGroup` after `MasterGroup` (in case the reference energy is changing).
 - `RFCommonGroup` comes last (triggers autoscale/autophase and `ReferenceGroup` correction).
""" PARAM_GROUPS_LIST

base_group_list = [LengthGroup, LordSlaveStatusGroup, StringGroup, ReferenceGroup, FloorPositionGroup, TrackingGroup]
alignment_group_list = [AlignmentGroup, ApertureGroup]
multipole_group_list = [MasterGroup, BMultipoleGroup, EMultipoleGroup]
bmultipole_group_list = [MasterGroup, BMultipoleGroup]
general_group_list = [base_group_list..., alignment_group_list..., multipole_group_list...]

PARAM_GROUPS_LIST = Dict(  
    ACKicker            => [base_group_list..., alignment_group_list..., bmultipole_group_list...],
    BeamBeam            => [base_group_list...],
    BeginningEle        => [base_group_list..., TwissGroup, InitParticleGroup],
    Bend                => [general_group_list..., BendGroup],
    Collimator          => [base_group_list...],
    Converter           => [base_group_list...],
    CrabCavity          => [base_group_list...],
    Drift               => [base_group_list...],
    EGun                => [base_group_list...],
    Fiducial            => [base_group_list...],
    FloorShift          => [base_group_list...],
    Foil                => [base_group_list...],
    Fork                => [base_group_list...],
    Girder              => [base_group_list...],
    Instrument          => [base_group_list...],
    Kicker              => [general_group_list...],
    LCavity             => [base_group_list..., alignment_group_list..., MasterGroup, RFAutoGroup, LCavityGroup, RFCommonGroup],
    Marker              => [base_group_list...],
    Mask                => [base_group_list...],
    Match               => [base_group_list...],
    Multipole           => [general_group_list...],
    NullEle             => [],
    Octupole            => [general_group_list...],
    Patch               => [base_group_list..., PatchGroup],
    Quadrupole          => [general_group_list...],
    RFCavity            => [base_group_list..., alignment_group_list..., MasterGroup, RFAutoGroup, RFCavityGroup, RFCommonGroup],
    Sextupole           => [general_group_list...],
    Solenoid            => [general_group_list..., SolenoidGroup],
    Taylor              => [base_group_list...],
    ThickMultipole      => [general_group_list...],
    Undulator           => [base_group_list...],
    UnionEle            => [base_group_list..., alignment_group_list...],
    Wiggler             => [base_group_list...],
)

ELE_PARAM_GROUP_INFO = Dict(
  AlignmentGroup        => EleParameterGroupInfo("Element position/orientation shift.", false),
  ApertureGroup         => EleParameterGroupInfo("Vacuum chamber aperture.", false),
  BendGroup             => EleParameterGroupInfo("Bend element parameters.", true),
  BMultipoleGroup       => EleParameterGroupInfo("Magnetic multipoles.", true),
  BMultipole1           => EleParameterGroupInfo("Magnetic multipole of given order. Substructure contained in `BMultipoleGroup`", false),
  ChamberWallGroup      => EleParameterGroupInfo("Vacuum chamber wall.", false),
  EMultipoleGroup       => EleParameterGroupInfo("Electric multipoles.", false),
  EMultipole1           => EleParameterGroupInfo("Electric multipole of given order. Substructure contained in `EMultipoleGroup`.", false),
  FloorPositionGroup    => EleParameterGroupInfo("Global floor position and orientation.", true),
  GirderGroup           => EleParameterGroupInfo("Girder parameters.", false),
  InitParticleGroup     => EleParameterGroupInfo("Initial particle position and spin.", false),
  TwissGroup            => EleParameterGroupInfo("Initial Twiss and coupling parameters.", false),
  LCavityGroup          => EleParameterGroupInfo("Accelerating cavity parameters.", false),
  LengthGroup           => EleParameterGroupInfo("Length and s-position parameters.", true),
  LordSlaveStatusGroup        => EleParameterGroupInfo("Element lord and slave status.", false),
  MasterGroup           => EleParameterGroupInfo("Contains field_master parameter.", false),
  PatchGroup            => EleParameterGroupInfo("Patch parameters.", false),
  ReferenceGroup        => EleParameterGroupInfo("Reference energy and species.", true),
  RFCavityGroup         => EleParameterGroupInfo("`RFCavity` parameters.", true),
  RFCommonGroup         => EleParameterGroupInfo("RF parameters common to both `LCavity` and `RFCavity`.", false),
  RFAutoGroup           => EleParameterGroupInfo("Contains `auto_amp`, and `auto_phase` related parameters.", false),
  SolenoidGroup         => EleParameterGroupInfo("`Solenoid` parameters.", false),
  StringGroup           => EleParameterGroupInfo("Informational strings.", false),
  TrackingGroup         => EleParameterGroupInfo("Default tracking settings.", false),
)

#---------------------------------------------------------------------------------------------------
# multipole!

"""
    multipole!(mgroup, order; insert::Bool = false) -> 

Finds multipole of a given order.

Returns `nothing` if `vec` array does not contain element with n = `order` and `insert` = `false`.
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
# BRANCH_PARAM

"""
Dictionary of parameters in the Branch.pdict dict.
""" BRANCH_PARAM

BRANCH_PARAM::Dict{Symbol,ParamInfo} = Dict{Symbol,ParamInfo}(
  :ix_branch   => ParamInfo(Nothing, Int,               "Index of branch in containing lat .branch[] array"),
  :geometry    => ParamInfo(Nothing, BranchGeometry.T,  "BranchGeometry OPEN (default) or CLOSED."),
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

