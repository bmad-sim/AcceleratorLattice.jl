#---------------------------------------------------------------------------------------------------
# enumit

"""
    enumit(str::AbstractString)

Makes list into a enum group and exports the names.
Also overloads Base.string so that something like `string(Lord.NOT)` will return "Lord.NOT"
instead of just "NOT". Exception: `BranchGeometry.OPEN` and `BranchGeometry.CLOSED` will
return `OPEN` and `CLOSED`.
""" enumit

macro enumit(str::AbstractString)
  eval( Meta.parse("@enumx $str") )
  str_words = split(str)
  str2 = join(str_words, ',')
  eval( Meta.parse("export $str2") )
  s = "Base.string(z::$(str_words[1]).T) = \"$(str_words[1]).\" * string(Symbol(z))"
  if str_words[1] != "BranchGeometry"; eval( Meta.parse(s) ); end
end

@enumit("ApertureShape RECTANGULAR ELLIPTICAL")
@enumit("BendType SECTOR RECTANGULAR")
@enumit("BodyLoc ENTRANCE_END CENTER EXIT_END BOTH_ENDS NOWHERE EVERYWHERE")
@enumit("BranchGeometry OPEN CLOSED")
@enumit("Cavity STANDING_WAVE TRAVELING_WAVE")
@enumit("FieldCalc MAP STANDARD")
@enumit("Interpolation LINEAR SPLINE")
@enumit("Lord NOT SUPER MULTIPASS GOVERNOR") 
@enumit("Slave NOT SUPER MULTIPASS")
@enumit("Loc UPSTREAM_END CENTER INSIDE DOWNSTREAM_END")
@enumit("Select UPSTREAM DOWNSTREAM")

@enumit("TrackingMethod RUNGE_KUTTA TIME_RUNGE_KUTTA STANDARD")
@enumit("ParticleState PREBORN ALIVE PRETRACK LOST LOST_NEG_X LOST_POS_X LOST_NEG_Y LOST_POS_Y LOST_PZ LOST_Z")

# Useful abbreviations

CLOSED::BranchGeometry.T = BranchGeometry.CLOSED
OPEN::BranchGeometry.T = BranchGeometry.OPEN


#---------------------------------------------------------------------------------------------------
# holly_type

"""
    holly_type(atype::AbstractString, ctypes::Vector)

Makes an abstract type from the first word and makes concrete types that inherit from the abstract type
from the other words in the string.
""" holly_type

function holly_type(atype::AbstractString, ctypes::Vector)
  eval( Meta.parse("abstract type $atype end") )
  eval( Meta.parse("export $atype") )

  for ct in ctypes
    eval( Meta.parse("struct $ct <: $atype; end") )
  end
end

holly_type("EleGeometrySwitch", ["Straight", "Circular", "ZeroLength", 
                                  "PatchGeom", "GirderGeom", "CrystalGeom",  "MirrorGeom"])

