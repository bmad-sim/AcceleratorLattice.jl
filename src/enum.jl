#---------------------------------------------------------------------------------------------------
# enum

"""
    enum(str::AbstractString)

Makes a list into an enum group and exports the names. 
See `EnumX.jl` documentation on details on the properties of the enums.

This function also overloads Base.string so that something like `string(Lord.NOT)` 
will return "Lord.NOT" instead of just "NOT".

The `str` argument has the same syntax as given in `EnumX`. Example:
```
  enum("Lord NOT SUPER MULTIPASS")
```
This will create a `Lord` emum group with values `Lord.NOT`, `Lord.SUPER`, and `Lord.MULTIPASS`

Also see `enum_add` and `holy_type`

""" 
function enum(str::AbstractString)
  eval_str("@enumx $str")
  words = split(str)
  eval( Meta.parse("export $(words[1])") )
  s = "Base.string(z::$(words[1]).T) = \"$(words[1]).\" * string(Symbol(z))"
  eval_str(s)
end

enum("BendType SECTOR RECTANGULAR")
enum("BodyLoc ENTRANCE_END CENTER EXIT_END BOTH_ENDS NOWHERE EVERYWHERE")
enum("BranchGeometry OPEN CLOSED")
enum("Cavity STANDING_WAVE TRAVELING_WAVE")
enum("Lord NOT SUPER MULTIPASS GOVERNOR") 
enum("Slave NOT SUPER MULTIPASS")
enum("Loc UPSTREAM_END CENTER INSIDE DOWNSTREAM_END")
enum("Select UPSTREAM DOWNSTREAM")
enum("ExactMultipoles OFF HORIZONTALLY_PURE VERTICALLY_PURE")
enum("FiducialPt ENTRANCE_END CENTER EXIT_END NONE")
enum("TrackingMethod RUNGE_KUTTA TIME_RUNGE_KUTTA STANDARD")
enum("ParticleState PREBORN ALIVE PRETRACK LOST LOST_NEG_X LOST_POS_X LOST_NEG_Y LOST_POS_Y LOST_PZ LOST_Z")

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
    enum_add(str::AbstractString)

Adds values to an existing enum group.
See `enum` for details of creating an enum group.

## Example 
To add to an existing enum group called `BendType` do
```
enum("BendType SECTOR RECTANGULAR")    # Define BendType group with two values
enum_add("BendType CORKSCREW HELIX")   # Add two more values
```
"""
function enum_add(str::AbstractString)
  words = split(str)
  group = eval_str("$(words[1])")

  components = names(group, all = true)
  # components[1] is something like `Symbol("#93#check_valid#1")` so reject components with `#` char.
  # Also reject the "T" component since this defines the type.
  for c in components
    c_str = string(c)
    if c_str == "T" || occursin("#", c_str) || c_str == words[1]; continue; end
    str *= " " * c_str
  end

  eval_str("@enumx $str")
end


#---------------------------------------------------------------------------------------------------
# holly_type

"""
    holly_type(atype::AbstractString, ctypes::Vector)

Makes an abstract type from the first word and makes concrete types that inherit from the abstract type
from the other words in the string. This group can be used like an `enum` group. 
The difference is that `holly_type` values can be used with dispatching.
The drawback is that the same struct name cannot be used with different groups.

## Example
```
holly_type("ApertureShape" ["RECTANGULAR", "ELLIPTICAL")
```
This will create structs `RECTANGULAR`, `ELLIPTICAL` which inherit from `ApertureShape`.
""" holly_type

function holly_type(atype::AbstractString, ctypes::Vector)
  eval( Meta.parse("abstract type $atype end") )
  eval( Meta.parse("export $atype") )

  for ct in ctypes
    eval( Meta.parse("struct $ct <: $atype; end") )
  end
end

holly_type("EleGeometrySwitch", ["STRAIGHT", "CIRCULAR", "ZERO_LENGTH", 
                   "PATCH_GEOMETRY", "GIRDER_GEOMETRY", "CRYSTAL_GEOMETRY",  "MIRROR_GEOMETRY"])

holly_type("ApertureShape", ["RECTANGULAR", "ELLIPTICAL"])