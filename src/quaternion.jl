abstract type AbstractQuaternion end

struct Quaternion <: AbstractQuaternion
  q0::Float64
  vec::Vector{Float64}
end

const UNIT_QUAT = Quaternion(1.0, [0.0, 0.0, 0.0])

struct BiQuaternion <: AbstractQuaternion
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

#---------------------------------------------------------------------------------------------------

Quaternion(qv::Vector) = Quaternion(qv[1], qv[2:end])
Quaternion(x::T) where T <: Number = Quaternion(x, [0.0, 0.0, 0.0])

function Quaternion(aa::AxisAngle) 
  if aa.angle == 0; return UNIT_QUAT; end
  m = mag(aa.axis)
  if m == 0; throw(RangeError("length of axis is zero.")); end
  return Quaternion(cos(0.5*aa.angle), sin(0.5*aa.angle)*axis / m)
end

function Quaternion(m::Matrix{T}) where T <: Number
  trace = tr(m)

  if trace > 0
    s = 0.5 / sqrt(1 + trace)
    return Quaternion(0.25 / s, s*[m[3,2]-m[2,3], m[1,3]-m[3,1], m[2,1]-m[1,2]])

  elseif m[1,1] > m[2,2] && m[1,1] > m[3,3]
    s = 2 * sqrt(1 + m[1,1] - m[2,2] - m[3,3])
    return Quaternion((m[3,2] - m[2,3]) / s, [0.25*s, (m[1,2] + m[2,1])/s, (m[1,3] + m[3,1])/s])

  elseif m[2,2] > m[3,3]
    s = 2 * sqrt(1 + m[2,2] - m[1,1] - m[3,3])
    return Quaternion((m[1,3] - m[3,1])/s, [(m[1,2] + m[2,1])/s, 0.25 * s, (m[2,3] + m[3,2])/s])

  else
    s = 2 * sqrt(1 + m[3,3] - m[1,1] - m[2,2])
    return Quaternion((m[2,1] - m[1,2])/s, [(m[1,3] + m[3,1])/s, (m[2,3] + m[3,2])/s, 0.25 * s])
  end
end

doq(q1::Quaternion, q2::Quaternion) = q1.q0 + q2.q0 + dot(q1.vec, q2.vec)
inv(q::Quaternion) = Quaternion(q.q0/

conj(q::AbstractQuaternion) = typeof(q)(q.q0, -q.vec)

#---------------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------------

"""
It is not assumed that the quaternion is normalized
"""

function RotMat(q::Quaternion)
  sq1 = q.q0 * q.q0
  sqx = q.vec[1] * q.vec[1]
  sqy = q.vec[2] * q.vec[2]
  sqz = q.vec[3] * q.vec[3]
  rmat = Matrix{Float64}(undef,3,3)

  # invs (inverse square length) is only required if quaternion is not already normalised                                       

  invs = 1 / (sqx + sqy + sqz + sq1)
  rmat[1,1] = ( sqx - sqy - sqz + sq1) * invs   # since sq1 + sqx + sqy + sqz =1/invs * invs                                     
  rmat[2,2] = (-sqx + sqy - sqz + sq1) * invs
  rmat[3,3] = (-sqx - sqy + sqz + sq1) * invs

  tmp1 = q.vec[1] * q.vec[2]
  tmp2 = q.vec[3] * q.q0
  rmat[2,1] = 2.0_rp * (tmp1 + tmp2) * invs
  rmat[1,2] = 2.0_rp * (tmp1 - tmp2) * invs

  tmp1 = q.vec[1] * q.vec[3]
  tmp2 = q.vec[2] * q.q0
  rmat[3,1] = 2.0_rp * (tmp1 - tmp2) * invs
  rmat[1,3] = 2.0_rp * (tmp1 + tmp2) * invs
  tmp1 = q.vec[2] * q.vec[3]
  tmp2 = q.vec[1] * q.q0
  rmat[3,2] = 2.0_rp * (tmp1 + tmp2) * invs
  rmat[2,3] = 2.0_rp * (tmp1 - tmp2) * invs
end

#---------------------------------------------------------------------------------------------------

