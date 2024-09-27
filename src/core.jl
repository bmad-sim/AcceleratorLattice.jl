# core.jl
# Utility routines that do not involve any structures defined by AcceleratorLattice.
# Also see: utilities.jl

#---------------------------------------------------------------------------------------------------
# Exceptions
# Not currently used. May be removed at a later date.

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end
struct StringParseError <: Exception; msg::String; end

abstract type Error end

#---------------------------------------------------------------------------------------------------
# E_tot

"""
   E_tot(species::Species; pc::Number = NaN, β::Number = NaN, E_kinetic::Number = NaN, γ::Number = NaN)
Returns the total energy (in `eV`). Only one of the optional arguments pc, β, E_kinetic, or γ should be set.

Also see the functions `pc`, `β`, `β1`, `E_kinetic`, and `γ`
""" E_tot 

function E_tot(species::Species; pc::Number = NaN, β::Number = NaN, E_kinetic::Number = NaN, γ::Number = NaN)
  if pc != NaN
    return sqrt(pc^2 + mass(species)^2)
  elseif β != NaN
    return mass(species) / sqrt(1 - β^2)
  elseif E_kinetic != NaN
    return E_kinetic + mass(species)
  elseif γ != NaN
    return γ * mass(species)
  else
    error("Not one of pc, β, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# pc

"""
   pc(species::Species; E_tot::Number = NaN, β::Number = NaN, E_kinetic::Number = NaN, γ::Number = NaN)
Returns the total energy (in `eV`). Only one of the optional arguments pc, β, E_kinetic, or γ should be set.

Also see the functions `E_tot`, `β`, `β1`, `E_kinetic`, and `γ`
""" pc

function pc(species::Species, E_tot::Number = NaN, β::Number = NaN, E_kinetic::Number = NaN, γ::Number = NaN)
  if E_tot != NaN
    return sqrt(E_tot^2 - mass(species)^2)
  elseif β != NaN
    return β * mass(species) / sqrt(1 - β^2)
  elseif E_kinetic != NaN
    return sqrt((E_kinetic + mass(species))^2 - mass(species)^2)
  elseif γ != NaN
    return mass(species) * sqrt(γ^2 - 1)
  else
    error("Not one of E_tot, β, E_kinetic, nor γ set.")
  end
end

#---------------------------------------------------------------------------------------------------
# eval_str

"""
    function eval_str(str::AbstractString)

Evaluates a string. Short for `eval(Meta.parse(str))`.
"""

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
"""

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

Useful for streamlining output when something like "\$(my_type)" would produce
a string with an "AcceleratorLattice." prefix.
"""

strip_AL(who) = replace(string(who), r"^AcceleratorLattice\." => "")

#---------------------------------------------------------------------------------------------------
# memloc
# "To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

#---------------------------------------------------------------------------------------------------
# cos_one

"""
    cos_one(x)

Function to calculate cos(x) - 1 to machine precision.
This is usful if angle can be near zero where the direct evaluation of cos(x) - 1 is inaccurate.
""" cos_one

cos_one(x) = -2.0 * sin(x/2.0)^2

#---------------------------------------------------------------------------------------------------
# modulo2

"""
! Function to return
!     mod2 = x + 2 * n * amp
! where n is an integer chosen such that
!    -amp <= mod2 < amp
"""

function modulo2(x, amp)
  m2 = mod(x, 2*amp)
  m2 < amp ? (return m2) : (return m2 - 2.0*amp)
end