abstract type Switch end

"""
    macro switch(base, names...)

Creates a "switch" group. A switch group is a set of switch values along with a switch group
variable which represents the union of all the switch values. 

This is similar to what @enum does except with switches, a given switch value may be used
in different switch groups.

### Input

- `base` Base type name. Can be something like `MyBase <: SuperT` if the constructed
          Type is to be a subtype of some other type.

- `base2` Used for switch intersections.
### Output

- An abstract type with the `base` name is created.
- A "switch" type is created by appending `Switch` to the `base` name.
    This is used for function arguments.
    The switch type is defined to be Type{<: `base`}. That is, will match to any child of `base`
- A struct is made is made for each of the `names`. 
    Each of these is a child of `base`.

### Example

### Notes:

Use `isa` to test for valid switch values EG: `OpenGeom isa GeometrySwitch` returns true.
Use `show` to show the switch values for a given switch group variable. EG: show(GeometrySwitch)

"""
macro switch(base, names...)
  # If a name is not defined, define a struct with that name.
  for name in names
    if ! isdefined(@__MODULE__, name)
      eval( :(abstract type $(name) <: Switch end) )
    end
  end

  # Define base as the union of all names.
  str = "$(base) = Union{"
  for name in names
    str *= "Type{$name},"
  end
  str *= "}"
  eval( Meta.parse(str) )

  # Add to switch_list_dict
  if ! isdefined(@__MODULE__, :switch_list_dict)
    eval( Meta.parse("switch_list_dict = Dict()") )
  end
  eval( Meta.parse("switch_list_dict[:$base] = $names") )
end

"""
Shows groups that a switch value is in
"""

function switch(io::IO, switchval::Type{<:Switch})
  # Turn switchval into string since using eval on switchval causes infinite recursion. 
  vstr = string(switchval)
  for (key, tuple) in switch_list_dict
    if vstr in [string(x) for x in tuple]
      println(io, f"  In switch group: {key}")
    end
  end
end

switch(switchval::Type{<:Switch}) = show(stdout, switchval)



@switch ApertureTypeSwitch Rectangular Elliptical
@switch BranchTypeSwitch TrackingBranch LordBranch 
@switch CavityTypeSwitch StandingWave TravelingWave
@switch EleBodyLocationSwitch EntranceEnd Center ExitEnd BothEnds NoWhere EveryWhere
@switch FieldCalcMethodSwitch FieldMap BmadStandard
@switch GeometrySwitch OpenGeom ClosedGeom 
@switch PositionSwitch UpStream Inside DownStream
@switch TrackingMethodSwitch RungeKutta TimeRungeKutta BmadStandard

# {Symbol,Tuple{Symbol}}