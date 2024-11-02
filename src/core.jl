# core.jl
# Utility routines that do not involve any structures defined by AcceleratorLattice.
# Also see: utilities.jl

#---------------------------------------------------------------------------------------------------
# E_tot

"""
   E_tot(species::Species; pc::Union{Number, Nothing} = nothing, β::Union{Number, Nothing} = nothing,
                         E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
   
Returns the total energy (in `eV`).
One and only one of the optional arguments pc, β, E_kinetic, or γ should be set.

Also see the functions `pc`, `β`, `β1`, `E_kinetic`, and `γ`
""" E_tot 

function E_tot(species::Species; pc::Union{Number, Nothing} = nothing, β::Union{Number, Nothing} = nothing, 
                           E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(pc)
    return sqrt(pc^2 + m^2)
  elseif !isnothing(β)
    return m / sqrt(1 - β^2)
  elseif !isnothing(E_kinetic)
    return E_kinetic + m
  elseif !isnothing(γ)
    return γ * m
  else
    error("Not one of pc, β, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# pc

"""
   pc(species::Species; E_tot::Union{Number, Nothing} = nothing, β::Union{Number, Nothing} = nothing, 
                          E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
   
Returns the total energy (in `eV`). 
One and only one of the optional arguments E_tot, β, E_kinetic, or γ should be set.

Also see the functions `E_tot`, `β`, `β1`, `E_kinetic`, and `γ`
""" pc

function pc(species::Species; 
                  E_tot::Union{Number, Nothing} = nothing, β::Union{Number, Nothing} = nothing, 
                          E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(E_tot)
    return sqrt(E_tot^2 - m^2)
  elseif !isnothing(β)
    return β * m / sqrt(1 - β^2)
  elseif !isnothing(E_kinetic)
    return sqrt((E_kinetic + m)^2 - m^2)
  elseif !isnothing(γ)
    return m * sqrt(γ^2 - 1)
  else
    error("Not one of E_tot, β, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# β

"""
   β(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                          E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
   
Returns the velocity `β` = `v/c`. 
One and only one of the optional arguments E_tot, pc, E_kinetic, or γ should be set.

Also see the functions `E_tot`, `pc`, `β1`, `E_kinetic`, and `γ`
""" β

function β(species::Species; 
                E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                          E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(E_tot)
    return sqrt(1 - (m / E_tot)^2)
  elseif !isnothing(pc)
    return 1 / sqrt(1 + (m / pc)^2)
  elseif !isnothing(E_kinetic)
    f = m / (E_kinetic + m)
    return sqrt(1 - f^2)
  elseif !isnothing(γ)
    return sqrt(1 - 1/γ^2)
  else
    error("Not one of E_tot, pc, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# β1

"""
   β1(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                          E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
Returns the quantity `1 - β` = `1 - v/c`. In the high energy limit, this is `1/(2γ^2)`.
β1 is computed such that in the high energy limit, round off error is not a problem.
One and only one of the optional arguments E_tot, pc, E_kinetic, or γ should be set.

Also see the functions `E_tot`; `pc`, `β`, `E_kinetic`, and `γ`
""" β1

function β1(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                           E_kinetic::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(E_tot)
    mm2 = (m / E_tot)^2
    return  mm2 / (1 + sqrt(1 - mm2))
  elseif !isnothing(pc)
    m = m
    return m^2 / (sqrt(m^2 + pc^2) * (sqrt(m^2 + pc^2) + pc))
  elseif !isnothing(E_kinetic)
    mm2 = (m / (E_kinetic + m))^2
    return  mm2 / (1 + sqrt(1 - mm2))
  elseif !isnothing(γ)
    mm2 = 1 / γ^2
    return  mm2 / (1 + sqrt(1 - mm2))
  else
    error("Not one of E_tot, pc, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# E_kinetic

"""
   E_kinetic(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                                    β::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
   
Returns the kinetic energy in `eV`.
One and only one of the optional arguments E_tot, pc, β, or γ should be set.

Also see the functions `E_tot`; `pc`, `β`, `β1`, and `γ`
""" E_kinetic

function E_kinetic(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                                         β::Union{Number, Nothing} = nothing, γ::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(pc)
    return pc^2 / (sqrt(pc^2 + m^2) + m)
  elseif !isnothing(β)
    return m * β^2 / (sqrt(1 - β^2) * (1 + sqrt(1 - β^2)))
  elseif !isnothing(E_tot)
    return E_tot - m
  elseif !isnothing(γ)
    return m * (γ - 1)
  else
    error("Not one of pc, β, E_tot, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# γ

"""
   γ(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                           β::Union{Number, Nothing} = nothing, E_kinetic::Union{Number, Nothing} = nothing)
   
Returns the total energy (in `eV`). 
One and only one of the optional arguments E_tot, pc, β, or E_kinetic should be set.

Also see the functions `pc`, `β`, `β1`, `E_kinetic`, and `γ`
""" γ 

function γ(species::Species; E_tot::Union{Number, Nothing} = nothing, pc::Union{Number, Nothing} = nothing, 
                           β::Union{Number, Nothing} = nothing, E_kinetic::Union{Number, Nothing} = nothing)
  m = mass(species)

  if !isnothing(pc)
    return sqrt((pc/m)^2 + 1)
  elseif !isnothing(β)
    return  1 / sqrt(1 - β^2)
  elseif !isnothing(E_kinetic)
    return 1 + E_kinetic / m
  elseif !isnothing(E_tot)
    return E_tot / m
  else
    error("Not one of pc, β, E_kinetic, nor γ set.")
  end
end


#---------------------------------------------------------------------------------------------------
# eval_str

"""
    eval_str(str::AbstractString)

Evaluates a string. Short for `eval(Meta.parse(str))`.
""" eval_str

eval_str(str::AbstractString) = eval(Meta.parse(str))

#---------------------------------------------------------------------------------------------------
# Base.length

"""
Returns the length in characters of the string representation of a Symbol.
Here the string representation includes the leading colon.
Example: length(:abc) => 4
""" Base.length

Base.length(sym::Symbol) = length(repr(sym))

#---------------------------------------------------------------------------------------------------
# index

"""
Index of substring in string. Assumes all characters are ASCII.
Returns 0 if substring is not found
""" index

function index(str::AbstractString, substr::AbstractString)
  ns = length(substr)
  for ix in range(1, length(str)-ns+1)
    if str[ix:ix+ns-1] == substr; return ix; end
  end

  return 0
end

#---------------------------------------------------------------------------------------------------
# strip_AL

"""
  function strip_AL(who) -> String

Returns a string stripped of prefix "AcceleratorLattice." if the prefix is present.

Useful for streamlining output when something like "\\\$(my_type)" would produce
a string with an "AcceleratorLattice." prefix.
""" strip_AL

strip_AL(who) = replace(string(who), r"^AcceleratorLattice\." => "")

#---------------------------------------------------------------------------------------------------
# memloc
# "To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

