#---------------------------------------------------------------------------------------------------
# propagate_ele_geometry

"""
    propagate_ele_geometry(floor_start::FloorPositionGroup, ele::Ele)
    propagate_ele_geometry(ele::Ele)

  Returns the floor position at the end of the element given the floor position at the beginning.
  Normally this routine is called with `floor_start` equal to ele.param[:floor_position].

### Notes:

Routine to calculate the floor coordinates without alignment shifts of an element at the downstream end
(if len_scale = 1) given the floor coordinates without alignment shifts of the preceeding element. 
That is, the coordinates are the `machine` coordinates and not the `body` coordinates.
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
  return FloorPositionGroup(r_floor, fstart.q)
end

function propagate_ele_geometry(::Type{CIRCULAR}, fstart::FloorPositionGroup, ele::Ele)
  df = floor_transform(ele.BendGroup, ele.L)
  return floor_transform(fstart, df)
end

function propagate_ele_geometry(::Type{PATCH_GEOMETRY}, fstart::FloorPositionGroup, ele::Ele)
  error("Not yet implemented!")
end

function propagate_ele_geometry(::Type{CRYSTAL_GEOMETRY}, fstart::FloorPositionGroup, ele::Ele)
  error("Not yet implemented!")
end

#---------------------------------------------------------------------------------------------------
# floor_transform

"""
    floor_transform(bend::BendGroup, L::Number) -> FloorPositionGroup

Returns the transformation of the coordinates from the beginning of a bend to the end of the bend.

The transformation is
  r_end = r_start + rot(q_start, dr)
  q_end = q_start * dq
""" floor_transform(bend::BendGroup, L::Number)

function floor_transform(bend::BendGroup, L)
  qa = rotY(bend.angle)
  r_vec = [-L * sinc(bend.angle/(2*pi)) * sin(bend.angle), 0.0, L * sinc(bend.angle/pi)]

  if bend.tilt_ref == 0
    return FloorPositionGroup(r_vec, qa)
  else
    qt = rotZ(-bend.tilt_ref)
    return FloorPositionGroup(rot(qt, r_vec), qt * qa * inv(qt))
  end
end

#---------------------------------------------------------------------------------------------------
# floor_transform

"""
    floor_transform(floor0::FloorPositionGroup, dfloor::FloorPositionGroup) -> FloorPositionGroup

Returns coordinate transformation of `dfloor` applied to `floor0`.
""" floor_transform(floor0::FloorPositionGroup, dfloor::FloorPositionGroup)

function floor_transform(floor0::FloorPositionGroup, dfloor::FloorPositionGroup)
  r_floor = floor0.r + rot(floor0.q, dfloor.r)
  q_floor = floor0.q * dfloor.q
  return FloorPositionGroup(r_floor, q_floor)
end

#---------------------------------------------------------------------------------------------------
# rot

"""
    rot(floor0::FloorPositionGroup, q::Quaternion) -> FloorPositionGroup

Rotates by `q` the floor position `floor0`.
""" 
function rot(floor0::FloorPositionGroup, q::Quaternion)
  return FloorPositionGroup(r = rot(q, floor0.r), q = q * floor0.q)
end

