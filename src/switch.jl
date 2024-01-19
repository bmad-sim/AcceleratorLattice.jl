"""
    abstract type Switch

Base type for switch group values.

A switch `group` is a set of `group values` along with the switch `group identifier`.
The `group values` are abstract types which inherit from the abstract type `Switch`.
The `group identifier` is the Union of all the `group value` types in the set.

This is similar to what the Jula `enum` except with switches, a given group value may be used
in different switch groups. 

To create a switch group, use the `@switch` macro.

Convention: Use a `Switch` suffix for `group identifier` values.

### Example

```
  @switch TrackLocationSwitch UpStream Inside DownStream
```

This creates abstract types `UpStream`, `Inside`, and `DownStream` and the identifier 
`TrackLocationSwitch` is the Union of the three abstract types:
```
  TrackLocationSwitch -> Union{Type{DownstreamEnd}, Type{Inside}, Type{UpstreamEnd}}
```

### Use Examples

After creating the `TrackLocationSwitch` group as shown above, the switch group can be used
with function signitures:
```
  function my_func(pos::TrackLocationSwitch, ...) = ...   # Will match to any switch value.
  function my_func2(in::Inside, ...) = ...                # Will match to Inside struct.
```

### Notes:

Use `isa` to test for valid switch values EG: `Inside isa TrackLocationSwitch` returns true.

Use `show` (or just type the value in the REPL) to show the switch values for a given switch 
group variable. EG: show(GeometrySwitch).

Use `show_groups` to see all the groups associated with a given value. EG: `show_groups(Inside)`.

The variable `switch_list_dict` is a Dict that maps identifiers to values. Just type this name
in the REPL to see a full list of switch groups.

Use `subtypes(Switch)` to see an alphabetical list all the values of all the switch groups.
""" Switch

abstract type Switch end

#---------------------------------------------------------------------------------------------------
# macro switch

"""
    macro switch(identifier, values...)

Creates a `switch group`. See `? Switch` for basic switch documentation.


### Input

- `identifier`    Switch group identifier.
- `values`        Switch group values.

### Output

- An abstract type is made for each of the `values` all of which are children of the abstract
type `Switch`.
- The `identifier` is defined to be the Union of all the value abstract types.
   
### Example

```
  @switch TrackLocationSwitch UpStream Inside DownStream
```

This creates abstract types `UpStream`, `Inside`, and `DownStream` and the identifier 
`TrackLocationSwitch` is the Union of the three abstract types:
```
  TrackLocationSwitch -> Union{Type{DownstreamEnd}, Type{Inside}, Type{UpstreamEnd}}
```
"""
macro switch(identifier, values...)
  # If a value is not defined, define a type with that value.
  for value in values
    if ! isdefined(@__MODULE__, value)
      eval(:(abstract type $value  <: Switch end))
      eval(:(export $value))
    end
  end

  # Define identifier as the union of all values.
  str = "$(identifier) = Union{"
  for value in values
    str *= "Type{$value},"
  end
  str *= "}"
  eval( Meta.parse(str) )

  # Add to switch_list_dict
  if ! isdefined(@__MODULE__, :switch_list_dict)
    eval( Meta.parse("switch_list_dict = Dict()") )
  end
  eval(Meta.parse("switch_list_dict[:$identifier] = $values"))
  eval(:(export $identifier))
  return nothing
end

#---------------------------------------------------------------------------------------------------
# show_group

"""
    function show_switch(io::IO, switchval::Type{T}) where T <:Switch

Given one switch value, print all possible values of the switch group.
See `@switch` documentation for more details.
""" show_groups

function show_groups(switchval::Type{T}) where T <:Switch
  found = false
  for (key, tuple) in switch_list_dict
    if !(Symbol(switchval) in tuple); continue; end
    println(f"Switch group: {key}")
    for t in tuple
      println(f"    {t}")
    end
    found = true
  end

  if !found; println(f"value not found in any switch groups: {switchval}"); end
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


