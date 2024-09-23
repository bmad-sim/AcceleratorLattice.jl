# utilities.jl
# Utility routines that involve structures from struct.jl
# Also see core.jl

#---------------------------------------------------------------------------------------------------
# lat_sanity_check

"""
    lat_sanity_check(lat::Lat)

Does some self consistency checks on a lattice and throws an error if there is a problem.
""" lat_sanity_check

function lat_sanity_check(lat::Lat)
  for (ib, branch) in enumerate(lat.branch)
    if ib != branch.ix_branch; error(f"SanityCheck: Branch with branch index: {ib} has branch.ix_branch set to {branch.ix_branch}"); end
    if lat !== branch.lat; error(f"SanityCheck: Branch {ib} has branch.lat not pointing to parient lat."); end

    for (ie, ele) in enumerate(branch.ele)
      if ie != ele.ix_ele; error(f"SanityCheck: Ele {ele.name} in branch {ib} with"*
                                      f" element index: {ie} has ele.ix_ele set to {ele.ix_ele}"); end

      if branch !== ele.branch; error(f"SanityCheck: Ele {ele_name(ele)} has ele.branch not pointing to parient branch."); end

      if branch.type == TrackingBranch
        if !haskey(ele.pdict, :LengthGroup) error(f"Sanity check: Ele {ele_name(ele)} does not have a LengthGroup group."); end
      end
    end
  end

end

#---------------------------------------------------------------------------------------------------
# Base.isless
# Used to sort output

function Base.isless(a::Type{T1}, b::Type{T2}) where {T1 <: EleParameterGroup, T2 <: EleParameterGroup}
  return Symbol(a) < Symbol(b)
end

