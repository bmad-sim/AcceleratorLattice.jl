#-------------------------------------------------------------------------------------
# Using

using OffsetArrays
using PyFormattedStrings
using Accessors

#-------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end

