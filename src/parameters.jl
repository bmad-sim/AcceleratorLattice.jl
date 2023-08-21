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

struct LatParamDict
  parent_struct::DataType
  kind::Union{DataType, Union}   # Something like ApertureTypeSwitch is a Union.
  description::String
  units::String
  alias::Union{Symbol,Expr}
  default
end

LatParamDict(parent::DataType, kind::Union{DataType, Union}, description::String, units::String = ""; 
      alias::Union{Symbol,Expr} = :nothing, default = nothing) = LatParamDict(parent, kind, description, units, alias, default)


"""
Dictionary of parameters in the Ele.param dict.
"""

global ele_param_dict = Dict(
  :type           => LatParamDict(StringGroup,    String,    "Type of element. Set by User and ignored the code."),
  :alias          => LatParamDict(StringGroup,    String,    "Alias name. Set by User and ignored by the code."),
  :description    => LatParamDict(StringGroup,    String,    "Descriptive info. Set by User and ignored by the code."),


  :angle          => LatParamDict(BendGroup,      Real,      "Design bend angle", "rad"),
  :bend_field     => LatParamDict(BendGroup,      Real,      "Design bend field corresponding to g bending", "T"),
  :rho            => LatParamDict(BendGroup,      Real,      "Design bend radius", "m"),
  :g              => LatParamDict(BendGroup,      Real,      "Design bend strength (1/rho)", "1/m"),
  :e              => LatParamDict(BendGroup,      RealVec,   "2-Vector of bend entrance and exit face angles. Equivalent to [:e1, :e2].", "rad"),
  :e1             => LatParamDict(BendGroup,      Real,      "Bend entrance face angle. Equivalent to :(e[1]).", "rad", alias = :(e[1])),
  :e2             => LatParamDict(BendGroup,      Real,      "Bend exit face angle. Equivalent to :(e[2]).", "rad", alias = :(e[2])),
  :e_rec          => LatParamDict(BendGroup,      RealVec,   
                     "2-Vector of bend entrance and exit face angles relative to a rectangular geometry. Equivalent to [:e1_rec, :e2_rec].", "rad"),
  :e1_rec         => LatParamDict(BendGroup,      Real,      "Bend entrance face angle relative to a rectangular geometry.", "rad", alias = :(e_rec[1])),
  :e2_rec         => LatParamDict(BendGroup,      Real,      "Bend exit face angle relative to a rectangular geometry.", "rad", alias = :(e_rec[2])),
  :len            => LatParamDict(BendGroup,      Real,      "Element length.", "m"),
  :len_chord      => LatParamDict(BendGroup,      Real,      "Bend chord length.", "m"),
  :ref_tilt       => LatParamDict(BendGroup,      Real,      "Bend reference orbit rotation around the upstream z-axis", "rad"),
  :fint           => LatParamDict(BendGroup,      RealVec,   "2-Vector of bend edge field integrals.", ""),
  :hgap           => LatParamDict(BendGroup,      RealVec,   "2-Vector of bend edge pole gap heights.", "m"),

  :aperture_type  => LatParamDict(ApertureGroup,  ApertureTypeSwitch, "Type of aperture."),
  :aperture_at    => LatParamDict(ApertureGroup,  EleBodyLocationSwitch, "Where the aperture is."),
  :offset_moves_aperture => 
                     LatParamDict(ApertureGroup,  Bool, "Does moving the element move the aperture?"),
  :x_limit        => LatParamDict(ApertureGroup,  RealVec,   "Vector of horizontal aperture limits.", "m"),
  :y_limit        => LatParamDict(ApertureGroup,  RealVec,   "Vector of vertical aperture limits.", "m"),

  :r_floor        => LatParamDict(FloorPositionGroup, RealVec,   "3-vector of floor position.", "m", alias = :(r[])),
  :q_floor        => LatParamDict(FloorPositionGroup, RealVec,   "Quaternion orientation.", "m", alias = :(q[])),

  :s              => LatParamDict(Nothing,        Real,      "Longitudinal s-position.", "m"),
  :ix_ele         => LatParamDict(Nothing,        Int,       "Index of element in containing branch .ele() array."),
  :orientation    => LatParamDict(Nothing,        Int,       "Longitudinal orientation of element. May be +1 or -1."),
  :branch         => LatParamDict(Nothing,        Pointer,   "Pointer to branch element is in."),
)


function ele_param(sym::Symbol)
  if haskey(ele_param_dict, sym); return ele_param_dict[sym]; end
  return nothing
end

struct EleParamKey
  description::String
end

global ele_param_group = Dict(
  FloorPositionGroup     => EleParamKey("Global floor position and orientation"),
  KMultipoleGroup        => EleParamKey("Normalized magnetic multipoles."),
  FieldMultipoleGroup    => EleParamKey("Unnormalized magnetic multipoles."),
  EMultipoleGroup        => EleParamKey("Electric multipoles."),
  AlignmentGroup         => EleParamKey("Vacuum chamber aperture."),
)


"""
Dictionary of parameters in the Branch.param dict.
"""

global branch_param = Dict(
  :ix_branch   => LatParamDict(Nothing, Int,      "Index of branch in containing lat .branch[] array"),
  :geometry    => LatParamDict(Nothing, Switch,   "open_geom or closed_geom Geometry enums"),
  :lat         => LatParamDict(Nothing, Pointer,  "Pointer to lattice containing the branch."),
  :type        => LatParamDict(Nothing, Switch,   "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => LatParamDict(Nothing, Pointer,  "Element that forks to this branch."),
  :live_branch => LatParamDict(Nothing, Bool,     "Used by programs to turn on/off tracking in a branch."),
  :ref_species => LatParamDict(Species, String,   "Reference tracking species."),
)


"""
Dictionary of parameters in the Lat.param dict.
"""
global lat_param = Dict(
)

#-----------------------------------------------------------------------------------------
# parameter groups

struct ParamState
  settable::Bool
end

to_dict(vec, state::ParamState = ParamState(true)) = Dict{Symbol,Any}([v => state for v in vec])
to_dict(kind::DataType, state::ParamState = ParamState(true)) = to_dict(fieldnames(kind), state)

base_dict = to_dict([:s, :len, :ix_ele, :branch], ParamState(false))

extended_base_dict = merge(base_dict, to_dict(StringGroup), to_dict(AlignmentGroup),
                                                            to_dict(FloorPositionGroup))
multipole_dict = merge(to_dict(KMultipoleGroup), to_dict(BMultipoleGroup), to_dict(EMultipoleGroup))

#-----------------------------------------------------------------------------------------
# ele_param_by_struct

"""
Table of what parameters are associated with what element types.
"""

global ele_param_by_struct = Dict(  
  Dict(
    Bend           => merge(extended_base_dict, to_dict(BendGroup)),
    Drift          => merge(extended_base_dict, multipole_dict),
    Marker         => merge(extended_base_dict, multipole_dict),
    Quadrupole     => merge(extended_base_dict, multipole_dict),
  )
)

function has_ele_param(type::Type{T}, sym::Symbol) where T <: Ele
  if sym in ele_param_by_struct[type]; return true; end
  return false
end

##deleteat!(ele_param_by_ele_struct[Bend], ele_param_by_ele_struct[Bend] .== :tilt)

#-----------------------------------------------------------------------------------------
# ele_param_defaults

"""
Real parameters have default 0.0 if not specified.
"""
global ele_param_defaults = Dict(
)

#-----------------------------------------------------------------------------------------
# branch_param_defaults

"""
Real parameters have default 0.0 if not specified.
Note: :geometry is not set for lord branches.
"""
global branch_param_defaults = Dict(
  :ix_branch  => "-",
)