#-------------------------------------------------------------------------------------
# Using

using OffsetArrays
using PyFormattedStrings
using Accessors
using LinearAlgebra

#-------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end

