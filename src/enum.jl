#---------------------------------------------------------------------------------------------------
# enumit

"""
    enumit(str::AbstractString)

Makes list into a enum group and exports the names
""" enumit

macro enumit(str::AbstractString)
  eval( Meta.parse("@enumx $str") )
  str2 = join(split(str), ',')
  eval( Meta.parse("export $str2") )
end

@enumit("ApertureType RECTANGULAR ELLIPTICAL")
@enumit("Bend SECTOR RECTANGULAR")
@enumit("BodyLoc ENTRANCE_END CENTER EXIT_END BOTH_ENDS NOWHERE EVERYWHERE")
@enumit("BranchGeometry OPEN CLOSED")
@enumit("Cavity STANDING_WAVE TRAVELING_WAVE")
@enumit("SlaveControl DELTA ABSOLUTE NOT_SET")
@enumit("FieldCalc MAP STANDARD")
@enumit("Interpolation LINEAR SPLINE")
@enumit("Lord NOT SUPER MULTIPASS GOVERNOR") 
@enumit("Slave NOT SUPER MULTIPASS")
@enumit("StreamLoc UPSTREAM_END CENTER INSIDE DOWNSTREAM_END")

@enumit("TrackingMethod RUNGE_KUTTA TIME_RUNGE_KUTTA STANDARD_TRACKING")
@enumit("TrackingState PREBORN ALIVE PRETRACK LOST LOST_NEG_X LOST_POS_X LOST_NEG_Y LOST_POS_Y LOST_PZ LOST_Z")
