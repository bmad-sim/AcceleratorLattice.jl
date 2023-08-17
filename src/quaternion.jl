struct Quaternion
  q0::Float64
  vec::Vector{Float64}
end

const UNIT_QUAT = Quaternion(1.0, [0.0, 0.0, 0.0])

struct BiQuaternion
  q0::ComplexF64
  vec::Vector{ComplexF64}
end

"""
The `axis` vector is not necessarily normalized.
"""
struct AxisAngle
  angle::Float64
  axis::Vector{Float64}
end

Quaternion(qv::Vector) = Quaternion(qv[1], qv[2:end])
Quaternion(x::Real) = Quaternion(x, [0.0, 0.0, 0.0])

function Quaternion(aa::AxisAngle) 
  if aa.angle == 0; return UNIT_QUAT; end
  m = mag(aa.axis)
  if m == 0; throw(RangeError("length of axis is zero.")); end
  return Quaternion(cos(0.5*aa.angle), sin(0.5*aa.angle)*axis / m)
end

