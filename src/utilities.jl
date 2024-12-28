# utilities.jl
# Utility routines that involve structures from struct.jl
# Also see core.jl

#---------------------------------------------------------------------------------------------------
# lat_sanity_check

"""
    lat_sanity_check(lat::Lattice)

Does some self consistency checks on a lattice and throws an error if there is a problem.
""" lat_sanity_check

function lat_sanity_check(lat::Lattice)
  for (ib, branch) in enumerate(lat.branch)
    if ib != branch.ix_branch; error("SanityCheck: Branch with branch index: $ib has branch.ix_branch set to $(branch.ix_branch)"); end
    if lat !== branch.lat; error("SanityCheck: Branch $ib has branch.lat not pointing to parient lat."); end

    for (ie, ele) in enumerate(branch.ele)
      if ie != ele.ix_ele; error("SanityCheck: Ele $(ele.name) in branch $ib with"*
                                      " element index: $ie has ele.ix_ele set to $(ele.ix_ele)"); end

      if branch !== ele.branch; error("SanityCheck: Ele $(ele_name(ele)) has ele.branch not pointing to parient branch."); end

      if branch.type == TrackingBranch
        if !haskey(ele.pdict, :LengthGroup) error("Sanity check: Ele $(ele_name(ele)) does not have a LengthGroup group."); end
      end
    end
  end

end

#---------------------------------------------------------------------------------------------------
# Base.isless

"""
    Base.isless(a::Type{T1}, b::Type{T2}) where {T1 <: EleParameterGroup, T2 <: EleParameterGroup} -> Bool
    Base.isless(x::Type{T}, y::Type{U}) where {T <: Ele, U <: Ele} = isless(string(x), string(y)) -> Bool

Used to sort output alphabetically by name.
""" Base.isless

function Base.isless(a::Type{T1}, b::Type{T2}) where {T1 <: EleParameterGroup, T2 <: EleParameterGroup}
  return Symbol(a) < Symbol(b)
end

Base.isless(x::Type{T}, y::Type{U}) where {T <: Ele, U <: Ele} = isless(string(x), string(y))

#---------------------------------------------------------------------------------------------------
# Base.sort(vec_ele::Vector{T}) where T <: Ele

"""
  Base.sort(vec_ele::Vector{T}) where T <: Ele -> Vector{T}

Sort vector of elements in increasing s-position. If more than one branch is involved, sort
is done branch-by-branch. Super or multipass lord elements are sorted with the branch they
are associated with. If a multipass lord is associated with multiple branches, it is placed
among the elements of the branch of its first slave.
""" Base.sort(vec_ele::Vector{T}) where T <: Ele

function Base.sort(vec_ele::Vector{T}) where T <: Ele
  lat = lattice(vec_ele[1])
  bv = Vector(undef, length(lat.branch))  # Vector of element vectors one for each branch

  # sort eles in different branches

  for ele in vec_ele
    if ele.lord_status == Lord.SUPER || ele.lord_status == Lord.MULTIPASS
      sort_ele = ele.slaves[1]
      if sort_ele.lord_status == Lord.SUPER; sort_ele = ele.slaves[1]; end
    else
      sort_ele = ele
    end

    ix = sort_ele.branch.ix_branch
    if !isassigned(bv, ix)
      bv[ix] = Vector{@NamedTuple{ele::T, s::Float64}}([(ele, sort_ele.s)])
      continue
    end

    this_b = bv[ix]
    for ie in range(length(this_b), 0, step = -1)
      if ie == 0 || this_b[ie].s < sort_ele.s
        insert!(this_b, ie+1, (ele, sort_ele.s))
        break
      end
    end
  end

  # Combine branches and return

  ie = 0
  vec_out = Vector{T}(undef, length(vec_ele))
  for ib in range(1, length(bv))
    if !isassigned(bv, ib); continue; end
    for ee in bv[ib]
      ie += 1
      vec_out[ie] = ee.ele
    end
  end

  return vec_out
end
