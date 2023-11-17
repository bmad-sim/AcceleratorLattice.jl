#-----------------------------------------------------------------------------------------
# branch_insert_ele!

function branch_insert_ele!(branch::Branch, ix_ele::Int, ele::Ele)
  insert!(branch, ix_ele, ele)
  branch_bookkeeper!(branch)
end

#-----------------------------------------------------------------------------------------
# branch_split!

"""
    branch_split!(branch::Branch, s_split::Real; choose_upstream::Bool = true, ele_near::Ele = null_ele)

Routine to split an lattice element of a branch into two to create a branch that has an element boundary at the point s = `s_split`. 
This routine will not split the lattice if the split would create a "runt" element with length less 
than 3*`LatticeGlobal.significant_length`.

`branch_split!` will redo the appropriate bookkeeping for lords and slaves and
a super-lord element will be created if needed. 

### Input
- `branch`            -- Lattice branch
- `s_split`           -- Position at which branch is to be split.
- `add_suffix`        -- logical, optional: If True (default) add '!1' and '!2" suffixes
                           to the split elements.
- `choose_upstream`   -- logical, optional: If no splitting of an element is needed, that is, 
  `s_split` is at an element boundary, there can be multiple possible split points if there exist zero 
  length elements at the split point. If `choose_upsteam` = true, the split will be chosen to be 
  at the maximal upstream location. If `choose_upstream` = false the split will be chosen to be the 
  downstream location. If `s_plit` is not at an element boundary, the setting of `choose_upstream` is immaterial.
  If `ele_near` is present, `choose_upstream` is ignored.
- `ele_near`          -- Element near the point to be split. ele_neam is useful in the case where
  there is a patch with a negative length which can create an ambiguity as to where to do the split
  In this case ele_neam will remove the ambiguity. Also useful to ensure where to split if there
  are elements with zero length nearby. Ignored equal to `null_ele`.

### Output tuple:
- `ele_split`     -- Element just before the s = `s_split` point.
- `split_done`    -- true if lat was split, false otherwise.
""" branch_split!

function branch_split!(branch::Branch, s_split::Real; choose_upstream::Bool = true, ix_insert::Int = -1)
  check_if_s_in_branch_range(branch, s_split)
  # return ix_split, split_done
  ele0 = ele_at_s(branch, s_split, choose_upstream = choose_upstream, ele_neam = ele_neam)
end
