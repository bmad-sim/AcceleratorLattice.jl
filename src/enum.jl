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

@enumit("ApertureTypeSwitch rectangular elliptical")
@enumit("BendTypeSwitch sbend rbend")
@enumit("BodyLocationSwitch entrance_end b_center exit_end both_ends nowhere everywhere")
@enumit("BoolSwitch no not_set yes")
@enumit("BranchGeometrySwitch open closed")
@enumit("CavityTypeSwitch standing_wave traveling_wave")
@enumit("ControlSlaveTypeSwitch delta absolute control_not_set")
@enumit("FieldCalcMethodSwitch field_map field_standard")
@enumit("InterpolationSwitch linear spline")
@enumit("LordStatusSwitch not_a_lord super_lord multipass_lord governor") 
@enumit("SlaveStatusSwitch not_a_slave super_slave multipass_slave")
@enumit("StreamLocationSwitch upstream_end center inside downstream_end")
@enumit("TrackingMethodSwitch rungekutta time_rungekutta standard_tracking")
@enumit("TrackingStateSwitch preborn alive pretrack lost lost_neg_x lost_pos_x lostNegY LostPosY LostPz LostZ")
