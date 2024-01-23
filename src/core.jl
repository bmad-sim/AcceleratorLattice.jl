#---------------------------------------------------------------------------------------------------
# Using

## using OffsetArrays
using InteractiveUtils      # Defines subtypes function
using PyFormattedStrings
using Accessors
using LinearAlgebra
using Rotations

import Base.Cartesian.lreplace

#---------------------------------------------------------------------------------------------------
# Exceptions

struct InfiniteLoop <: Exception;   msg::String; end
struct RangeError <: Exception;     msg::String; end
struct LatticeParseError <: Exception; msg::String; end
struct SwitchError <: Exception; msg::String; end
struct StringParseError <: Exception; msg::String; end

abstract type Error end

#---------------------------------------------------------------------------------------------------

eval_str(str::AbstractString) = eval(Meta.parse(str))

#---------------------------------------------------------------------------------------------------

QuatN = QuatRotation{Number}
Quat64 = QuatRotation{Float64}

#---------------------------------------------------------------------------------------------------
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
rot(q1::QuatRotation, q2::QuatRotation) = q1 * q2

#---------------------------------------------------------------------------------------------------

field_names(x) = fieldnames(typeof(x))

#---------------------------------------------------------------------------------------------------
# it_ismutable & it_isimmutable

"""
    function it_ismutable(x)

Work around for the problem that ismutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_ismutable

function it_ismutable(x)
  if typeof(x) <: AbstractString; return false; end
  return ismutable(x)
end

"""
    function it_isimmutable(x)

Work around for the problem that isimmutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_isimmutable

function it_isimmutable(x)
  if typeof(x) <: AbstractString; return true; end
  return isimmutable(x)
end

#---------------------------------------------------------------------------------------------------

function integer(str::AbstractString, default::Number)
  try
    ix = parse(Int, str)
    return Int64(ix)
  catch
    return Int64(default)
  end
end

function float(str::AbstractString, default::Number)
  try
    flt = parse(Float, str)
    return Float64(ix)
  catch
    return Float64(default)
  end
end