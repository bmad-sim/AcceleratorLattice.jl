#-----------------------------------------------------------------------------------------
# latele_at_s

"""
    latele_at_s(branch::LatBranch, s::Real; choose_max::Bool = False, ele_near = nothing)

Returns lattice element that overlaps a given longitudinal s-position. Also returned
is the location (upstream, downstream, or inside) of the s-position with respect to the returned 

"""
function latele_at_s(branch::LatBranch, s::Real; choose_max::Bool = False, ele_near = nothing)
  check_if_s_in_branch_range(branch, s)

  # If ele_near set

  if ele_near == nothing
    n1 = 1
    n3 = branch.ele[end].param[:ix_ele]

    while true
      if n3 == n1 + 1; break; end
      n2 = (n1 + n3) / 2
      s < branch.ele[n2].param[:s] || (choose_max && s == branch.ele[n2].param[:s]) ? n3 = n2 : n1 = n2
    end

    # Solution is n1 except in one case.
    if choose_max && s == branch.ele[n3].param[:s]; n1 = n1+1; end
    

  # If ix_near not used

  else


  end

  # return ele
end

#-----------------------------------------------------------------------------------------
# branch_split!

"""
Routine to split an lattice element of a branch into two to create a branch that has an element boundary at the point s = s_split. 
This routine will not split the lattice if the split would create a "runt" element with length less 
than 5*bmad_com%significant_length.

branch_split! will redo the appropriate bookkeeping for lords and slaves.
A super_lord element will be created if needed. 
"""
function branch_split!(branch::LatBranch, s_split::Real; choose_max::Bool = False, ix_insert::Int = -1)
  check_if_s_in_branch_range(branch, s_split)
  # return ix_split, split_done
end

#-----------------------------------------------------------------------------------------
# s_inbounds

"""
Returns the equivalent inbounds s-position in the range [branch.ele[1].param(:s), branch.ele[end].param(:s)]
if the branch has a closed geometry. Otherwise returns s.
This is useful since in closed geometries 
"""
function s_inbounds(branch::LatBranch, s::Real)
end

#-----------------------------------------------------------------------------------------
# check_if_s_in_branch_range

function check_if_s_in_branch_range(branch::LatBranch, s::Real)
  if s_split < branch.ele[1].param[:s] || s_split > branch.ele[end].param[:s]
    throw(RangeError(f"s_split ({string(s_split)}) position out of range [{branch.ele[1].param[:s]}], for branch ({branch.name})"))
  end
end

#-----------------------------------------------------------------------------------------
# branch_insert_latele!

function branch_insert_latele!(branch::LatBranch, ix_ele::Int, ele::LatEle)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
end

#-----------------------------------------------------------------------------------------
# branch_bookkeeper!

function branch_bookkeeper!(branch::LatBranch)
  if branch.name == "lord"; return; end
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.param[:ix_ele] = ix_ele
    if ix_ele > 1; ele.param[:s] = branch.ele[ix_ele-1].param[:s] + get(branch.ele[ix_ele-1].param, :len, 0); end
  end
end

#-----------------------------------------------------------------------------------------
# lat_bookkeeper!


function lat_bookkeeper!(lat::Lat)
  for branch in lat.branch
    branch_bookkeeper!(branch)
  end
end