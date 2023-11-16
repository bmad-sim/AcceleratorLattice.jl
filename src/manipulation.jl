#-----------------------------------------------------------------------------------------
# branch_insert_ele!

function branch_insert_ele!(branch::Branch, ix_ele::Int, ele::Ele)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
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
function branch_split!(branch::Branch, s_split::Real; choose_upstream::Bool = true, ix_insert::Int = -1)
  check_if_s_in_branch_range(branch, s_split)
  # return ix_split, split_done
end
