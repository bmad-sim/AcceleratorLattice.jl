#---------------------------------------------------------------------------------------------------
# ParamInfo

"""
    mutable struct ParamInfo

Struct containing information on an element parameter.
Values of the `ELE_PARAM_INFO_DICT` `Dict` are `ParamInfo` structs.

## Fields
• `parent_group::T where T <: DataType  - Parent group of the parameter. \\
• `paramkind::Union{T, Union, UnionAll} where T <: DataType  - Something like Aperture is a Union.
• `description::String = ""   - 
• `units::String = ""
• `output_group::T where T <: Union{DataType, Nothing}
• `struct_sym::Symbol                    # Symbol in struct.
• `sub_struct::Union{Symbol, Nothing}    # Used if parameter parent is not parent_group. 
                                         #   EG: Twiss.a.beta has sub_struct = :a
• `user_sym::Symbol                      # Symbol used in by a user. Generally this is the
                                         #   the same as struct_sym. An exception is r_floor• `

 keys of the dict 

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
  parent_group::T where T <: DataType
  paramkind::Union{T, Union, UnionAll} where T <: DataType
  description::String = ""
  units::String = ""
  output_group::T where T <: Union{DataType, Nothing} = nothing
  struct_sym::Symbol = :XXX
  sub_struct::Union{Symbol, Nothing} = nothing
  user_sym::Symbol = :Z
end

#---------------------------------------------------------------------------------------------------
# ParamInfo constructor. 

"""
    ParamInfo(parent, kind, description, units::String = "", output_group = nothing, 
                                     struct_sym::Symbol = :XXX, sub_struct = nothing) = 
              ParamInfo(parent, kind, description, units, output_group, struct_sym, sub_struct, :Z)

Constructor for the `ParamInfo` struct.

- `:XXX` indicates that the `struct_sym` will be the same as the key in `ELE_PARAM_INFO_DICT`.
 EG: `ELE_PARAM_INFO_DICT[:field_master].struct_sym` will have the value `:field_master.`
- `:Z` is always replaced by the key in `ELE_PARAM_INFO_DICT`.
"""

ParamInfo(parent, kind, description, units::String = "", output_group = nothing, 
                                     struct_sym::Symbol = :XXX, sub_struct = nothing) = 
              ParamInfo(parent, kind, description, units, output_group, struct_sym, sub_struct, :Z)

#---------------------------------------------------------------------------------------------------
# ELE_PARAM_INFO_DICT

"""
    ELE_PARAM_INFO_DICT = Dict{Symbol,ParamInfo}

Dictionary mapping element parameters to `ParamInfo` structs which hold information on the parameters.
For example, `ELE_PARAM_INFO_DICT[:species_ref]` shows that the `species_ref` parameter is associated
with the `ReferenceParams`, etc. See the documentation on `ParamInfo` for more details.
""" ELE_PARAM_INFO_DICT

ELE_PARAM_INFO_DICT = Dict(
  :name               => ParamInfo(Nothing,        String,         "Name of the element."),
  :ix_ele             => ParamInfo(Nothing,        Int,            "Index of element in containing branch.ele[] array."),
  :branch             => ParamInfo(Nothing,        Branch,         "Pointer to branch element is in."),
  :multipass_lord     => ParamInfo(Nothing,        Ele,            "Element's multipass_lord. Will not be present if no lord exists."),
  :super_lords        => ParamInfo(Nothing,        Vector{Ele},    "Array of element's super lords. Will not be present if no lords exist."),
  :slaves             => ParamInfo(Nothing,        Vector{Ele},    "Array of slaves of element. Will not be present if no slaves exist."),
  :girder             => ParamInfo(Nothing,        Ele,            "Supporting Girder element. Will not be present if no supporting girder."),
  :from_forks         => ParamInfo(Nothing         Vector{Ele},    "List of fork elements that fork to this element."),

  :amp_function       => ParamInfo(ACKickerParams,  Function,       "Amplitude function."),

  :offset             => ParamInfo(BodyShiftParams, Vector{Number}, "[x, y, z] offset of element or, for a patch, exit coordinates.", "m"),
  :x_rot              => ParamInfo(BodyShiftParams, Number,         "X-axis rotation of element or, for a patch, exit coordinates.", "rad"),
  :y_rot              => ParamInfo(BodyShiftParams, Number,         "Y-axis rotation of element or, for a patch, exit coordinates.", "rad"),
  :z_rot              => ParamInfo(BodyShiftParams, Number,         "Z-axis rotation of element or, for a patch, exit coordinates.", "rad"),

  :q_shift            => ParamInfo(BodyShiftParams, Quaternion,     "Quaternion orientation.", "", OutputParams),
  :q_shift_tot        => ParamInfo(BodyShiftParams, Quaternion,     "Quaternion orientation including Girder orientation.", "", OutputParams),
  :offset_tot         => ParamInfo(BodyShiftParams, Vector{Number}, "[x, y, z] element offset including Girder orientation.", "m", OutputParams),
  :x_rot_tot          => ParamInfo(BodyShiftParams, Number,         "X-axis element rotation including Girder orientation.", "rad", OutputParams),
  :y_rot_tot          => ParamInfo(BodyShiftParams, Number,         "Y-axis element rotation including Girder orientation.", "rad", OutputParams),
  :z_rot_tot          => ParamInfo(BodyShiftParams, Number,         "Z-axis element rotation including Girder orientation.", "rad", OutputParams),

  :aperture_shape     => ParamInfo(ApertureParams,  ApertureShape,  "Aperture shape. Default is ELLIPTICAL."),
  :aperture_at        => ParamInfo(ApertureParams,  BodyLoc.T,      "Aperture location. Default is BodyLoc.ENTRANCE_END."),
  :aperture_shifts_with_body
                      => ParamInfo(ApertureParams,  Bool,           "Do element alignment shifts move the aperture?"),
  :x_limit            => ParamInfo(ApertureParams,  Vector{Number}, "Min/Max horizontal aperture limits.", "m"),
  :y_limit            => ParamInfo(ApertureParams,  Vector{Number}, "Min/Max vertical aperture limits.", "m"),
  :wall               => ParamInfo(ApertureParams,  Wall2D,         "Wall defined by array of aperture vertices."),
  :custom_aperture    => ParamInfo(ApertureParams,  Dict,           "Custom aperture info."),

  :angle              => ParamInfo(BendParams,      Number,         "Reference bend angle", "rad"),
  :bend_field_ref     => ParamInfo(BendParams,      Number,         "Reference bend field corresponding to g bending strength", "T"),
  :g                  => ParamInfo(BendParams,      Number,         "Reference bend strength (1/rho)", "1/m"),
  :e1                 => ParamInfo(BendParams,      Number,         "Bend entrance face angle.", "rad"),
  :e2                 => ParamInfo(BendParams,      Number,         "Bend exit face angle.", "rad"),
  :e1_rect            => ParamInfo(BendParams,      Number,         "Bend entrance face angles relative to a rectangular geometry.", "rad"),
  :e2_rect            => ParamInfo(BendParams,      Number,         "Bend exit face angles relative to a rectangular geometry.", "rad"),
  :L_chord            => ParamInfo(BendParams,      Number,         "Bend chord length.", "m"),
  :tilt_ref           => ParamInfo(BendParams,      Number,         "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :edge_int1          => ParamInfo(BendParams,      Number,         "Bend entrance edge field integral.", "m"),
  :edge_int2          => ParamInfo(BendParams,      Number,         "Bend exit edge field integral.", "m"),
  :bend_type          => ParamInfo(BendParams,      BendType.T,     "Sets the \"logical\" shape of a bend."),
  :exact_multipoles   => ParamInfo(BendParams,      ExactMultipoles.T, "Are multipoles treated exactly?"),

  :rho                => ParamInfo(BendParams,   Number,            "Reference bend radius", "m", OutputParams),
  :L_sagitta          => ParamInfo(BendParams,   Number,            "Bend sagitta length.", "m", OutputParams),
  :norm_bend_field    => ParamInfo(BendParams,   Number,            "Actual bend strength in the plane of the bend", "1/m", OutputParams),
  :bend_field         => ParamInfo(BendParams,   Number,            "Actual bend field in the plane of the bend field", "T", OutputParams),

  :species_ref_downstream => ParamInfo(DownstreamReferenceParams, Species, "Reference species at downstream end."),
  :pc_ref_downstream      => ParamInfo(DownstreamReferenceParams, Number,  "Reference momentum * c at downstream end.", "eV"),
  :E_tot_ref_downstream   => ParamInfo(DownstreamReferenceParams, Number,  "Reference total energy at downstream end.", "eV"),

  :β_ref_downstream       => ParamInfo(DownstreamReferenceParams, Number,   "Reference velocity/c at downstream end.", "", OutputParams),
  :γ_ref_downstream       => ParamInfo(DownstreamReferenceParams, Number,   "Reference relativistic gamma factor at downstream end.", "", OutputParams),

  :to_line            => ParamInfo(ForkParams,      Union{BeamLine, Nothing}, "Beamline forked to."),
  :to_ele             => ParamInfo(ForkParams,      Union{String,Ele},        "Lattice element forked to."),
  :direction          => ParamInfo(ForkParams,      Int,            "Direction (forwards or backwards) of injection."),

  :supported          => ParamInfo(GirderParams,    Vector{Ele},    "Array of elements supported by a Girder."),

  :L                  => ParamInfo(LengthParams,    Number,         "Element length.", "m"),
  :orientation        => ParamInfo(LengthParams,    Int,            "Longitudinal orientation of element. May be +1 or -1."),
  :s                  => ParamInfo(LengthParams,    Number,         "Longitudinal s-position at the upstream end.", "m"),
  :s_downstream       => ParamInfo(LengthParams,    Number,         "Longitudinal s-position at the downstream end.", "m"),

  :slave_status       => ParamInfo(LordSlaveStatusParams, Slave.T,  "Slave status."),
  :lord_status        => ParamInfo(LordSlaveStatusParams, Lord.T,   "Lord status."),

  :is_on              => ParamInfo(MasterParams,    Bool,           "Element fields on/off."),
  :field_master       => ParamInfo(MasterParams,    Bool,           "True: fields are fixed and normalized values change when varying ref energy."),

  :r_floor            => ParamInfo(OrientationParams, Vector{Number}, "3-vector of element floor position.", "m", nothing, :r),
  :q_floor            => ParamInfo(OrientationParams, Quaternion,     "Element quaternion orientation.", "", nothing, :q),

  :origin_ele         => ParamInfo(OriginEleParams,     Ele,        "Coordinate reference element."),
  :origin_ele_ref_pt  => ParamInfo(OriginEleParams,     Loc.T,      "Reference location on reference element. Default is Loc.CENTER."),

  :E_tot_offset       => ParamInfo(PatchParams,     Number,         "Reference energy offset.", "eV"),
  :E_tot_exit         => ParamInfo(PatchParams,     Number,         "Reference energy at exit end.", "eV"),
  :pc_exit            => ParamInfo(PatchParams,     Number,         "Reference momentum at exit end.", "eV"),
  :L_user             => ParamInfo(PatchParams,     Number,         "User set length.", "m"),
  :flexible           => ParamInfo(PatchParams,     Bool,           "Flexible patch?"),
  :ref_coords         => ParamInfo(PatchParams,     BodyLoc.T,      "Patch coords with respect to BodyLoc.ENTRANCE_END or BodyLoc.EXIT_END?"),

  :species_ref            => ParamInfo(ReferenceParams, Species,    "Reference species."),
  :pc_ref                 => ParamInfo(ReferenceParams, Number,     "Reference momentum * c.", "eV"),
  :E_tot_ref              => ParamInfo(ReferenceParams, Number,     "Reference total energy.", "eV"),
  :time_ref               => ParamInfo(ReferenceParams, Number,     "Reference time.", "sec"),
  :extra_dtime_ref        => ParamInfo(ReferenceParams, Number,     "Additional reference time change.", "sec"),
  :time_ref_downstream    => ParamInfo(ReferenceParams, Number,     "Reference time at downstream end.", "sec"),
  :dE_ref                 => ParamInfo(ReferenceParams, Number,     "Change in reference energy.", "volt"),

  :β_ref                  => ParamInfo(ReferenceParams, Number,     "Reference velocity/c.", "", OutputParams),
  :γ_ref                  => ParamInfo(ReferenceParams, Number,     "Reference relativistic gamma factor.", "", OutputParams),

  :voltage            => ParamInfo(RFParams,       Number,          "RF voltage.", "volt"),
  :gradient           => ParamInfo(RFParams,       Number,          "RF gradient.", "volt/m"),
  :phase              => ParamInfo(RFParams,       Number,          "RF phase.", "rad"),
  :multipass_phase    => ParamInfo(RFParams,       Number,    
                                                   "RF phase added to element and not controlled by multipass lord.", "rad"),
  :frequency          => ParamInfo(RFParams,       Number,          "RF frequency.", "Hz"),
  :harmon             => ParamInfo(RFParams,       Number,          "RF frequency harmonic number.", ""),
  :cavity_type        => ParamInfo(RFParams,       Cavity.T,        "Type of cavity."),
  :n_cell             => ParamInfo(RFParams,       Int,             "Number of RF cells."),

  :auto_amp           => ParamInfo(RFAutoParams,    Number,    
                                  "Correction to the voltage/gradient calculated by the auto scale code.", ""),
  :auto_phase         => ParamInfo(RFAutoParams,    Number,         "Correction RF phase calculated by the auto scale code.", "rad"),
  :do_auto_amp        => ParamInfo(RFAutoParams,    Bool,           "Autoscale voltage/gradient?"),
  :do_auto_phase      => ParamInfo(RFAutoParams,    Bool,           "Autoscale phase?"),

  :num_steps          => ParamInfo(TrackingParams,  Int,            "Nominal number of tracking steps."),
  :ds_step            => ParamInfo(TrackingParams,  Number,         "Nominal distance between tracking steps.", "m"),

  :Ksol               => ParamInfo(SolenoidParams,   Number,        "Solenoid strength.", "1/m"),
  :Bsol               => ParamInfo(SolenoidParams,   Number,        "Solenoid field.", "T"),

  :spin               => ParamInfo(InitParticleParams, Vector{Number}, "Initial particle spin"),
  :orbit              => ParamInfo(InitParticleParams, Vector{Number}, "Initial particle position."),

  :type               => ParamInfo(DescriptionParams,   String,     "Type of element."),
  :ID                 => ParamInfo(DescriptionParams,   String,     "Identification name."),
  :class              => ParamInfo(DescriptionParams,   String,     "Classification of element."),

  :beta               => ParamInfo(Twiss1,      Number,            "Beta Twiss parameter.", "m"),
  :alpha              => ParamInfo(Twiss1,      Number,            "Alpha Twiss parameter.", ""),
  :gamma              => ParamInfo(Twiss1,      Number,            "Gamma Twiss parameter.", "1/m"),
  :phi                => ParamInfo(Twiss1,      Number,            "Betatron phase.", "rad"),
  :eta                => ParamInfo(Twiss1,      Number,            "Position dispersion.", "m"),
  :etap               => ParamInfo(Twiss1,      Number,            "Momentum dispersion.", ""),
  :deta_ds            => ParamInfo(Twiss1,      Number,            "Dispersion derivative.", ""),

  :beta_a             => ParamInfo(TwissParams,  Number,            "A-mode beta Twiss parameter.", "m", nothing, :beta, :a),
  :alpha_a            => ParamInfo(TwissParams,  Number,            "A-mode alpha Twiss parameter.", "", nothing, :alpha, :a),
  :gamma_a            => ParamInfo(TwissParams,  Number,            "A-mode gamma Twiss parameter.", "1/m", nothing, :gamma, :a),
  :phi_a              => ParamInfo(TwissParams,  Number,            "A-mode betatron phase.", "rad", nothing, :phi, :a),

  :beta_b             => ParamInfo(TwissParams,  Number,            "B-mode beta Twiss parameter.", "m", nothing, :beta, :b),
  :alpha_b            => ParamInfo(TwissParams,  Number,            "B-mode alpha Twiss parameter.", "", nothing, :alpha, :b),
  :gamma_b            => ParamInfo(TwissParams,  Number,            "B-mode gamma Twiss parameter.", "1/m", nothing, :gamma, :b),
  :phi_b              => ParamInfo(TwissParams,  Number,            "B-mode betatron phase.", "rad", nothing, :phi, :b),

  :eta_x              => ParamInfo(TwissParams,  Number,            "X-mode position dispersion.", "m", nothing, :eta, :x),
  :etap_x             => ParamInfo(TwissParams,  Number,            "X-mode momentum dispersion.", "", nothing, :etap, :x),
  :deta_ds_x          => ParamInfo(TwissParams,  Number,            "X-mode dispersion derivative.", "", nothing, :deta_ds, :x),

  :eta_y              => ParamInfo(TwissParams,  Number,            "Y-mode position dispersion.", "m", nothing, :eta, :y),
  :etap_y             => ParamInfo(TwissParams,  Number,            "Y-mode momentum dispersion.", "", nothing, :etap, :y),
  :deta_ds_y          => ParamInfo(TwissParams,  Number,            "Y-mode dispersion derivative.", "", nothing, :deta_ds, :y),
)

for (key, info) in ELE_PARAM_INFO_DICT
  if info.struct_sym == :XXX; info.struct_sym = key; end
  info.user_sym = key
end

#---------------------------------------------------------------------------------------------------
# associated_names(group::Type{T}) 

"""
    associated_names(group::Type{T}) -> Vector{Symbol}

List of names (symbols) of parameters associated with element parameter group struct `group`.
Associated parameters are the fields of the struct plus any associated output parameters.

If the "user name" is different from the group field name, the user name is used.
For example, for a `OrientationParams`, `r_floor` will be in the name list instead of `r`.
""" associated_names

function associated_names(group::Type{T}) where T <: EleParams
  names = [field for field in fieldnames(group)]
  for (key, pinfo) in ELE_PARAM_INFO_DICT
    if pinfo.parent_group != group; continue; end
    if pinfo.user_sym ∉ names; push!(names, pinfo.user_sym); end
    if pinfo.struct_sym != pinfo.user_sym; deleteat!(names, names .== pinfo.struct_sym); end
  end
  return names
end

#---------------------------------------------------------------------------------------------------

DEPENDENT_ELE_PARAMETERS::Vector{Symbol} = 
         [:species_ref_downstream, :pc_ref_downstream, :E_tot_ref_downstream, :time_ref_downstream,]

#---------------------------------------------------------------------------------------------------
# has_parent_group

function has_parent_group(pinfo::ParamInfo, group::Type{T}) where T <: BaseEleParams
  if typeof(pinfo.parent_group) <: Vector
    return group in pinfo.parent_group
  else
    return group == pinfo.parent_group
  end
end

#---------------------------------------------------------------------------------------------------
# ele_param_struct_field_to_user_sym

"""
    Dict{Symbol,Vector{Symbol}} ele_param_struct_field_to_user_sym[field::Symbol] -> users::Vector{Symbol}

Map element parameter struct field to vector of user symbol(s). User symbols being the symbols
that a user can use to access the struct field. 

Dict values are vectors since the struct symbol maps to multiple user symbols.
This mapping only covers stuff in `ELE_PARAM_INFO_DICT` so this mapping does not, for example, cover multipoles.

Example: `ele_param_struct_field_to_user_sym[:beta] => [:beta_b, :beta, :beta_a, :beta_c]`

The mappings from user name to field for this example are: \\
• `beta_a` - maps to `a.beta` in a TwissParams \\
• `beta_b` - maps to `b.beta` in a TwissParams \\
• `beta_c` - maps to `c.beta` in a TwissParams \\
• `beta`   - maps to `beta` in a Twiss1Params \\
""" ele_param_struct_field_to_user_sym

ele_param_struct_field_to_user_sym = Dict{Symbol,Vector{Symbol}}()

for (param, info) in ELE_PARAM_INFO_DICT
  if info.struct_sym in keys(ele_param_struct_field_to_user_sym)
    push!(ele_param_struct_field_to_user_sym[info.struct_sym], param)
  else
    ele_param_struct_field_to_user_sym[info.struct_sym] = [param]
  end
end

#---------------------------------------------------------------------------------------------------
# units

"""
    units(param::Union{Symbol,DataType}) -> units::String
    units(param::Union{Symbol,DataType}, eletype::Type{T}) where T <: Ele -> units::String

Returns the units associated with symbol. EG: `m` (meters) for `param` = `:L`.
`param` may be an element parameter group type (EG: `LengthParams`) in which
case `units` returns a blank string.
""" units

function units(param::Union{Symbol,DataType})
  if typeof(param) == DataType; return ""; end

  if param in keys(ele_param_struct_field_to_user_sym)
    # Ambiguous so just assume that all possibilities have the same units.
    info = ELE_PARAM_INFO_DICT[ele_param_struct_field_to_user_sym[param][1]]
  else
    info = ele_param_info(param, throw_error = false)
  end

  if isnothing(info); (return "?units?"); end
  return info.units
end

#-

function units(param::Union{Symbol,DataType}, eletype::Type{T}) where T <: Ele
  return units(param)
end

#---------------------------------------------------------------------------------------------------
# description

"""
    description(param::Symbol) -> String

Return description string for lattice element parameter `param`.
""" description

function description(param)
  param_info = ele_param_info(param)
  if isnothing(param_info); return "???"; end
  return param_info.description
end

#---------------------------------------------------------------------------------------------------
# multipole_type

"""
    function multipole_type(sym::Symbol) -> (type::String, order::Int, group_type::Type{T})
    function multipole_type(str::AbstractString}) -> (type::String, order::Int, group_type::Type{T})
                                   where T <: Union{BMultipoleParams,EMultipoleParams,Nothing}

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
    isnothing(order) || order < 0 ? (return isbad) : return ("tilt", order, BMultipoleParams)
  elseif length(str) > 5 && str[1:5] == "Etilt"
    order = tryparse(Int,   str[6:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("Etilt", order, EMultipoleParams)
  elseif length(str) > 10 && str[1:10] == "integrated"
    order = tryparse(Int,   str[11:end])
    isnothing(order) || order < 0 ? (return isbad) : return ("integrated", order, BMultipoleParams)
  elseif length(str) > 11 && str[1:11] == "Eintegrated"
    order = tryparse(Int,   str[12:end]) 
    isnothing(order) || order < 0 ? (return isbad) : return ("Eintegrated", order, EMultipoleParams)
  end

  if str[1:2] in Set(["Kn", "Ks", "Bn", "Bs"])
    group_type = BMultipoleParams
  elseif str[1:2] in Set(["En", "Es"])
    group_type = EMultipoleParams
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
    Internal: multipole_param_info(sym::Symbol) -> ParamInfo

Returns `ParamInfo` information struct on a given multipole parameter corresponding to `sym`.

The `sub_struct` of the returned `ParamInfo` is set to nothing since the true sub-structure is 
complicated (something like `vec[J]` where `J` is not fixed).

""" multipole_param_info

function multipole_param_info(sym::Symbol)
  (mtype, order, group) = multipole_type(sym)
  if group == Nothing; return nothing; end

  if mtype == "tilt"
    return ParamInfo(BMultipoleParams, Number, "Magnetic multipole tilt for order $order", "rad", nothing, :tilt, nothing, sym)
  elseif mtype == "Etilt"
    return ParamInfo(EMultipoleParams, Number, "Electric multipole tilt for order $order", "rad", nothing, :Etilt, nothing, sym)
  elseif mtype == "integrated"
    return ParamInfo(BMultipoleParams, Bool, "Are stored multipoles integrated for order $order?", "", nothing, :integrated, nothing, sym)
  elseif mtype == "Eintegrated"
    return ParamInfo(EMultipoleParams, Bool, "Are stored multipoles integrated for order $order?", "", nothing, :Eintegrated, nothing, sym)
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

    return ParamInfo(BMultipoleParams, Number, "$str, momentum-normalized, magnetic multipole of order $order.", units, nothing, insym, nothing, sym)

  elseif mtype[1] == 'B'
    if order == -1;    units = "T*m"
    elseif order == 0; units = "T"
    else;              units = "T/m^$exp"
    end

    return ParamInfo(BMultipoleParams, Number, "$str, magnetic field multipole of order $order.", units, nothing, insym, nothing, sym)

  elseif mtype[1] == 'E'
    if order == -1; units = "V"
    else;           units = "V/m^$(exp+1)"
    end

    return ParamInfo(EMultipoleParams, Number, "$str, electric field multipole of order $order.", units, nothing, insym, nothing, sym) 
  end
end

!-

multipole_param_info(str::AbstractString) = multipole_param_info(Symbol(str))

#---------------------------------------------------------------------------------------------------
# ele_param_info

"""
    ele_param_info(who::Union{Symbol,DataType}; throw_error = true) -> Union{ParamInfo, Nothing}
    ele_param_info(who::Symbol, ele::Ele; throw_error = true) -> Union{ParamInfo, Nothing}

Returns information on `who` which is either a `Symbol` representing an element parameter
or an element parameter group type.

Returned is a `ParamInfo` struct. If `who` is a DataType or no information on `who` is found, 
an error is thrown or `nothing` is returned depending upon the setting of `throw_error`.
""" ele_param_info

function ele_param_info(who::Union{Symbol,DataType}; throw_error = true)
  if typeof(who) == Symbol
    if haskey(ELE_PARAM_INFO_DICT, who); (return ELE_PARAM_INFO_DICT[who]); end
    # Is a multipole? Otherwise unrecognized.
    info = multipole_param_info(who)
    if isnothing(info) && throw_error; error("Unrecognized element parameter: $who"); end
    return info
  end

  # A DataType means `who` is not an element parameter.
  if throw_error; error(f"Unrecognized element parameter: {who}"); end
  return nothing
end

#

function ele_param_info(who::Union{Symbol,DataType}, ele::Ele; throw_error = true)
  if typeof(who) == Symbol
    param_info = ele_param_info(who, throw_error = throw_error)
    if isnothing(param_info); return nothing; end

    if typeof(param_info.parent_group) <: Vector
      for parent in param_info.parent_group
        if parent in PARAM_GROUPS_LIST[typeof(ele)]
          param_info.parent_group = parent
          return param_info
        end
      end
    
      error(f"Symbol {who} not in element {ele_name(ele)} which is of type {typeof(ele)}")

    else
      if param_info.parent_group in PARAM_GROUPS_LIST[typeof(ele)] || 
                                        param_info.parent_group == Nothing; return param_info; end
      error(f"Symbol {who} not in element {ele_name(ele)} which is of type {typeof(ele)}")   
    end
  end

  # A DataType means `who` is not an element parameter.
  if throw_error; error(f"Unrecognized element parameter: {who}"); end
  return nothing
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
  mul = multipole!(BMultipoleParams, order)
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
  mul = multipole!(EMultipoleParams, order)
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
 - `LengthParams` being first (except for a `Bend` where BendParams is `first`).
 - `BendParams` after `ReferenceParams` and `MasterParams` (in case the reference energy is changing).
 - `BMultipoleParams` and `EMultipoleParams` after `MasterParams` (in case the reference energy is changing).
 - `RFCommonParams` comes last (triggers autoscale/autophase and `ReferenceParams` correction).
""" PARAM_GROUPS_LIST

base_group_list = [LengthParams, LordSlaveStatusParams, DescriptionParams, ReferenceParams, 
         DownstreamReferenceParams, OrientationParams, TrackingParams, BodyShiftParams, ApertureParams]
multipole_group_list = [MasterParams, BMultipoleParams, EMultipoleParams]
general_group_list = [base_group_list..., multipole_group_list...]

PARAM_GROUPS_LIST = Dict(  
    ACKicker            => [general_group_list..., ACKickerParams],
    BeamBeam            => [base_group_list..., BeamBeamParams],
    BeginningEle        => [base_group_list..., TwissParams, InitParticleParams],
    Bend                => [BendParams, general_group_list...],
    Collimator          => [base_group_list...],
    Converter           => [base_group_list...],
    CrabCavity          => [base_group_list...],
    Drift               => [base_group_list...],
    EGun                => [general_group_list...],
    Fiducial            => [DescriptionParams, OrientationParams, BodyShiftParams, OriginEleParams],
    FloorShift          => [DescriptionParams, OrientationParams, BodyShiftParams, OriginEleParams],
    Foil                => [base_group_list...],
    Fork                => [base_group_list..., ForkParams],
    Girder              => [LengthParams, DescriptionParams, OrientationParams, BodyShiftParams, OriginEleParams, GirderParams],
    Instrument          => [base_group_list...],
    Kicker              => [general_group_list...],
    LCavity             => [base_group_list..., MasterParams, RFAutoParams, RFParams],
    Marker              => [base_group_list...],
    Match               => [base_group_list...],
    Multipole           => [general_group_list...],
    NullEle             => [],
    Octupole            => [general_group_list...],
    Patch               => [base_group_list..., PatchParams],
    Quadrupole          => [general_group_list...],
    RFCavity            => [base_group_list..., MasterParams, RFAutoParams, RFParams],
    Sextupole           => [general_group_list...],
    Solenoid            => [general_group_list..., SolenoidParams],
    Taylor              => [base_group_list...],
    Undulator           => [base_group_list...],
    UnionEle            => [base_group_list...],
    Wiggler             => [base_group_list...],
)

PARAM_GROUPS_SYMBOL = copy(PARAM_GROUPS_LIST)
for key in keys(PARAM_GROUPS_SYMBOL)
  PARAM_GROUPS_SYMBOL[key] = Symbol.(strip_AL.(string.(PARAM_GROUPS_SYMBOL[key])))
end


ELE_PARAM_GROUP_INFO = Dict(
  ACKickerParams         => EleParamsInfo("ACKicker element parameters.", false),
  BodyShiftParams        => EleParamsInfo("Element position/orientation shift.", false),
  ApertureParams         => EleParamsInfo("Vacuum chamber aperture.", false),
  BeamBeamParams         => EleParamsInfo("BeamBeam element parameters.", false),
  BendParams             => EleParamsInfo("Bend element parameters.", true),
  BMultipoleParams       => EleParamsInfo("Magnetic multipoles.", true),
  BMultipole            => EleParamsInfo("Magnetic multipole of given order. Substructure contained in `BMultipoleParams`", false),
  DescriptionParams      => EleParamsInfo("Informational strings.", false),
  DownstreamReferenceParams => EleParamsInfo("Downstream element end reference energy and species.", false),
  EMultipoleParams       => EleParamsInfo("Electric multipoles.", false),
  EMultipole            => EleParamsInfo("Electric multipole of given order. Substructure contained in `EMultipoleParams`.", false),
  ForkParams             => EleParamsInfo("Fork element parameters", false),
  GirderParams           => EleParamsInfo("Girder parameters.", false),
  InitParticleParams     => EleParamsInfo("Initial particle position and spin.", false),
  TwissParams            => EleParamsInfo("Initial Twiss and coupling parameters.", false),
  LengthParams           => EleParamsInfo("Length and s-position parameters.", true),
  LordSlaveStatusParams  => EleParamsInfo("Element lord and slave status.", false),
  MasterParams           => EleParamsInfo("Contains field_master parameter.", false),
  OrientationParams      => EleParamsInfo("Global floor position and orientation.", true),
  OriginEleParams        => EleParamsInfo("Defines coordinate origin for Girder, FloorShift and Fiducial elements.", false),
  PatchParams            => EleParamsInfo("Patch parameters.", false),
  ReferenceParams        => EleParamsInfo("Reference energy and species.", true),
  RFParams               => EleParamsInfo("`RFCavity` and `LCavity` RF parameters.", true),
  RFAutoParams           => EleParamsInfo("Contains `auto_amp`, and `auto_phase` related parameters.", false),
  SolenoidParams         => EleParamsInfo("`Solenoid` parameters.", false),
  TrackingParams         => EleParamsInfo("Default tracking settings.", false),
)

#---------------------------------------------------------------------------------------------------
# 

BOOKKEEPING_VECTOR_PARAMETERS = Dict(
  BeginningEle          => [:r_floor],
  Fiducial              => [:offset],
  FloorShift            => [:offset],
  Patch                 => [:offset],
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
  ix = multipole_index(mgroup.pole, order)

  if !insert
    if ix > length(mgroup.pole) || order != mgroup.pole[ix].order; return nothing; end
    return mgroup.pole[ix]
  end

  if ix > length(mgroup.pole) 
    ix = length(mgroup.pole) + 1
    insert!(mgroup.pole, ix, eltype(mgroup.pole)())
    mgroup.pole[ix].order = order
  elseif mgroup.pole[ix].order != order
    insert!(mgroup.pole, ix, eltype(mgroup.pole)())
    mgroup.pole[ix].order = order
  end

  return mgroup.pole[ix]
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
  :type        => ParamInfo(Nothing, BranchType,        "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => ParamInfo(Nothing, Pointer,           "Element that forks to this branch."),
  :live_branch => ParamInfo(Nothing, Bool,              "Used by programs to turn on/off tracking in a branch."),
  :ref_species => ParamInfo(Species, String,            "Reference tracking species."),
)

#---------------------------------------------------------------------------------------------------
# Bases.copy(x::T) where {T <: EleParams} 

"""
Copy for a normal element parameter group is equivalent to a deep copy.
The only reason not to have copy != deepcopy is when the group has a lot of data. Think field table.
"""

Base.copy(x::T) where {T <: EleParams} = T([deepcopy(getfield(x, k)) for k ∈ fieldnames(T)]...)

