"""A
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


@enum geometry open! closed!

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
  :s            => ParamInfo(Real, "Longitudinal s-position", "m"),
  :len          => ParamInfo(Real, "Element length", "m"),
  :len_chord    => ParamInfo(Real, "Bend element chord element length", "m"),
  :e1           => ParamInfo(Real, "Bend element entrance face angle", ""),
  :e2           => ParamInfo(Real, "Bend element exit face angle", ""),
  :floor        => ParamInfo(Struct, "Global floor position and orientation", "", FloorPosition),
)

"""
Dictionary of parameters in the Branch.param dict.
"""
global latbranch_param = Dict(
  :ix_branch => ParamInfo(Int, "Index of branch in containing lat .branch() array"),
  :geometry  => ParamInfo(Switch, "open_geom or closed_geom"),
  :lat       => ParamInfo(Pointer, "Pointer to lattice containing the branch."),

)


"""
Dictionary of parameters in the Lat.param dict.
"""
global lat_param = Dict(
)


#-----------------------------------------------------------------------------------------
"""
Table of what parameters are associated with what elements
"""
global ele_param_by_type = Dict(  
  Dict(
    Bend           => Dict(),
    Drift          => Dict(),
    Marker         => Dict(),
    ThickMultipole => Dict(),
    Quadrupole     => Dict(),
  )
)



#-----------------------------------------------------------------------------------------

"""
Real parameters have default 0.0 if not specified.
"""

global param_defaults = Dict(
  :geometry => open_geom,
)