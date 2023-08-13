"""
    macro switch(base, names...)

Creates a set of "switch types" which are subtypes of `base`.
This is similar to what @enum does except the switch values are types instead of integers.

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



"""
macro switch(base, names...)
  eval( :(abstract type $(base) end) )
  # Something simple like base = Geom does not have args but base = Geom <
  if hasproperty(base, :args); base = base.args[1]; end    # Strip off "<: SuperT"

  eval( Meta.parse("$(base)Switch = (Type{<:$(base)})") )

  for name in names
    eval( :(struct $(name) <: $(base); end) )
  end 
end


@switch Geometry OpenGeom ClosedGeom 
@switch BranchType TrackingBranch LordBranch 
@switch EleBodyLocation EntranceEnd Center ExitEnd BothEnds NoWhere EveryWhere
@switch Position UpStream Inside DownStream
@switch ApertureType Rectangular Elliptical

