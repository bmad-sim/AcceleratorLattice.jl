#-------------------------------------------------------------------------------------
# Using

using OffsetArrays
using PyFormattedStrings
using Accessors

#-------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct BmadParseError <: Exception; msg::String; end

#-------------------------------------------------------------------------------------
# vector

"""
Return a vector version of `this`
"""

function vector(this)
  if this isa Vector; return this; end
  if this isa Tuple; return [item for item in this]; end
  return [this]
end

#-------------------------------------------------------------------------------------
# Misc

"NaI stands for NotAnInteger. Technically equal to -987654321."
NaI = -987654321