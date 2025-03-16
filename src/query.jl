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
  if ele.class in [BeginningEle, Fiducial, Fork, 
                            Marker, Match, NullEle, Taylor]; return ZERO_LENGTH; end
  return STRAIGHT
end

#---------------------------------------------------------------------------------------------------
# is_null(ele), is_null(branch), is_null(species

"""
    is_null(ele::Ele)
    is_null(branch::Branch
    is_null(species::Species)

Test if argument is either of the `NULL_ELE`, `NULL_BRANCH`, or null species. constants.
""" is_null

is_null(ele::Ele) = (ele.name == "NULL_ELE")
is_null(branch::Branch) = (branch.name == "NULL_BRANCH")
is_null(species::Species) = (species == Species())

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
    slave_index(slave::Ele, lord::Ele = NULL_ELE) -> Int

For a super or multipass slave element, returns the index of the slave in the `lord.slaves[]`.
Throws an error for all other elements.

Note: For a super or multipass slave element that is not a `UnionEle`, there is only one lord
so in this case the lord does not have to be present in the argument list.
""" slave_index

function slave_index(slave::Ele, lord::Ele = NULL_ELE) 
  if slave.slave_status == Slave.SUPER
    if slave.class == UnionEle && length(slave.super_lords) > 1
      lord === NULL_ELE && error("Need to specify lord element for UnionEle slave $(ele_name(slave))")
      for ix in 1:length(lord.slaves)
        if lord.slaves[ix].ix_ele == slave.ix_ele; return ix; end
      end
    end

    lord != NULL_ELE && !(lord === slave.super_lords[1]) && 
              error("Element: $(ele_name(lord)) is not a super lord to $(ele_name(slave))")
    lord = slave.super_lords[1]
    for ix in 1:length(lord.slaves)
      if lord.slaves[ix].ix_ele == slave.ix_ele; return ix; end
    end

  elseif slave.slave_status == Slave.MULTIPASS
    lord != NULL_ELE && lord && !(lord === slave.multipass_lord) && 
            error("Element: $(ele_name(lord)) is not a multipass lord to $(ele_name(slave))")
    lord = slave.multipass_lord
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
# multipass_lord

"""
    multipass_lord(ele::Ele) -> Union{Vector{Ele}, Nothing}

Returns the multipass lord of element `ele`. 
If no super lords exist for `ele`, `nothing` is returned.
""" multipass_lord

function multipass_lord(ele::Ele)
  if !haskey(ele.pdict, :multipass_lord) return nothing; end
  return ele.pdict[:multipass_lord]
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
