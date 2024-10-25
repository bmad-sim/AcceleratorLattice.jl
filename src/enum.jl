# Defines enums and Holy traits.

#---------------------------------------------------------------------------------------------------
# enum

"""
    enum(group_name::AbstractString, values::Vector, docstr::AbstractString)

Makes a list into an enum group and exports the names of the group and values. 
See `EnumX.jl` documentation on details on the properties of the enums.

`docstr` is used to create a documentation string for the group name that is put in the Julia help system.

This function also overloads Base.string so that something like `string(Lord.NOT)` 
will return "Lord.NOT" instead of just "NOT".

Example:
```
  enum("Lord" ["NOT", "SUPER", "MULTIPASS"], "Lord types.")
```
This will create a `Lord` emum group with values `Lord.NOT`, `Lord.SUPER`, and `Lord.MULTIPASS`

Also see `enum_add` and `holy_traits`

""" 
function enum(group_name::AbstractString, values::Vector, docstr::AbstractString)
  eval_str("@enumx $group_name $(join(values, " "))")
  eval_str("export $(group_name)")
  s = "Base.string(z::$(group_name).T) = \"$(group_name).\" * string(Symbol(z))"
  eval_str(s)

  global global_docstr = """
    Module $(group_name)
Enum group. Used to describe: $(docstr)\\\n
Possible values (subtypes) for this group:\n
"""

  for val in values
    global_docstr *= "•  `$group_name.$val`\\\n"
  end

  eval_str("@doc global_docstr $group_name")
end

enum("BendType", ["SECTOR", "RECTANGULAR"], "Logical shape of a Bend.")
enum("BodyLoc", ["ENTRANCE_END", "CENTER", "EXIT_END", "BOTH_ENDS", "NOWHERE", "EVERYWHERE"], 
                                                    "Location in relation to an element's body.")
enum("BranchGeometry", ["OPEN", "CLOSED"], "Geometry of a branch.")
enum("Cavity", ["STANDING_WAVE", "TRAVELING_WAVE"], "RF cavity type.")
enum("Lord", ["NOT", "SUPER", "MULTIPASS", "GOVERNOR GIRDER"], "Type of lord this element is.") 
enum("Slave", ["NOT", "SUPER", "MULTIPASS"], "Type of slave this element is.")
enum("Loc", ["UPSTREAM_END", "CENTER", "INSIDE", "DOWNSTREAM_END"], "Location in relation to machine coordinates.")
enum("Select", ["UPSTREAM", "DOWNSTREAM"], "What to select in case of ambiguity.")
enum("ExactMultipoles", ["OFF", "HORIZONTALLY_PURE", "VERTICALLY_PURE"], "Bend multipole coefficient meaning." )
enum("FiducialPt", ["ENTRANCE_END", "CENTER", "EXIT_END", "NONE"], 
                                      "Fiducial point location in relation to body coordinates.")
enum("TrackingMethod", ["RUNGE_KUTTA", "TIME_RUNGE_KUTTA", "STANDARD"], "Particle tracking method.")
enum("ParticleState", ["PREBORN", "ALIVE", "PRETRACK", "LOST", "LOST_NEG_X", "LOST_POS_X", 
                         "LOST_NEG_Y", "LOST_POS_Y", "LOST_PZ", "LOST_Z"], "Particle state.")

# Useful abbreviations

"""
    const CLOSED::BranchGeometry.T = BranchGeometry.CLOSED
    const OPEN::BranchGeometry.T = BranchGeometry.OPEN

Useful abbreviations since `OPEN` and `CLOSED` are used a lot.
""" OPEN, CLOSED

const CLOSED::BranchGeometry.T = BranchGeometry.CLOSED
const OPEN::BranchGeometry.T = BranchGeometry.OPEN

#---------------------------------------------------------------------------------------------------
# enum_add

"""
    enum_add(group_name::AbstractString, values::Vector)

Adds values to an existing enum group and exports the names.
See the `enum` function documentation for details of creating an enum group.

## Example 
To add to an existing enum group called `BendType` do
```
enum("BendType", ["SECTOR", "RECTANGULAR"], "Type of bend.")  # Define BendType group with two values
enum_add("BendType", ["CORKSCREW", "HELIX"])   # Add two more values
```
"""
function enum_add(group_name::AbstractString, values::Vector)
  group = eval_str("$(group_name)")

  components = names(group, all = true)
  # A component can be something like `Symbol("#93#check_valid#1")` so reject components with `#` char.
  # Also reject the "T" component since this defines the type.
  for c in components
    c_str = string(c)
    if c_str == "T" || occursin("#", c_str) || c_str == group_name; continue; end
    enum_group *= " " * c_str
  end

  eval_str("@enumx $enum_group $(join(values, " "))")
  return nothing
end


#---------------------------------------------------------------------------------------------------
# holy_traits

"""
    holy_traits(atype::AbstractString, values::Vector, descrip::AbstractString = "")

Makes an abstract type from `atype` and makes concrete types (called "values" or "traits") 
from the `values`. 
The values inherit from `atype`. This group can be used like an `enum` group. 
The difference is that `holy_traits` values can be used with function dispatching.
The drawback is that the same value name cannot be used with different Holy trait groups.

`descrip` is a descriptive string used in creating a docstring.

`atype` and all `values` will be exported.

## Example
```
holy_traits("ApertureShape" ["RECTANGULAR", "ELLIPTICAL"], "Shape of aperture.")
```
This will create structs `RECTANGULAR`, `ELLIPTICAL` which inherit from `ApertureShape`.
""" holy_traits

function holy_traits(atype::AbstractString, values::Vector, descrip::AbstractString = "")
  eval_str("abstract type $atype end")
  eval_str("export $atype")

  global doc_str = """
    abstract type $atype <: Any
Holy trait type group use to describe: $descrip\\\n
Possible values for this group:\n
"""

  for val in values
    eval_str("struct $val <: $atype; end")
    eval_str("export $val")
    doc_str *= "•  `$val`\\\n"
  end
  
  eval_str("@doc doc_str $atype")
  return nothing
end

holy_traits("EleGeometry", ["STRAIGHT", "CIRCULAR", "ZERO_LENGTH", 
                   "PATCH_GEOMETRY", "GIRDER_GEOMETRY", "CRYSTAL_GEOMETRY", "MIRROR_GEOMETRY"], 
                   "Element geometry.")

holy_traits("ApertureShape", ["RECTANGULAR", "ELLIPTICAL", "VERTEX", "CUSTOM"], "The shape of the aperture.")