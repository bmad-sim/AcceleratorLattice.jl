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
    throw(RangeError(f"s-position ({s}) out of range [{branch.ele[1].s}], for branch ({branch.name})"))
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