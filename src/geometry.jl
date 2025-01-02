#---------------------------------------------------------------------------------------------------
# propagate_ele_geometry

"""
    propagate_ele_geometry(geometry::Type{<:EleGeometry}, floor_start::OrientationGroup, 
                                                                     ele::Ele) -> OrientationGroup
    propagate_ele_geometry(ele::Ele) -> OrientationGroup

  Returns the floor position at the end of the element given the floor position at the beginning.
  Normally this routine is called with `floor_start` equal to ele.param[:floor_position].

### Notes:

Routine to calculate the floor coordinates without alignment shifts of an element at the downstream end
(if len_scale = 1) given the floor coordinates without alignment shifts of the preceeding element. 
That is, the coordinates are the `machine` coordinates and not the `body` coordinates.
""" propagate_ele_geometry

function propagate_ele_geometry(ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), ele.OrientationGroup, ele)
end

function propagate_ele_geometry(fstart::OrientationGroup, ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), fstart, ele)
end

function propagate_ele_geometry(::Type{ZERO_LENGTH}, fstart::OrientationGroup, ele::Ele)
  return fstart
end

function propagate_ele_geometry(::Type{STRAIGHT}, fstart::OrientationGroup, ele::Ele)
  r_floor = fstart.r + rot([0.0, 0.0, ele.L], fstart.q)
  return OrientationGroup(r_floor, fstart.q)
end

function propagate_ele_geometry(::Type{CIRCULAR}, fstart::OrientationGroup, ele::Ele)
  df = coord_transform(ele.L, ele.BendGroup.g, ele.BendGroup.tilt_ref)
  return coord_transform(fstart, df)
end

function propagate_ele_geometry(::Type{PATCH_GEOMETRY}, fstart::OrientationGroup, ele::Ele)
  error("Not yet implemented!")
end

function propagate_ele_geometry(::Type{CRYSTAL_GEOMETRY}, fstart::OrientationGroup, ele::Ele)
  error("Not yet implemented!")
end

#---------------------------------------------------------------------------------------------------
# coord_transform

"""
    coord_transform(ds::Number, g::Number, tilt_ref::Number = 0) -> OrientationGroup

Returns the coordinate transformation from one point on the arc with radius `1/g` of a Bend to another
point that is an arc distance `ds` from the first point.

The transformation is
  r_end = r_start + rot(dr, q_start)
  q_end = q_start * dq
""" coord_transform(ds::Number, g::Number, tilt_ref::Number = 0.0)

function coord_transform(ds::Number, g::Number, tilt_ref::Number = 0.0)
  if g == 0
    return OrientationGroup([0.0, 0.0, ds], Quaternion())

  else
    angle = ds/g
    r_vec = [-ds * sinc(angle/(2*pi)) * sin(angle), 0.0, ds * sinc(angle/(2*pi))]

    qa = rotY(-angle)
    if tilt_ref == 0
      return OrientationGroup(r_vec, qa)
    else
      qt = rotZ(-tilt_ref)
      return OrientationGroup(rot(r_vec, qt), qt * qa * inv(qt))
    end
  end
end

#---------------------------------------------------------------------------------------------------
# coord_transform

"""
    coord_transform(coord0::OrientationGroup, dcoord::OrientationGroup) -> OrientationGroup

Returns coordinate transformation of `dcoord` applied to `coord0`.
""" coord_transform(coord0::OrientationGroup, dcoord::OrientationGroup)

function coord_transform(coord0::OrientationGroup, dcoord::OrientationGroup)
  r_coord = coord0.r + rot(dcoord.r, coord0.q)
  q_coord = coord0.q * dcoord.q
  return OrientationGroup(r_coord, q_coord)
end

#---------------------------------------------------------------------------------------------------
# bend_quaternion

"""
    bend_quaternion(angle::Number, tilt_ref::Number) -> Quaternion

Quaternion representing the coordinate rotation for a bend through an angle `angle` with
a `tilt_ref` reference tilt.
""" bend_quaternion

function bend_quaternion(angle::Number, tilt_ref::Number)
  if tilt_ref == 0
    return rotY(-angle)
  else
    qt = rotZ(-tilt_ref)
    return qt * rotY(-angle) * inv(qt)
  end
end

#---------------------------------------------------------------------------------------------------
# rot!

"""
    rot!(coord::OrientationGroup, q::Quaternion) -> OrientationGroup

Rotates coordinate position `coord` by `q`.
""" 
function rot!(coord::OrientationGroup, q::Quaternion)
  coord.r = rot(coord.r, q)
  coord.q = q * coord.q
  return coord
end

#---------------------------------------------------------------------------------------------------
# rot

"""
    rot(coord::OrientationGroup, q::Quaternion) -> OrientationGroup

Rotates coordinate position `coord` by `q`.
""" 
function rot(coord::OrientationGroup, q::Quaternion)
  return OrientationGroup(r = rot(coord0.r, q), q = q * coord0.q)
end

