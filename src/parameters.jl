"""
Dictionaries of parameters defined by Bmad
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
  kind::DataType
  description::String
  units::String 
end

LatParamDict(parent::DataType, kind::DataType, description::String) = LatParamDict(parent, kind, description, "")
LatParamDict(parent::DataType, description::String) = LatParamDict(parent, Nothing, description, "")

"""
Dictionary of parameters in the Ele.param dict.
"""

global ele_param = Dict(
  :type         => LatParamDict(StringGroup,    String,    "Type of element. Set by User and ignored by Bmad."),
  :alias        => LatParamDict(StringGroup,    String,    "Alias name. Set by User and ignored by Bmad."),
  :description  => LatParamDict(StringGroup,    String,    "Descriptive info. Set by User and ignored by Bmad."),
  :ix_ele       => LatParamDict(Nothing,        Int,       "Index of element in containing branch .ele() array."),
  :orientation  => LatParamDict(Nothing,        Int,       "Longitudinal orientation of element. May be +1 or -1."),
  :branch       => LatParamDict(Nothing,        Pointer,   "Pointer to branch containing element."),
  :e            => LatParamDict(BendGroup,      RealVec,   "Vector of bend entrance  and exit face angles. Equivalent to [:e1, :e2].", "rad"),
  :e1           => LatParamDict(BendGroup,      Real,      "Bend entrance face angle. Equivalent to :(e[1]).", "rad"),
  :e2           => LatParamDict(BendGroup,      Real,      "Bend exit face angle. Equivalent to :(e[2]).", "rad"),
  :e_rec        => LatParamDict(BendGroup,      RealVec,   
                     "Vector of bend entrance  and exit face angles relative to a rectangular geometry. Equivalent to [:e1_rec, :e2_rec].", "rad"),
  :e1_rec       => LatParamDict(BendGroup,      Real,      "Bend entrance face angle relative to a rectangular geometry.", "rad"),
  :e2_rec       => LatParamDict(BendGroup,      Real,      "Bend exit face angle relative to a rectangular geometry.", "rad"),
  :len          => LatParamDict(BendGroup,      Real,      "Element length.", "m"),
  :len_chord    => LatParamDict(BendGroup,      Real,      "Bend chord length.", "m"),
  :s            => LatParamDict(Nothing,        Real,      "Longitudinal s-position.", "m"),
  :x_limit      => LatParamDict(ApertureGroup,  RealVec,   "Vector of horizontal aperture limits.", "m"),
  :y_limit      => LatParamDict(ApertureGroup,  RealVec,   "Vector of vertical aperture limits.", "m"),
  :fint         => LatParamDict(BendGroup,      RealVec,   "Vector of bend edge field integrals.", ""),
  :hgap         => LatParamDict(BendGroup,      RealVec,   "Vector of bend edge pole gap heights.", "m"),
  :branch       => LatParamDict(Nothing,        Pointer,   "Pointer to branch element is in.")
)

struct EleParamKey
  kind::DataType
  description::String
end

global ele_dict_keys = Dict(
  :floor           => EleParamKey(FloorPositionGroup,   "Global floor position and orientation"),
  :kmultipole      => EleParamKey(KMultipoleGroup,      "Normalized magnetic multipoles."),
  :fieldmultipole  => EleParamKey(FieldMultipoleGroup,  "Unnormalized magnetic multipoles."),
  :emultipole      => EleParamKey(EMultipoleGroup,      "Electric multipoles."),
  :alignment       => EleParamKey(AlignmentGroup,       "Vacuum chamber aperture."),
)


"""
Dictionary of parameters in the Branch.param dict.
"""

global branch_param = Dict(
  :ix_branch   => LatParamDict(Int,      "Index of branch in containing lat .branch[] array"),
  :geometry    => LatParamDict(Switch,   "open_geom or closed_geom Geometry enums"),
  :lat         => LatParamDict(Pointer,  "Pointer to lattice containing the branch."),
  :type        => LatParamDict(Switch,   "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => LatParamDict(Pointer,  "Element that forks to this branch."),
  :live_branch => LatParamDict(Bool,     "Used by programs to turn on/off tracking in a branch."),
  :wall        => LatParamDict(Struct,   "Vacuum chamber wall."),
  :ref_species => LatParamDict(Struct,   "Reference tracking species."),
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
#    Bend           => append!(base_group, descrip_group, fieldnames(BendParams), fieldnames(AlignmentParams)),
#    Drift          => append!(base_group, descrip_group, fieldnames(AlignmentParams)),
#    Marker         => Vector(),
#    ThickMultipole => Vector(),
#    Quadrupole     => Vector(),
  )
)

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