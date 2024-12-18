#---------------------------------------------------------------------------------------------------
# AxisAngle

"""
    struct AxisAngle

The `axis` vector is not necessarily normalized.
""" AxisAngle

struct AxisAngle
  angle::Number
  axis::Vector{Number}
end

#---------------------------------------------------------------------------------------------------
# QuaternionX, QuaternionY, QuaternionZ

"""
    QuaternionX(angle::Number) -> Quaternion
    QuaternionY(angle::Number) -> Quaternion
    QuaternionZ(angle::Number) -> Quaternion

Quaternion constructors representing rotations around x, y, and z axes.
""" QuaternionX, QuaternionY, QuaternionZ

QuaternionX(angle::Number) = Quaternion(cos(angle/2), [sin(angle/2), 0, 0])
QuaternionY(angle::Number) = Quaternion(cos(angle/2), [0, sin(angle/2), 0])
QuaternionZ(angle::Number) = Quaternion(cos(angle/2), [0, 0, sin(angle/2)])

#---------------------------------------------------------------------------------------------------
# Quaternion

"""
    Quaternion(aa::AxisAngle) 
    Quaternion(m::Matrix{T}) 
    Quaternion(x_rot::Real, y_rot::Real, tilt::Real)
    Quaternion(qv::Vector)  # 4-vector

Quaternion constructors. 
""" Quaternion

Quaternion(qv::Vector) = Quaternion(qv[1], qv[2:end])

Quaternion(x_rot::Real, y_rot::Real, tilt::Real) = QuaternionY(y_rot) * QuaternionX(x_rot) * QuaternionZ(tilt)

function Quaternion(aa::AxisAngle) 
  if aa.angle == 0; return UNIT_QUAT; end
  m = mag(aa.axis)
  if m == 0; error("RangeError: Length of axis is zero."); end
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

const UNIT_QUAT = Quaternion(1.0, [0.0, 0.0, 0.0])

#---------------------------------------------------------------------------------------------------
# rot

"""
    rot(q::Quaternion, v::Vector{T}) where {T} -> Vector{T}

Rotation of a 3-vector `v` by a quaternion `q`.
""" rot

function rot(q::Quaternion, v::Vector{T}) where {T}
  vv = q * v / q
  return [vv.q1, vv.q2, vv.q3]
end

#---------------------------------------------------------------------------------------------------
# rot_angles

"""
    rot_angles(q::Quaternion; angles0 = [0.0, 0.0, 0.0]) -> theta, phi, psi

Return the  `theta`, `phi`, and `psi` rotation angles corresponding to the quaternion `q`.
""" rot_angles

function rot_angles(q::Quaternion{T}; angles0 = [0.0, 0.0, 0.0]) where {T}
  m = quat_to_dcm(q)  # The dcm is the inverse (transpose) of the corresponding rotation matrix

  # Special case where cos(phi) is close to zero.
  # Only theta at +/- psi is well defined here so this is rather arbitrary.
  if abs(m[3,1]) + abs(m[3,3]) < 1e-14
    if m[3,2] > 0; return angles0[1],  pi/2, atan(-m[1,3], m[1,1]) - angles0[1]
    else;          return angles0[1], -pi/2, atan( m[1,3], m[1,1]) + angles0[1]
    end
  end

  theta = atan(m[3,1], m[3,3])
  phi = atan(m[3,2], norm(m[3,1]^2, m[3,3]^2))
  psi = atan(m[1,2], m[2,2])

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

"""
    rot_mat(q::Quaternion{T}) where {T}

Return the rotation matrix corresponding to quaternion `q`.
It is not assumed that the quaternion is normalized.
""" rot_mat

function rot_mat(q::Quaternion{T}) where {T}
  sq1 = q.q0 * q.q0
  sqx = q.q1 * q.q1
  sqy = q.q2 * q.q2
  sqz = q.q3 * q.q3
  rmat = Matrix{Float64}(undef,3,3)

  # invs (inverse square length) is only required if quaternion is not already normalised                                       

  invs = 1 / (sqx + sqy + sqz + sq1)
  rmat[1,1] = ( sqx - sqy - sqz + sq1) * invs   # since sq1 + sqx + sqy + sqz =1/invs * invs                                     
  rmat[2,2] = (-sqx + sqy - sqz + sq1) * invs
  rmat[3,3] = (-sqx - sqy + sqz + sq1) * invs

  tmp1 = q.q1 * q.q2
  tmp2 = q.q3 * q.q0
  rmat[2,1] = 2 * (tmp1 + tmp2) * invs
  rmat[1,2] = 2 * (tmp1 - tmp2) * invs

  tmp1 = q.q1 * q.q3
  tmp2 = q.q2 * q.q0
  rmat[3,1] = 2 * (tmp1 - tmp2) * invs
  rmat[1,3] = 2 * (tmp1 + tmp2) * invs
  tmp1 = q.q2 * q.q3
  tmp2 = q.q1 * q.q0
  rmat[3,2] = 2 * (tmp1 + tmp2) * invs
  rmat[2,3] = 2 * (tmp1 - tmp2) * invs

  return rmat
end

#---------------------------------------------------------------------------------------------------
# Base.show(io::IO, q::ReferenceFrameRotations.Quaternion)
# Standard show for a quaternion has a "Quaternion{Float64}:" prefix added on which is annoying.

function qstr(x::Number)
  if x < 0
    return "- $(abs(x))"
  else
    return "+ $x"
  end
end

function Base.show(io::IO, q::ReferenceFrameRotations.Quaternion{T})  where T <: Number 
  print(io, "$(q.q0) $(qstr(q.q1))⋅i $(qstr(q.q2))⋅j $(qstr(q.q3))⋅k")
end 

#---------------------------------------------------------------------------------------------------
