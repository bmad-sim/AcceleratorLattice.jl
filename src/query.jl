#---------------------------------------------------------------------------------------------------
# lat_sanity_check

"""
    lat_sanity_check(lat::Lat)

Does some self consistency checks and throws an error if there is a problem.
""" lat_sanity_check

function lat_sanity_check(lat::Lat)
  for (ib, branch) in enumerate(lat.branch)
    if ib != branch.ix_branch; error(f"SanityCheck: Branch with branch index: {ib} has branch.ix_branch set to {branch.ix_branch}"); end
    if lat !== branch.lat; error(f"SanityCheck: Branch {ib} has branch.lat not pointing to parient lat."); end

    for (ie, ele) in enumerate(branch.ele)
      if ie != ele.ix_ele; error(f"SanityCheck: Ele {ele.name} in branch {ib} with"*
                                      f" element index: {ie} has ele.ix_ele set to {ele.ix_ele}"); end
      if branch !== ele.branch; error(f"SanityCheck: Ele {ele_name(ele)} has ele.branch not pointing to parient branch."); end
    end
  end

end

#---------------------------------------------------------------------------------------------------
# s_inbounds

"""
Returns the equivalent inbounds s-position in the range [branch.ele[1].s, branch.ele[end].s]
if the branch has a closed geometry. Otherwise returns s.
This is useful since in closed geometries 
"""
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
Returns `true`/`false` if `name` matches/does not match `branch`.
A match can match branch.name or the branch index.
A blank name matches all branches.
Bmad standard wildcard characters "*" and "%" can be used.
"""
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
"""

min_ele_length(lat::Lat) = 2 * lat.LatticeGlobal.significant_length