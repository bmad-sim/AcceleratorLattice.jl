"""
    abstract type Switch end

Base type for switches.
See the documentation for `@switch` for more details.
""" Switch

abstract type Switch end

#---------------------------------------------------------------------------------------------------
# macro switch

"""
    macro switch(identifier, names...)

The macro creates a "switch group".

A switch `group` is a set of switch `names` along with a switch group `identifier`.
The `names` are all abstract types inherited from the abstract type `Switch`.
The identifier is the Union of all the names.

This is similar to what @enum does except with switches, a given switch name may be used
in different switch groups. 

### Input

- `identifier`    Switch group identifier.
- `names`         Switch group values.

### Output

- An abstract type is made for each of the `names` all of which are children of `Switch`.
- The `identifier` is defined to be the Union of all the name abstract types.
   
### Example

```
  @switch TrackLocationSwitch UpStream Inside DownStream
```

This creates abstract types `UpStream`, `Inside`, and `DownStream`. 
The variable `TrackLocationSwitch` is created as the Union of the three abstract types.

Use examples:
```
  function my_func(pos::TrackLocationSwitch, ...) = ...   # Will match to any switch value.
  function my_func2(in::Inside, ...) = ...           # Will match to Inside struct.
```

### Notes:

Use `isa` to test for valid switch values EG: `Open` isa GeometrySwitch` returns true.

Use `show` (or just type the name in the REPL) to show the switch values for a given switch 
group variable. EG: show(GeometrySwitch).
""" switch

macro switch(base, names...)
  # If a name is not defined, define a type with that name.
  for name in names
    if ! isdefined(@__MODULE__, name)
      eval(:(abstract type $name  <: Switch end))
      eval(:(export $name))
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
  eval(Meta.parse("switch_list_dict[:$base] = $names"))
  eval(:(export $base))
  return nothing
end

#---------------------------------------------------------------------------------------------------
# show_group

"""
    function show_switch(io::IO, switchval::Type{T}) where T <:Switch

Given one switch value, print all possible values of the switch group.
See `@switch` documentation for more details.
""" show_switch

function show_group(switchval::Type{T}) where T <:Switch
  found = false
  for (key, tuple) in switch_list_dict
    if !(Symbol(switchval) in tuple); continue; end
    println(f"Switch group: {key}")
    for t in tuple
      println(f"    {t}")
    end
    found = true
  end

  if !found; println(f"Name not found in any switch groups: {switchval}"); end
end

#---------------------------------------------------------------------------------------------------

@switch ApertureTypeSwitch Rectangular Elliptical
@switch BendTypeSwitch SBend RBend
@switch BoolSwitch False NotSet True
@switch BranchGeometrySwitch Open Closed
@switch BranchTypeSwitch TrackingBranch LordBranch 
@switch CavityTypeSwitch StandingWave TravelingWave
@switch ControlSlaveTypeSwitch Delta Absolute NotSet
@switch EleBodyLocationSwitch EntranceEnd Center ExitEnd BothEnds NoWhere EveryWhere
@switch EleBodyEndSwitch EntranceEnd ExitEnd
@switch EleBodyRefSwitch UpstreamEnd Center DownstreamEnd
@switch EleGeometrySwitch Straight Circular ZeroLength PatchGeom GirderGeom CrystalGeom MirrorGeom
@switch FieldCalcMethodSwitch FieldMap BmadStandard
@switch InterpolationSwitch Linear Spline
@switch RefLocationSwitch UpstreamEnd Center DownstreamEnd
@switch TrackLocationSwitch UpstreamEnd Inside DownstreamEnd
@switch TrackingMethodSwitch RungeKutta TimeRungeKutta BmadStandard
@switch TrackingStateSwitch PreBorn Alive NotSet Lost LostNegX LostPosX LostNegY LostPosY LostPz LostZ


