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

#---------------------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end
struct StringParseError <: Exception; msg::String; end

abstract type Error end

#---------------------------------------------------------------------------------------------------

eval_str(str::AbstractString) = eval(Meta.parse(str))

#---------------------------------------------------------------------------------------------------

field_names(x) = fieldnames(typeof(x))

#---------------------------------------------------------------------------------------------------
# it_ismutable & it_isimmutable

"""
    function it_ismutable(x)

Work around for the problem that ismutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_ismutable

function it_ismutable(x)
  if typeof(x) <: AbstractString; return false; end
  return ismutable(x)
end

"""
    function it_isimmutable(x)

Work around for the problem that isimmutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_isimmutable

function it_isimmutable(x)
  if typeof(x) <: AbstractString; return true; end
  return isimmutable(x)
end

#---------------------------------------------------------------------------------------------------

function integer(str::AbstractString, default::Number)
  try
    ix = parse(Int, str)
    return ix
  catch
    return default
  end
end

function float(str::AbstractString, default::Number)
  try
    flt = parse(Float, str)
    return ix
  catch
    return default
  end
end