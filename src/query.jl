#---------------------------------------------------------------------------------------------------
# machine_location

"""
    machine_location(loc::BodyLocationSwitch, orientation::Int)

Given a location with respect to an element's `local` orientation,
along with the element's orientation with respect to machine coordinates, 
return the equivalent location in machine coordinates.

The reverse function is body_location.

### Input

 - `loc`          Possible values: `EntranceEnd`, `Center`, `ExitEnd`
 - `orientation`  Possible values: -1 or +1.

### Output

 - Returns: `UpstreamEnd`, `Center`, or `DownstreamEnd` (a `StreamLocationSwitch` value).
""" machine_location

function machine_location(loc::BodyLocationSwitch, orientation::Int)
  if loc == Center; return Center; end

  if loc == EntranceEnd
    orientation == 1 ? (return UpstreamEnd) : return DownstreamEnd
  elseif loc == ExitEnd
    orientation == 1 ? (return DownstreamEnd) : return UpstreamEnd
  else
    error(f"ConfusedError: Should not be here! Please report this!")
  end
end

#---------------------------------------------------------------------------------------------------
# body_location

"""
    body_location(loc::StreamLocationSwitch, orientation::Int)

Given an element location with respect to machine coordinates,
along with the element's orientation with respect to machine coordinates, 
return the equivalent location with respect to the element's `local` orientation.

The reverse function is machine_location.

### Input

 - `loc`          Possible values: `UpstreamEnd`, `Center`, or `DownstreamEnd` (a `StreamLocationSwitch` value).
 - `orientation`  Possible values: -1 or +1.

### Output

 - Returns: `EntrancEnd`, `Center`, `ExitEnd` (a `BodyLocationSwitch` value).
""" body_location

function body_location(loc::StreamLocationSwitch, orientation::Int)
  if loc == Center; return Center; end

  if loc == UpstreamEnd
    orientation == 1 ? (return EntranceEnd) : return ExitEnd
  elseif loc == DownstreamEnd
    orientation == 1 ? (return ExitEnd) : return EntranceEnd
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

Test if argument is NULL_ELE or NULL_BRANCH.
""" is_null

is_null(ele::Ele) = return (typeof(ele) == NullEle)
is_null(branch::Branch) = return (branch.ix_branch == -1)

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