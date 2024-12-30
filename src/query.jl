#---------------------------------------------------------------------------------------------------
# machine_location

"""
    machine_location(loc::BodyLoc.T, orientation::Int)::Loc.T

Given a location with respect to an element's `local` orientation and the element's `orientation`,
return the equivalent location in machine coordinates.

The reverse function is body_location.

### Input

 - `loc`          Location with respect to an element's `local` orientation.
                     Possible values: `BodyLoc.ENTRANCE_END`, `BodyLoc.CENTER`, or `BodyLoc.EXIT_END`
 - `orientation`  Element orientation. Possible values: -1 or +1.

### Output

 - Returns: `Loc.UPSTREAM_END`, `Loc.CENTER`, or `Loc.DOWNSTREAM_END` (a `Loc.T` value).
""" machine_location

function machine_location(loc::BodyLoc.T, orientation::Int)::Loc.T
  if loc == BodyLoc.CENTER; return Loc.CENTER; end

  if loc == BodyLoc.ENTRANCE_END
    orientation == 1 ? (return Loc.UPSTREAM_END) : return Loc.DOWNSTREAM_END
  elseif loc == BodyLoc.EXIT_END
    orientation == 1 ? (return Loc.DOWNSTREAM_END) : return Loc.UPSTREAM_END
  else
    error("loc argument values limited to `BodyLoc.ENTRANCE_END`, `BodyLoc.CENTER`,  or `BodyLoc.EXIT_END`. Not: $loc")
  end
end

#---------------------------------------------------------------------------------------------------
# body_location

"""
    body_location(loc::Loc.T, orientation::Int)::BodyLoc.T

Given an element location with respect to machine coordinates,
along with the element's orientation with respect to machine coordinates, 
return the equivalent location with respect to the element's `local` orientation.

The reverse function is machine_location.

### Input

 - `loc`          Possible values: `Loc.UPSTREAM_END`, `Loc.CENTER`, or `Loc.DOWNSTREAM_END` .
 - `orientation`  Possible values: -1 or +1.

### Output

 - Returns: `BodyLoc.entrance_end`, `Loc.CENTER`, `BodyLoc.EXIT_END`.
""" body_location

function body_location(loc::Loc.T, orientation::Int)
  if loc == Loc.CENTER; return b_enter; end

  if loc == Loc.UPSTREAM_END
    orientation == 1 ? (return BodyLoc.ENTRANCE_END) : return BodyLoc.EXIT_END
  elseif loc == Loc.DOWNSTREAM_END
    orientation == 1 ? (return BodyLoc.EXIT_END) : return BodyLoc.ENTRANCE_END
  else
    error("ConfusedError: Should not be here! Please report this!")
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
  if ele isa Bend; return CIRCULAR; end
  if ele isa Patch; return PATCH_GEOMETRY; end
  if typeof(ele) in [BeginningEle, Fiducial, Fork, 
                            Marker, Match, NullEle, Taylor]; return ZERO_LENGTH; end
  return STRAIGHT
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
if the branch has a `BranchGeom.CLOSED` geometry. Otherwise returns s.
This is useful since in `Branch.Geom.CLOSED` geometries.
""" s_inbounds

function s_inbounds(branch::Branch, s::Real)
end

#---------------------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::Branch, s::Real)
  if s < branch.ele[1].s || s > branch.ele[end].s_downstream
    error("RangeError: s-position ($s) out of range [$(branch.ele[1].s), $(branch.ele[end].s_downstream)], for branch ($(branch.name))")
  end
end

#---------------------------------------------------------------------------------------------------
# matches_branch

"""
    matches_branch(name::AbstractString, branch::Branch)

Tests if `name` matches/does not match `branch`.
A match can match branch.name or the branch index.
A blank name matches all branches.
Bmad standard wildcard characters `"*"` and `"%"` can be used.
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
# slave_index

"""
    slave_index(slave::Ele) -> Int

For a super or multipass slave element, returns the index of the slave in the `lord.slaves[]`
array. Exception: A `UnionEle` super slave has multiple lords. In this case, zero is returned.
""" slave_index

function slave_index(slave::Ele) 
  if slave.slave_status == Slave.SUPER
    if typeof(slave) == UnionEle; return 0; end
    lord = slave.super_lords[1]
    for ix in 1:length(lord.slaves)
      if lord.slaves[ix].ix_ele == slave.ix_ele; return ix; end
    end

  elseif slave.slave_status == Slave.MULTIPASS
    lord = slave.multipass_lord[1]
    for ix in 1:length(lord.slaves)
      if lord.slaves[ix].ix_ele == slave.ix_ele; return ix; end
    end

  else
    error("Element is not a super nor a multipass slave.")
  end

  error("Bookkeeping error! Please contact an AcceleratorLattice maintainer!")
end

#---------------------------------------------------------------------------------------------------
# girder

"""
    girder(ele::Ele) -> Union{Ele, Nothing}

Returns the `Girder' supporting element `ele` or `nothing`.
""" girder

function girder(ele::Ele)
  if !haskey(ele.pdict, :girder) return nothing; end
  return ele.pdict[:girder]
end

#---------------------------------------------------------------------------------------------------
# min_ele_length

"""
    min_ele_length(lat::Lattice)

For elements that have a non-zero length: minimum element length that is "significant".
This is used by, for example, the `split!` function which will not create "runt" elements
whose length is below min_ele_length. The returned value is `2 * lat.LatticeGlobal.significant_length`
""" min_ele_length

min_ele_length(lat::Lattice) = 2 * lat.LatticeGlobal.significant_length

#---------------------------------------------------------------------------------------------------
# it_ismutable & it_isimmutable

"""
    function it_ismutable(x)

Work around for the problem that ismutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_ismutable

function it_ismutable(x)
  if typeof(x) <: AbstractString; return false; end
  return ismutable(x)
end

"""
    function it_isimmutable(x)

Work around for the problem that isimmutable returns True for strings.
See: https://github.com/JuliaLang/julia/issues/30210
""" it_isimmutable

function it_isimmutable(x)
  if typeof(x) <: AbstractString; return true; end
  return isimmutable(x)
end
