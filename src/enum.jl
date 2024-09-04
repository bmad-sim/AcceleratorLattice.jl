#---------------------------------------------------------------------------------------------------
# enumit

"""
    enumit(str::AbstractString)

Makes list into a enum group and exports the names
""" enumit

macro enumit(str::AbstractString)
  eval( Meta.parse("@enum $str") )
  str2 = join(split(str), ',')
  eval( Meta.parse("export $str2") )
end

@enumit("ApertureType RECTANGULAR ELLIPTICAL")
@enumit("BendType SBEND RBEND")
@enumit("BodyLocation ENTRANCE_END B_CENTER EXIT_END BOTH_ENDS NOWHERE EVERYWHERE")
@enumit("BranchGeometry OPEN CLOSED")
@enumit("CavityType STANDING_WAVE TRAVELING_WAVE")
@enumit("ControlSlaveType DELTA ABSOLUTE CONTROL_NOT_SET")
@enumit("FieldCalcMethod FIELD_MAP FIELD_STANDARD")
@enumit("Interpolation LINEAR SPLINE")
@enumit("LordStatus NOT_A_LORD SUPER_LORD MULTIPASS_LORD GOVERNOR") 
@enumit("SlaveStatus NOT_A_SLAVE SUPER_SLAVE MULTIPASS_SLAVE")
@enumit("StreamLocation UPSTREAM_END CENTER INSIDE DOWNSTREAM_END")

@enumit("TrackingMethod RUNGE_KUTTA TIME_RUNGE_KUTTA STANDARD_TRACKING")
@enumit("TrackingState PREBORN ALIVE PRETRACK LOST LOST_NEG_X LOST_POS_X LOST_NEG_Y LOST_POS_Y LOST_PZ LOST_Z")
