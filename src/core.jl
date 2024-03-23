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

@enumit("ApertureTypeSwitch Rectangular Elliptical")
@enumit("BendTypeSwitch SBend RBend")
@enumit("BodyLocationSwitch EntranceEnd BCenter ExitEnd BothEnds NoWhere EveryWhere")
@enumit("BoolSwitch False NotSet True")
@enumit("BranchGeometrySwitch Open Closed")
@enumit("CavityTypeSwitch StandingWave TravelingWave")
@enumit("ControlSlaveTypeSwitch Delta Absolute null")
@enumit("FieldCalcMethodSwitch FieldMap FieldStandard")
@enumit("InterpolationSwitch Linear Spline")
@enumit("LordStatusSwitch NotALord SuperLord MultipassLord Governor") 
@enumit("SlaveStatusSwitch NotASlave SuperSlave MultipassSlave")
@enumit("StreamLocationSwitch UpstreamEnd Center Inside DownstreamEnd")
@enumit("TrackingMethodSwitch RungeKutta TimeRungeKutta TrackingStandard")
@enumit("TrackingStateSwitch PreBorn Alive PreTrack Lost LostNegX LostPosX LostNegY LostPosY LostPz LostZ")

#---------------------------------------------------------------------------------------------------
# holly_type

"""
    holly_type(str::AbstractString)

Makes an abstract type from the first word and makes concrete types that inherit from the abstract type
from the other words in the string.
""" holly_type

macro holly_type(str::AbstractString)
  tlist = split(str)
  eval( Meta.parse("abstract type $(tlist[1]) end") )
  str2 = join(tlist, ',')
  eval( Meta.parse("export $str2") )

  for tp in tlist[2:end]
    eval( Meta.parse("struct $tp <: $(tlist[1]); end") )
  end
end

@holly_type("EleGeometrySwitch Straight Circular ZeroLength PatchGeom GirderGeom CrystalGeom MirrorGeom")

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