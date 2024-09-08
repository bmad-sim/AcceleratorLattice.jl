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
  str_split = split(str)
  str2 = join(str_split, ',')
  eval( Meta.parse("export $str2") )
  s = "Base.string(z::$(str_split[1]).T) = \"$(str_split[1]).\" * string(Symbol(z))"
  if str_split[1] != "BranchGeometry"; eval( Meta.parse(s) ); end
end

@enumit("ApertureShape RECTANGULAR ELLIPTICAL")
@enumit("BendType SECTOR RECTANGULAR")
@enumit("BodyLoc ENTRANCE_END CENTER EXIT_END BOTH_ENDS NOWHERE EVERYWHERE")
@enumit("BranchGeometry OPEN CLOSED")
## @enumit("EleGeometry STRAIGHT CIRCULAR ZEROLENGTH PATCH GIRDER CRYSTAL MIRROR") # See core.jl
@enumit("Cavity STANDING_WAVE TRAVELING_WAVE")
@enumit("SlaveControl DELTA ABSOLUTE NOT_SET")
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


