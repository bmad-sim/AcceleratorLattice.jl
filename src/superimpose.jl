#---------------------------------------------------------------------------------------------------
# superimpose!

"""
    function superimpose!(super_ele::Ele, ref_ele::Vector{Ele}; ele_origin::EleRefLocationSwitch = Center, 
                      offset::Real = 0, ref_origin::EleRefLocationSwitch = Center, wrap::Bool = true)
    function superimpose!(super_ele::Ele, ref_ele::Ele; ele_origin::EleRefLocationSwitch = Center, 
           offset::Real = 0, ref_origin::EleRefLocationSwitch = Center, wrap::Bool = true)

- `wrap`   Only relavent if the superimposed element has an end that extends beyond the 
starting or ending edge of the branch. If true (default), wrap the element around the
branch so that the element's upstream edge before the branch end edge and the element's 
downstream edge after the branch start edge. If `wrap` = false, extend the lattice to accommodate.

superposition for zero length elements with zero offset happens at the upstream end of ref_ele.

""" superimpose!

function superimpose!(super_ele::Ele, ref_ele::Vector{Ele}; ele_origin::EleRefLocationSwitch = Center, 
                      offset::Real = 0, ref_origin::EleRefLocationSwitch = Center, wrap::Bool = true)
  for ref in ref_ele
    superimpose!(super_ele, ref, ele_origin = ele_origin, offset = offset, ref_origin = ref_origin, wrap = wrap)  
  end
end

#-----------

function superimpose!(super_ele::Ele, ref_ele::Ele; ele_origin::EleRefLocationSwitch = Center, 
           offset::Real = 0, ref_origin::EleRefLocationSwitch = Center, wrap::Bool = true)

  # Get insertion branch
  branch = ref_ele.branch
  if branch.type == LordBranch 
    branch = ref_ele.slave[1].branch
    ref_ix_ele = ref_ele.slave[1].ix_ele
  else
    ref_ix_ele = ref_ele.ix_ele
  end

  L_super = get_property(super_ele, :L, 0.0)

  # Insertion of zero length element with zero offset at edge of an element.
  if L_super == 0 && offset == 0 
    if ref_origin == EntranceEnd || (ref_origin == Center && ref_ele.L == 0)
      ix_insert = max(ref_ix_ele, 2)
      insert_ele!(branch, super_ele, ix_insert)
      return
    elseif ref_origin == ExitEnd 
      ix_insert = min(ref_ix_ele+1, length(ref_ele.branch.ele))
      insert_ele!(branch, super_ele, ix_insert)
      return
    end
  end

  # Superposition position ends
  if branch.type == LordBranch
    if ref_origin == EntranceEnd; s1 = ref_ele.slave[1].s
    elseif ref_origin == Center;  s1 = 0.5 * (ref_ele.slave[1].s + ref_ele.slave[end].s_exit)
    else;                         s1 = ref_ele.slave[end].s_exit
    end
  else    # Not a lord branch
    if ref_origin == EntranceEnd; s1 = ref_ele.s
    elseif ref_origin == Center;  s1 = 0.5 * (ref_ele.s + ref_ele.s_exit)
    else;                         s1 = ref_ele.s_exit
    end
  end

  if ele_origin == EntranceEnd; s1 = s1 + offset
  elseif ele_origin == Center;  s1 = s1 + offset - 0.5 * L_super
  else;                         s1 = s1 + offset - L_super
  end

  s2 = s1 + L_super

  # Insertion of zero length element.
  if L_super == 0
    ele_at, _ = split_ele!(branch, s1, choose_upstream = (ref_origin == ExitEnd), ele_near = ref_ele)
    insert_ele!(branch, super_ele, ele_at.ix_ele)
    return
  end

  # Element that has nonzero length
  branch_len = branch.ele[end].s_exit - branch.ele[1].s

  if s1 < branch.ele[1].s
    if wrap
      s1 = s1 + branch_len
    else
      @ele drift = Drift(L = branch.ele[1].s - s1)
      insert_ele!(branch, drift, 2)
    end
  end

  if s2 > branch.ele[end].s_exit
    if wrap
      s2 = s2 - branch_len
    else
      @ele drift = Drift(L = s2 - branch.ele[end].s_exit)
      insert_ele!(branch.ele, drift, length(branch.ele))
    end
  end

  # Splits locations are adjusted to avoid elements with length below the minimum.
  # And super_lord length will be adjusted accordingly.
  ele1 = ele_at_s(branch, s1, choose_upstream = false, ele_near = ref_ele)
  ele2 = ele_at_s(branch, s2, choose_upstream = true, ele_near = ref_ele)

  min_len = min_ele_length(branch.lat)

  if abs(ele1.s - s1) < min_len
    s1 = ele1.s
    super_ele.L = super_ele.L + s1 - ele1.s
  elseif abs(ele1.s_exit - s1) < min_len
    s1 = ele1.s_exit
    super_ele.L = super_ele.L + s1 - ele1.s_exit
  end

  if abs(ele2.s - s2) < min_len
    s2 = ele2.s
    super_ele.L = super_ele.L + ele2.s - s2
  elseif abs(ele2.s_exit - s2) < min_len
    s2 = ele2.s_exit
    super_ele.L = super_ele.L + ele2.s_exit - s2
  end

  # Choose_upstream is set to minimize number of elements in superposition region
  ele1, _ = split_ele(branch, s1, choose_upstream = false)
  ele2, _ = split_ele(branch, s2, choose_upstream = true)
end
