#---------------------------------------------------------------------------------------------------

QuatN = QuatRotation{Number}
Quat64 = QuatRotation{Float64}

abstract type AbstractQuaternion end

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
""" AxisAngle

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
  if m == 0; error(f"RangeError: Length of axis is zero."); end
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

#---------------------------------------------------------------------------------------------------

"""
It is not assumed that the quaternion is normalized
""" RotMat

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
# quat_angles

"""
    quat_angles(q; angles0 = [0.0, 0.0, 0.0])

Returns angles `theta`, `phi`, `psi` corresponding to quaternion `q`.

 - `angles0`   `angles0` is used so that the returned angles (which are ambiguous up to factors of pi), 
are  "close" to `angles0`. This is used when `angles0` corresponds to the orientation of some 
initial quaternion  `q0` and `q` is "close" to `q0` (for example, `q` and `q0` are the quaternions
for orientations at the ends of a bend element).
""" quat_angles

function quat_angles(q; angles0 = [0.0, 0.0, 0.0])
  s00 = q.q.s * q.q.s
  s11 = q.q.v1 * q.q.v1
  s22 = q.q.v2 * q.q.v2
  s33 = q.q.v3 * q.q.v3
  s12 = q.q.v1 * q.q.v2

  w13 = 2.0 * (s13 * s20)
  w33 = s00 - s11 - s22 + s33

  # Only theta at +/- psi is well defined here so this is rather arbitrary
  if abs(w13) + abs(w33) < 1e-12
    if w23 > 0; return angles0[1], pi/2, atan(-w31, w11) - angles0[1]
    else;       return angles0[1], -pi/2, atan(w21, w11) + angles0[1]
    end
  end

  # Normal case
  theta = atan(w13, w33)
  phi = atan(w23, norm([w13 + w33]))
  psi = atan(w21, w22)

  if angles0 == [0.0, 0.0, 0.0]; return mod(theta, 2pi), phi, psi; end

  diff1 = [modulo2(theta-angles0[1], pi), modulo2(phi-angles0[2], pi), modulo2(psi-angles0[3], pi)]
  diff2 = [modulo2(pi+theta-angles0[1], pi), modulo2(pi-phi-angles0[2], pi), modulo2(pi+psi-angles0[3], pi)]
  if norm(diff1) < norm(diff2)
    return diff1 + angles0
  else
    return diff2 + angles0
  end
end

#---------------------------------------------------------------------------------------------------
