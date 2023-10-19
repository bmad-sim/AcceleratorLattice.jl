#---------------------------------------------------------------------------------------------------
"""
    propagate_ele_geometry(floor_start::FloorPositionGroup, ele::Ele)

  Returns the floor position at the end of the element given the floor position at the beginning.
  Normally this routine is called with `floor_start` equal to ele.param[:floor_position].

### Notes:

Routine to calculate the non-misaligned global (floor) coordinates of an element at the downstream end
(if len_scale = 1) given the non-misaligned global coordinates of the preceeding element. 

The coordinates are computed without misalignments. That is, the coordinates are the "laboratory" 
coordinates and not the "body" coordinates. To compute coordinates with misalignments, use
the routine ele_geometry_with_misalignments.


"""

function propagate_ele_geometry(fstart::FloorPositionGroup, ele::Ele)
  L = ele.L

  if ele_geometry(ele) == ZeroLength
    return fstart

  elseif ele_geometry(ele) == Straight
    r_floor = fstart.r_floor + rot(fstart.q_floor, [0.0, 0.0, L])
    return FloorPositionGroup(r_floor, fstart.q_floor, fstart.theta, fstart.phi, fstart.psi)

  elseif ele_geometry(ele) == Circular
    bend::BendGroup = ele.BendGroup
    (r_trans, q_trans) = ele_floor_transform(bend)
    r_floor = fstart.r_floor + rot(fstart.q_floor, r_trans)
    q_floor = rot(fstart.q_floor, q_trans)
    return FloorPositionGroup(r_floor, q_floor, floor_angles(q_floor, fstart)...)

  elseif ele_geometry(ele) == PatchGeom
    error("Not yet implemented!")

  elseif ele_geometry(ele) == GirderGeom
    error("Not yet implemented!")

  elseif ele_geometry(ele) == CrystalGeom
    error("Not yet implemented!")

  else
    throw(SwitchError(f"ele_geometry function returns an unknown LatGeometrySwitch {ele_geometry(ele)} for {ele}"))
  end
end

#---------------------------------------------------------------------------------------------------
# ele_floor_transform

"""
"""

function ele_floor_transform(bend::BendGroup)
  qa = Quat64(RotY(bend.angle))
  r_vec = [bend.rho * cos_one(bend.angle), 0.0, bend.rho * sin(bend.angle)]
  if bend.ref_tilt == 0; return (r_vec, qa); end

  qt = Quat64(RotZ(-bend.ref_tilt))
  return (rot(qt, r_vec), qt * qa * inv(qt))
end

#---------------------------------------------------------------------------------------------------
# Quat64

QuatRotation(theta::Float64, phi::Float64, psi::Float64) = Quat64(RotY(theta) * RotX(-phi) * RotZ(psi))

#---------------------------------------------------------------------------------------------------
# floor_angles

"""
    floor_angles(q::Quat64, floor0::FloorPositionGroup = FloorPositionGroup())

Function to construct the angles that define the orientation of an element
in the global "floor" coordinates from the quaternion.

Input:
   w_mat(3,3) -- Real(rp): Orientation matrix.
   floor0     -- floor_position_struct, optional: There are two solutions related by:
                   [theta, phi, psi] & [pi+theta, pi-phi, pi+psi]
                 If floor0 is present, choose the solution "nearest" the angles in floor0.


"""

function floor_angles(q::Quat64, f0::FloorPositionGroup = FloorPositionGroup())
  m = RotMatrix(q)
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


