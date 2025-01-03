#---------------------------------------------------------------------------------------------------
# propagate_ele_geometry

"""
    propagate_ele_geometry(geometry::Type{<:EleGeometry}, floor_start::OrientationParams, 
                                                                     ele::Ele) -> OrientationParams
    propagate_ele_geometry(ele::Ele) -> OrientationParams

  Returns the floor position at the end of the element given the floor position at the beginning.
  Normally this routine is called with `floor_start` equal to ele.param[:floor_position].

### Notes:

Routine to calculate the floor coordinates without alignment shifts of an element at the downstream end
(if len_scale = 1) given the floor coordinates without alignment shifts of the preceeding element. 
That is, the coordinates are the `machine` coordinates and not the `body` coordinates.
""" propagate_ele_geometry

function propagate_ele_geometry(ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), ele.OrientationParams, ele)
end

function propagate_ele_geometry(fstart::OrientationParams, ele::Ele)
  return propagate_ele_geometry(ele_geometry(ele), fstart, ele)
end

function propagate_ele_geometry(::Type{ZERO_LENGTH}, fstart::OrientationParams, ele::Ele)
  return fstart
end

function propagate_ele_geometry(::Type{STRAIGHT}, fstart::OrientationParams, ele::Ele)
  r_floor = fstart.r + rot([0.0, 0.0, ele.L], fstart.q)
  return OrientationParams(r_floor, fstart.q)
end

function propagate_ele_geometry(::Type{CIRCULAR}, fstart::OrientationParams, ele::Ele)
  df = coord_transform(ele.L, ele.BendParams.g, ele.BendParams.tilt_ref)
  return coord_transform(fstart, df)
end

function propagate_ele_geometry(::Type{PATCH_GEOMETRY}, fstart::OrientationParams, ele::Ele)
  error("Not yet implemented!")
end

function propagate_ele_geometry(::Type{CRYSTAL_GEOMETRY}, fstart::OrientationParams, ele::Ele)
  error("Not yet implemented!")
end

#---------------------------------------------------------------------------------------------------
# coord_transform

"""
    coord_transform(ds::Number, g::Number, tilt_ref::Number = 0) -> OrientationParams

Returns the coordinate transformation from one point on the arc with radius `1/g` of a Bend to another
point that is an arc distance `ds` from the first point.

The transformation is
  r_end = r_start + rot(dr, q_start)
  q_end = q_start * dq
""" coord_transform(ds::Number, g::Number, tilt_ref::Number = 0.0)

function coord_transform(ds::Number, g::Number, tilt_ref::Number = 0.0)
  if g == 0
    return OrientationParams([0.0, 0.0, ds], Quaternion())

  else
    angle = ds/g
    r_vec = [-ds * un_sinc(0.5*angle) * sin(angle), 0.0, ds * un_sinc(0.5*angle)]

    qa = rotY(-angle)
    if tilt_ref == 0
      return OrientationParams(r_vec, qa)
    else
      qt = rotZ(-tilt_ref)
      return OrientationParams(rot(r_vec, qt), qt * qa * inv(qt))
    end
  end
end

#---------------------------------------------------------------------------------------------------
# coord_transform

"""
    coord_transform(coord0::OrientationParams, dcoord::OrientationParams) -> OrientationParams

Returns coordinate transformation of `dcoord` applied to `coord0`.
""" coord_transform(coord0::OrientationParams, dcoord::OrientationParams)

function coord_transform(coord0::OrientationParams, dcoord::OrientationParams)
  r_coord = coord0.r + rot(dcoord.r, coord0.q)
  q_coord = coord0.q * dcoord.q
  return OrientationParams(r_coord, q_coord)
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
    rot!(coord::OrientationParams, q::Quaternion) -> OrientationParams

Rotates coordinate position `coord` by `q`.
""" 
function rot!(coord::OrientationParams, q::Quaternion)
  coord.r = rot(coord.r, q)
  coord.q = q * coord.q
  return coord
end

#---------------------------------------------------------------------------------------------------
# rot

"""
    rot(coord::OrientationParams, q::Quaternion) -> OrientationParams

Rotates coordinate position `coord` by `q`.
""" 
function rot(coord::OrientationParams, q::Quaternion)
  return OrientationParams(r = rot(coord0.r, q), q = q * coord0.q)
end

