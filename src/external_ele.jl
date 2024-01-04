#---------------------------------------------------------------------------------------------------
# lat_ele_dict

"""
    lat_ele_dict(lat::Lat)

Return a dictionary of `ele_name => Vector{Ele}` mapping of lattice element names to arrays of
elements with that name.

### Input

- `lat` -- Lattice to use.

### Output

Dict{String, Vector{Ele}} dictionary where the keys are element names and the values are 
vectors of elements of whose name matches the key

### Example

eled = lat_ele_dict(lat)    # Create Dictionary
eled["q23w"]                


"""

function lat_ele_dict(lat::Lat)
  eled = Dict{String,Vector{Ele}}()
  for branch in lat.branch
    for ele in branch.ele
      if haskey(eled, ele.name)
        eled[ele.name]
        push!(eled[ele.name], ele)
      else
        eled[ele.name] = Vector{Ele}([ele])
      end
    end
  end
  return eled
end

#---------------------------------------------------------------------------------------------------
# kill_external_ele

"""
Set external variables corresponding to elements with the same name in a lattice to `nothing`. 
(Currently there is no way to undefine the variables).
See also `create_external_ele`.

The `prefix` argument is needed if a prefix was given in `create_ele_vars`.

The `this_module` argument is needed if the variables are not in the `Main` module. 
Note: `@__MODULE__` is the name of the module of the calling routine.
"""
function kill_external_ele(lat::Lat; prefix::AbstractString = "", this_module = Main)
  for branch in lat.branch
    for ele in branch.ele
      nam = prefix * ele.name
      if !isdefined(this_module, Symbol(nam)); continue; end
      eval( :($(Symbol(nam)) = nothing) )
    end
  end
  return nothing
end

#---------------------------------------------------------------------------------------------------
# create_external_ele

"""
Creates `Ele` variables external to a lattice with the same name as the elements in the lattice.

For example, if "q23w" is the name of an element in the lattice, this routine will create a
variable with the name `q23w`. 

In the case where multiple lattice elements have the same name, the corresponding variable 
will be a vector of `Ele`s.

The `prefix` arg can be used to distinguish between elements of the same name in different lattices.

The `this_module` arg is needed if the variables are not to be in the Main module. 
Use `@__MODULE__` for the name of the module of the code calling `create_ele_vars`.

The routine kill_external_ele will remove these external elements.
"""
function create_external_ele(lat::Lat; prefix::AbstractString = "", this_module = Main)
  eled = lat_ele_dict(lat)

  for (name, evec) in eled
    if length(evec) == 1
      eval( :($(Symbol(this_module)).$(Symbol(name)) = $(evec[1])) )
    else
      eval( :($(Symbol(this_module)).$(Symbol(name))= $(evec)) )
    end
  end
  return nothing
end

#---------------------------------------------------------------------------------------------------
# create_unique_ele_names!

"""
function create_unique_ele_names!(lat::Lat; suffix::AbstractString = "!#")

Modifies a lattice so that all elements have a unique name.

For elements whose names are not unique, the `suffix` arg is appended to the element name
and an integer is substituted for  the "#" character in the suffix arg. If no "#" 
character exists, a "#" character is appended to the suffix arg.
"""
function create_unique_ele_names!(lat::Lat; suffix::AbstractString = "!#")
  if !occursin("#", suffix); suffix = suffix * "#"; end
  eled = lat_ele_dict(lat)

  for (name, evec) in eled
    if length(evec) == 1; continue; end
    for (ix, ele) in enumerate(evec)
      ele.name = ele.name * replace(suffix, "#" => string(ix))
    end
  end

  return nothing
end
