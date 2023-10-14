#-------------------------------------------------------------------------------------
# Using

## using OffsetArrays
using PyFormattedStrings
using Accessors
using LinearAlgebra
using Rotations

#-------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end
struct StringParseError <: Exception; msg::String; end

abstract type Error end

#---------------------------------------------------------------------------------------------------

Quat64 = QuatRotation{Float64}
Vector64 = Vector{Float64}

#-------------------------------------------------------------------------------------
# The Rotation.jl package displays the 3x3 rotation matrix with 
# the show command which is not what is wanted.

function Base.show(io::IO, ::MIME"text/plain", q::QuatRotation{T}) where T
  println(io, typeof(q))
  println(io, f"  ({q.q.s}, {q.q.v1}, {q.q.v2}, {q.q.v3})")
end

function Base.show(io::IO, q::QuatRotation{T}) where T
  print(io, f"({q.q.s}, {q.q.v1}, {q.q.v2}, {q.q.v3})")
end

function Base.show(io::IO, ::MIME"text/plain", a::AngleAxis{T}) where T
  println(io, typeof(a))
  println(io, f"  ({a.theta}, {a.axis_x}, {a.axis_y}, {a.axis_z})")
end

function Base.show(io::IO, ::MIME"text/plain", rv::RotationVec{T}) where T
  println(io, typeof(rv))
  println(io, f"  ({rv.sx}, {rv.sy}, {rv.sz})")
end

rot(q::QuatRotation, v::Vector) = Vector(q * v)

#-------------------------------------------------------------------------------------

field_names(x) = fieldnames(typeof(x))