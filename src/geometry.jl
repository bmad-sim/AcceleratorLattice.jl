#---------------------------------------------------------------------------------------------------
# propagate_ele_geometry

"""
    propagate_ele_geometry(floor_start::FloorPositionGroup, ele::Ele)
    propagate_ele_geometry(ele::Ele)

  Returns the floor position at the end of the element given the floor position at the beginning.
  Normally this routine is called with `floor_start` equal to ele.param[:floor_position].

### Notes:

Routine to calculate the non-misaligned global (floor) coordinates of an element at the downstream end
(if len_scale = 1) given the non-misaligned global coordinates of the preceeding element. 

The coordinates are computed without misalignments. That is, the coordinates are the "machine" 
coordinates and not the "body" coordinates. To compute coordinates with misalignments, use
the routine ele_geometry_with_misalignments.


""" propagate_ele_geometry

function propagate_ele_geometry(ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), ele.FloorPositionGroup, ele)
end

function propagate_ele_geometry(fstart::FloorPositionGroup, ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), fstart, ele)
end

function propagate_ele_geometry(::Type{ZERO_LENGTH}, fstart::FloorPositionGroup, ele::Ele)
  return fstart
end

function propagate_ele_geometry(::Type{STRAIGHT}, fstart::FloorPositionGroup, ele::Ele)
  r_floor = fstart.r + rot(fstart.q, [0.0, 0.0, ele.L])
  return FloorPositionGroup(r_floor, fstart.q, fstart.theta, fstart.phi, fstart.psi)
end

function propagate_ele_geometry(::Type{CIRCULAR}, fstart::FloorPositionGroup, ele::Ele)
  bend::BendGroup = ele.BendGroup
  (r_trans, q_trans) = ele_floor_transform(bend, ele.L)
  r_floor = fstart.r + rot(fstart.q, r_trans)
  q_floor = fstart.q * q_trans
  return FloorPositionGroup(r_floor, q_floor, floor_angles(q_floor, fstart)...)
end

function propagate_ele_geometry(::Type{PATCH_GEOMETRY}, fstart::FloorPositionGroup, ele::Ele)
  error("Not yet implemented!")
end

function propagate_ele_geometry(::Type{GIRDER_GEOMETRY}, fstart::FloorPositionGroup, ele::Ele)
  error("Not yet implemented!")
end

function propagate_ele_geometry(::Type{CRYSTAL_GEOMETRY}, fstart::FloorPositionGroup, ele::Ele)
  error("Not yet implemented!")
end

#---------------------------------------------------------------------------------------------------
# ele_floor_transform

"""
    ele_floor_transform(bend::BendGroup)

Returns the (dr, dq) transformation between the beginning of a bend and the end of the bend.

The transformation is
  r_end = r_start + rot(q_start, dr)
  q_end = q_start * dq)
""" ele_floor_transform

function ele_floor_transform(bend::BendGroup, L)
  qa = RotY(bend.angle)
  r_vec = [-L * sinc(bend.angle/(2*pi)) * sin(bend.angle), 0.0, L * sinc(bend.angle/pi)]
  if bend.ref_tilt == 0; return (r_vec, qa); end

  qt = RotZ(-bend.ref_tilt)
  return (rot(qt, r_vec), qt * qa * inv(qt))
end

#---------------------------------------------------------------------------------------------------
# QuatRotation

"""
    QuatRotation(theta::Real, phi::Real, psi::Real)

Function to return the quaternion corresponding to a rotation parameterized
by `theta`, `phi`, and `psi`.
""" QuatRotation

QuatRotation(theta::Real, phi::Real, psi::Real) = RotY(theta) * RotX(-phi) * RotZ(psi)

#---------------------------------------------------------------------------------------------------
# floor_angles

"""
    floor_angles(q::Quaternion, floor0::FloorPositionGroup = FloorPositionGroup())

Function to construct the angles that define the orientation of an element
in the global "floor" coordinates from the quaternion.

Input:
   w_mat(3,3) -- Real(rp): Orientation matrix.
   floor0     -- floor_position_struct, optional: There are two solutions related by:
                   [theta, phi, psi] & [pi+theta, pi-phi, pi+psi]
                 If floor0 is present, choose the solution "nearest" the angles in floor0.


""" floor_angles

function floor_angles(q::Quaternion, f0::FloorPositionGroup = FloorPositionGroup())
  m = quat_to_dcm(q)
  # Special case where cos(phi) is close to zero.
  if abs(m[1,3]) + abs(m[3,3]) < 1e-12
    # Only theta +/- pis is well defined here so this is rather arbitrary.
    if m[2,3] > 0
      return f0.theta, pi/2, atan(-m[3,1], m[1,1]) - f0.theta
    else
      return f0.theta, -pi/2, atan(m[3,1], m[1,1]) + f0.theta
    end

  else
    theta = atan(m[1,3], m[3,3])
    phi = atan(m[2,3], sqrt(m[1,3]^2 + m[3,3]^2))
    psi = atan(m[2,1], m[2,2])
    diff1 = (modulo2(theta-f0.theta, pi), modulo2(phi-f0.phi, pi), modulo2(psi-f0.psi, pi))
    diff2 = (modulo2(pi+theta-f0.theta, pi), modulo2(pi-phi-f0.phi, pi), modulo2(pi+psi-f0.psi, pi))
    sum(norm(diff1)) < sum(norm(diff2)) ? d = diff1 : d = diff2
    return theta+d[1], phi+d[2], psi+d[3]
  end
end


