"""
Dictionaries of parameters defined by Bmad
"""

"""
Possible kind values: String, IntKind, RealKind, RealVec, BoolKind, Switch, Struct, Pointer

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

A Struct is a struct. For example, the :floor parameter holds a FloorPosition struct
"""

abstract type ParamKind
abstract type Struct <: ParamKind end
abstract type Switch <: ParamKind end
abstract type Pointer <: ParamKind end
abstract type RealVec <: ParamKind end

struct LatticeParamInfo
  parent_struct::DataType
  kind::ParamKind
  description::String
  units::String 
end

LatticeParamInfo(parent::DataType, kind::ParamKind, description::String) = LatticeParamInfo(parent, kind, description, "")

"""
Dictionary of parameters in the Ele.param dict.
"""
global ele_param = Dict(
  :type         => LatticeParamInfo(String,    "Type of element. Set by User and ignored by Bmad."),
  :alias        => LatticeParamInfo(String,    "Alias name. Set by User and ignored by Bmad."),
  :description  => LatticeParamInfo(String,    "Descriptive info. Set by User and ignored by Bmad."),
  :ix_ele       => LatticeParamInfo(IntKind,   "Index of element in containing branch .ele() array."),
  :orientation  => LatticeParamInfo(IntKind,   "Longitudinal orientation of element. May be +1 or -1."),
  :branch       => LatticeParamInfo(Pointer,   "Pointer to branch containing element."),
  :e            => LatticeParamInfo(RealVec,   "Bend entrance  and exit face angles. Equivalent to [:e1, :e2]., "rad"),
  :e1           => LatticeParamInfo(RealKind,  "Bend entrance face angle. Equivalent to :(e[1])", "rad"),
  :e2           => LatticeParamInfo(RealKind,  "Bend exit face angle. Equivalent to :(e[2])", "rad"),
  :er           => LatticeParamInfo(RealVec,   "Bend entrance  and exit face angles relative to a rectangular geometry. Equivalent to [:er1, :er2]., "rad"),
  :er1          => LatticeParamInfo(RealKind,  "Bend entrance face angle relative to a rectangular geometry.", "rad"),
  :er2          => LatticeParamInfo(RealKind,  "Bend exit face angle relative to a rectangular geometry.", "rad"),
  :len          => LatticeParamInfo(RealKind,  "Element length.", "m"),
  :len_chord    => LatticeParamInfo(RealKind,  "Bend chord length.", "m"),
  :s            => LatticeParamInfo(RealKind,  "Longitudinal s-position.", "m"),
  :x_limit      => LatticeParamInfo(RealVec
  :y_limit
  :fint
  :hgap

)

struct EleParamKey
  kind::DataType
  description::String
end

global ele_dict_keys = Dict(
  :floor           => EleParamKey(FloorPosition, "Global floor position and orientation"),
  :kmultipoles     => EleParamKey(EleKMultipoles, "Normalized magnetic multipoles."),
  :fieldmultipoles => EleParamKey(EleFieldMultipoles, "Unnormalized magnetic multipoles.")
  :emultipoles     => EleParamKey(EleEMultipolse, "Electric multipoles.")
  :alignment       => EleParamKey(Alignment
)


"""
Dictionary of parameters in the Branch.param dict.
"""
global branch_param = Dict(
  :ix_branch   => LatticeParamInfo(Int, "Index of branch in containing lat .branch() array"),
  :geometry    => LatticeParamInfo(Switch, "open_geom or closed_geom Geometry enums"),
  :lat         => LatticeParamInfo(Pointer, "Pointer to lattice containing the branch."),
  :type        => LatticeParamInfo(Switch, "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => LatticeParamInfo(Struct, "Element that forks to this branch.", "", Ele),
  :live_branch => LatticeParamInfo(Bool, "Used by programs to turn on/off tracking in a branch."),
  :wall        => LatticeParamInfo(Struct, "Vacuum chamber wall.", "", ChamberWall),
  :ref_species => LatticeParamInfo(Struct, "Reference tracking species.", "", Species),
)


"""
Dictionary of parameters in the Lat.param dict.
"""
global lat_param = Dict(
)

#-----------------------------------------------------------------------------------------
# parameter groups


base_group = [:s, :len, :ix_ele, :branch]
descrip_group = [:type, :alias, :description]
misalign_group = [:x_offset, :y_offset, :z_offset, :x_pitch, :y_pitch, :tilt]


#-----------------------------------------------------------------------------------------
# ele_param_by_ele_struct

"""
Table of what parameters are associated with what element types.
"""

global ele_param_by_ele_struct = Dict(  
  Dict(
    Bend           => append!(base_group, descrip_group, fieldnames(BendParams), fieldnames(AlignmentParams)),
    Drift          => append!(base_group, descrip_group, fieldnames(AlignmentParams)),
    Marker         => Vector(),
    ThickMultipole => Vector(),
    Quadrupole     => Vector(),
  )
)

deleteat!(ele_param_by_ele_struct[Bend], ele_param_by_ele_struct[Bend] .== :tilt)

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