#---------------------------------------------------------------------------------------------------
# machine_location

"""
    machine_location(loc::BodyLocationSwitch, orientation::Int) -> StreamLocationSwitch

Given a location with respect to an element's `local` orientation and the element's `orientation`,
return the equivalent location in machine coordinates.

The reverse function is body_location.

### Input

 - `loc`          Location with respect to an element's `local` orientation.
                     Possible values: `entrance_end`, `b_center`, or `exit_end`
 - `orientation`  Element orientation. Possible values: -1 or +1.

### Output

 - Returns: `upstream_end`, `center`, or `downstream_end` (a `StreamLocationSwitch` value).
""" machine_location

function machine_location(loc::BodyLocationSwitch, orientation::Int)
  if loc == b_center; return center; end

  if loc == entrance_end
    orientation == 1 ? (return upstream_end) : return downstream_end
  elseif loc == exit_end
    orientation == 1 ? (return downstream_end) : return upstream_end
  else
    error(f"loc argument values limited to `entrance_end`, `b_center`,  or `exit_end`. Not: {loc}")
  end
end

#---------------------------------------------------------------------------------------------------
# body_location

"""
    body_location(loc::StreamLocationSwitch, orientation::Int) -> BodyLocationSwitch

Given an element location with respect to machine coordinates,
along with the element's orientation with respect to machine coordinates, 
return the equivalent location with respect to the element's `local` orientation.

The reverse function is machine_location.

### Input

 - `loc`          Possible values: `upstream_end`, `b_center`, or `downstream_end` .
 - `orientation`  Possible values: -1 or +1.

### Output

 - Returns: `entranc_end`, `b_center`, `exit_end`.
""" body_location

function body_location(loc::StreamLocationSwitch, orientation::Int)
  if loc == center; return b_enter; end

  if loc == upstream_end
    orientation == 1 ? (return entrance_end) : return exit_end
  elseif loc == downstream_end
    orientation == 1 ? (return exit_end) : return entrance_end
  else
    error(f"ConfusedError: Should not be here! Please report this!")
  end
end

#---------------------------------------------------------------------------------------------------
# Element traits

"""
    thick_multipole_ele(ele::Ele)

Identifies "thick multipole" elements. Returns a Bool.
Thick multipole elements are:

    Drift, 
    Quadrupole, 
    Sextupole, 
    Octupole

""" thick_multipole_ele

function thick_multipole_ele(ele::Ele)
  ele <: Union{Drift, Quadrupole, Sextupole, Octupole} ? (return true) : (return false)
end

"Geometry type. Returns a EleGeometrySwitch"
function ele_geometry(ele::Ele)
  if ele isa Bend; return Circular; end
  if ele isa Patch; return PatchLike; end
  if typeof(ele) <: Union{Marker, Mask, Multipole}; return ZeroLength; end
  if ele isa Girder; return GirderLike; end
  return Straight
end

#---------------------------------------------------------------------------------------------------
# is_null(ele), is_null(branch)

"""
    is_null(ele::Ele)
    is_null(branch::Branch

Test if argument is either of the NULL_ELE or NULL_BRANCH constants.
""" is_null

is_null(ele::Ele) = return (ele.name == "NULL_ELE")
is_null(branch::Branch) = return (branch.name == "NULL_BRANCH")

#---------------------------------------------------------------------------------------------------
# s_inbounds

"""
Returns the equivalent inbounds s-position in the range [branch.ele[1].s, branch.ele[end].s]
if the branch has a closed geometry. Otherwise returns s.
This is useful since in closed geometries 
""" s_inbounds

function s_inbounds(branch::Branch, s::Real)
end

#---------------------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::Branch, s::Real)
  if s < branch.ele[1].s || s > branch.ele[end].s
    error(f"RangeError: s-position ({s}) out of range [{branch.ele[1].s}], for branch ({branch.name})")
  end
end

#---------------------------------------------------------------------------------------------------
# matches_branch

"""
    matches_branch(name::AbstractString, branch::Branch)

Returns `true`/`false` if `name` matches/does not match `branch`.
A match can match branch.name or the branch index.
A blank name matches all branches.
Bmad standard wildcard characters "*" and "%" can be used.
""" matches_branch

function matches_branch(name::AbstractString, branch::Branch)
  if name == ""; return true; end

  ix = integer(name, 0)
  if ix > 0
    return ix == branch.ix_branch
  else
    return str_match(name, branch.name)
  end
end

#---------------------------------------------------------------------------------------------------
# min_ele_length

"""
    min_ele_length(lat::Lat)

For elements that have a non-zero length: minimum element length that is "significant".
This is used by, for example, the `split!` function which will not create "runt" elements
whose length is below min_ele_length. The returned value is `2 * lat.LatticeGlobal.significant_length`
""" min_ele_length

min_ele_length(lat::Lat) = 2 * lat.LatticeGlobal.significant_length