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

function propagate_ele_geometry(floor_start::FloorPositionGroup, ele::Ele)
  if ele_geometry(ele) == ZeroLength
    return floor_start

  elseif ele_geometry(ele) == Straight


  elseif ele_geometry(ele) == Circular


  elseif ele_geometry(ele) == PatchLike

  elseif ele_geometry(ele) == GirderLike

  else
    throw(SwitchError(f"ele_geometry function returns an unknown LatGeometrySwitch {ele_geometry(ele)} for {ele}"))
  end
end