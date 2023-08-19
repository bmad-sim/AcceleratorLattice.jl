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
  len = ele[:len]

  if ele_geometry(ele) == ZeroLength
    return fstart

  elseif ele_geometry(ele) == Straight
    r = fstart.r + rot(fstart.q, [0.0, 0.0, len])
    return FloorPositionGroup(r, fstart.q, fstart.theta, fstart.phi, fstart,psi)

  elseif ele_geometry(ele) == Circular
    bend::BendGroup = get_group(BendGroup, ele)
    (r_trans, q_trans) = ele_floor_transform(bend)
    r = fstart.r + rot(fstart.q, r_trans)
    q = rot(fstart.q, q_trans)
    (theta, phi, psi) = floor_angles(q, fstart)

  elseif ele_geometry(ele) == PatchGeom
    throw("Not yet implemented!")

  elseif ele_geometry(ele) == GirderGeom
    throw("Not yet implemented!")

  elseif ele_geometry(ele) == CrystalGeom
    throw("Not yet implemented!")

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