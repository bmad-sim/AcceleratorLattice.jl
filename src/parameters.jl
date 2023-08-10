"""
Dictionaries of parameters defined by Bmad
"""

"""
Possible kind values: String, Int, Real, Bool, Switch, Struct, Pointer

A Switch is a variable that has only a finite number of values.
Generally, a Switch will either be an enum or something that has a finite number of integer states.

A Pointer is something that points to other variables.
For example, a Ele may have a vector pointing to its lords. In this case the vector
itself is considered to be a Pointer as well as its components.

A Struct is a struct. For example, the :floor parameter holds a FloorPosition struct
"""

abstract type Struct end
abstract type Switch end
abstract type Pointer end

struct ParamInfo
  kind
  description::AbstractString
  units::AbstractString 
  struct_type                        # Set for Struct parameters
end

ParamInfo(kind, description) = ParamInfo(kind, description, "", nothing)
ParamInfo(kind, description, units) = ParamInfo(kind, description, units, nothing)

"""
Dictionary of parameters in the Ele.param dict.
"""
global ele_param = Dict(
  :type         => ParamInfo(String, "Type of element. Set by User and ignored by Bmad."),
  :alias        => ParamInfo(String, "Alias name. Set by User and ignored by Bmad."),
  :description  => ParamInfo(String, "Descriptive info. Set by User and ignored by Bmad."),
  :ix_ele       => ParamInfo(Int, "Index of element in containing branch .ele() array."),
  :orientation  => ParamInfo(Int, "Longitudinal orientation of element. May be +1 or -1."),
  :branch       => ParamInfo(Pointer, "Pointer to branch containing element."),

  :e1           => ParamInfo(Real, "Bend entrance face angle", ""),
  :e2           => ParamInfo(Real, "Bend exit face angle", ""),
  :e1r          => ParamInfo(Real, "Bend entrance face angle relative to a rectangular geometry", ""),
  :e2r          => ParamInfo(Real, "Bend exit face angle relative to a rectangular geometry", ""),
  :len          => ParamInfo(Real, "Element length", "m"),
  :len_chord    => ParamInfo(Real, "Bend chord length", "m"),
  :s            => ParamInfo(Real, "Longitudinal s-position", "m"),

  :floor        => ParamInfo(Struct, "Global floor position and orientation", "", FloorPosition),
)

"""
Dictionary of parameters in the Branch.param dict.
"""
global branch_param = Dict(
  :ix_branch   => ParamInfo(Int, "Index of branch in containing lat .branch() array"),
  :geometry    => ParamInfo(Switch, "open_geom or closed_geom Geometry enums"),
  :lat         => ParamInfo(Pointer, "Pointer to lattice containing the branch."),
  :type        => ParamInfo(Switch, "Either LordBranch or TrackingBranch BranchType enums."),
  :from_ele    => ParamInfo(Struct, "Element that forks to this branch.", "", Ele),
  :live_branch => ParamInfo(Bool, "Used by programs to turn on/off tracking in a branch."),
  :wall        => ParamInfo(Struct, "Vacuum chamber wall.", "", ChamberWall),
  :ref_species => ParamInfo(Struct, "Reference tracking species.", "", Species),
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