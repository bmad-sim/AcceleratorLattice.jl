"""
    macro switch(base, names...)

Creates a set of "switch types" which are subtypes of `base`.
This is similar to what @enum does except the switch values are types instead of integers.

### Input

- `base` Base type name. Can be something like "MyBase <: SuperT" if the constructed
          Type is to be a subtype of some other type.

"""
macro switch(base, names...)
  eval( :(abstract type $(base) end) )

  if hasproperty(base, :args); base = base.args[1]; end    # Strip off "<: SuperT"
  for name in names
    eval( :(struct $(name) <: $(base); end) )
  end 
end


@switch Geometry OpenGeom ClosedGeom 
@switch BranchType TrackingBranch LordBranch 
@switch EleBodyLocation EntranceEnd Center ExitEnd BothEnds NoWhere EveryWhere
@switch Position UpStream Inside DownStream

