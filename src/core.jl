# core.jl
# Utility routines that do not involve any structures defined by AcceleratorLattice.
# Also see: utilities.jl


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

