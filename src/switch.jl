"""
    abstract type Switch end

Base type for switches.
See the documentation for `@switch` for more details.
""" Switch

abstract type Switch end

#---------------------------------------------------------------------------------------------------
# macro switch

"""
    macro switch(base, names...)

The macro creates a "switch group".

A switch group is a set of switch values along with a switch group identifier.
The values are all types and the identifier is the Union of all the values.

This is similar to what @enum does except with switches, a given switch value may be used
in different switch groups. 

### Input

- `base`    Switch group identifier.
- `names`   Switch group values.

### Output

- A struct is made is made for each of the `names` all of which are children of `Switch`.
- The `base` is defined to be the Union of all the name structs.
   
### Example

```
  @switch PositionSwitch UpStream Inside DownStream
```

This creates structs `UpStream`, `Inside`, and `DownStream`. 
The variable `PositionSwitch` is created as the Union of the three value structs.

Use examples:
```
  function my_func(pos::PositionSwitch, ...) = ...   # Will match to any switch value.
  function my_func2(in::Inside, ...) = ...           # Will match to Inside struct.
```

### Notes:

Use `isa` to test for valid switch values EG: `OpenGeom isa GeometrySwitch` returns true.

Use `show` (or just type the name in the REPL) to show the switch values for a given switch 
group variable. EG: show(GeometrySwitch).
""" switch

macro switch(base, names...)
  # If a name is not defined, define a struct with that name.
  for name in names
    if ! isdefined(@__MODULE__, name)
      eval( :(abstract type $(name) <: Switch end) )
      eval( :(export $(name)) )
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
  return nothing
end

#---------------------------------------------------------------------------------------------------
# function show

"""
    function show_switch(io::IO, switchval::Type{T}) where T <:Switch

Given one switch value, print all possible values of the switch group.
Called through the Base.show command.
See `@switch` documentation for more details.
""" show_switch

function show_switch(io::IO, switchval::Type{T}) where T <:Switch
  # Turn switchval into string since using eval on switchval causes infinite recursion.
  vstr = string(switchval)
  for (key, tuple) in switch_list_dict
    if vstr in [string(x) for x in tuple]
      println(io, f"Switch group: {key}")
      for t in tuple
        println(io, f"    {t}")
      end
    end
  end
end

Base.show(io::IO, ::MIME"text/plain", switchval::Type{<:Switch}) = show_switch(stdout, switchval)
Base.show(switchval::Type{<:Switch}) = show_switch(stdout, switchval)

#---------------------------------------------------------------------------------------------------

@switch ApertureTypeSwitch Rectangular Elliptical
@switch BranchTypeSwitch TrackingBranch LordBranch 
@switch CavityTypeSwitch StandingWave TravelingWave
@switch EleBodyLocationSwitch EntranceEnd Center ExitEnd BothEnds NoWhere EveryWhere
@switch FieldCalcMethodSwitch FieldMap BmadStandard
@switch BranchGeometrySwitch OpenGeom ClosedGeom 
@switch PositionSwitch UpStream Inside DownStream
@switch TrackingMethodSwitch RungeKutta TimeRungeKutta BmadStandard
@switch EleGeometrySwitch Straight Circular ZeroLength PatchGeom GirderGeom CrystalGeom MirrorGeom
@switch BendTypeSwitch SBend RBend

