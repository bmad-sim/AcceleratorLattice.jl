function branch_split!(branch::LatBranch, s_split::Real; choose_max::Bool = False, ix_insert::Int = -1)
  # return ix_split, split_done
end

function branch_insert_latele!(branch::LatBranch, insert_ele::LatEle, ix_ele::Int)
end

function branch_bookkeeper!(branch::LatBranch)
  if branch.name == "lord"; return; end
  for (ix_ele, ele) in enumerate(branch.ele)
    ele.param[:ix_ele] = ix_ele
    if ix_ele > 1; ele.param[:s] = oldele.param[:s] + get(oldele.param, :len, 0); end
    oldele = ele
  end
end

function lat_bookkeeper!(lat::Lat)
  for branch in lat.branch
    branch_bookkeeper(branch)
  end
end