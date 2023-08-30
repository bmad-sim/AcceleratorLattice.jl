"""
    abstract type Switch end

Base type for switches.
See the documentation for `@switch` for more details.
"""
abstract type Switch end

#---------------------------------------------------------------------------------------------------
# macro switch

"""
    macro switch(base, names...)

The macro creates a "switch group" and the function prints.
A switch group is a set of switch values along with a switch group identifier.
The values are all types and the identifier is the Union of all the values.

This is similar to what @enum does except with switches, a given switch value may be used
in different switch groups. 

### Input

- `base` Base type name. Can be something like `MyBase <: SuperT` if the constructed
          Type is to be a subtype of some other type.

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
  eval( Meta.parse("show_switch(io::IO, id::Type{$base}) = show_switch_by_id(io::IO, id)") )
  return nothing
end

#---------------------------------------------------------------------------------------------------
# function show

"""
    function show_switch(io::IO, switchval::Type{T}) where T <:Switch

Given one switch value, print all possible values of the switch group.
Called through the Base.show command.
See `@switch` documentation for more details.
"""
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

"""
function show_switch_by_id(io::IO, id)
  println("Switch values:")
  for (key, vals) in switch_list_dict
    if eval(key) != id; continue; end
    for val in vals
      println(f"    {val}")
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

