#---------------------------------------------------------------------------------------------------
# superimpose!

"""
    function superimpose!(super_ele::Ele, ref::Union{Ele,Branch}; ele_origin::BodyLocationSwitch = center, 
                      offset::Real = 0, ref_origin::BodyLocationSwitch = center, wrap::Bool = true)

Superimpose an element on a branch. 

- The `super_ele` element must not be a `Drift`

- Zero length elements in the superposition region will be left alone.

- Superimposing an element on top of a non-`Drift` element produces a `UnionEle` `super_slave`.

- `wrap`   Only relavent if the superimposed element has an end that extends beyond the 
starting or ending edge of the branch. If true (default), wrap the element around the
branch so that the element's upstream edge before the branch end edge and the element's 
downstream edge after the branch start edge. If `wrap` = false, extend the lattice to accommodate.

The superposition location is determined with respect to the `local` coordinates of the `ref_ele`.
Thus, a positive `offset` will displace the superposition location downstream if `ref_ele` has
a normal orientation and vice versa for a reversed orientation.

When `offset` = 0, for zero length elements  the superposition location is at the entrance end of `ref_ele` 
except if `ele_origin` is set to `downstream_end` in which case the location is at the exit end.

The superimposed element will inherit the orientation of the `ref`.

""" superimpose!

function superimpose!(super_ele::Ele ref::Union{Ele,Branch}; ele_origin::BodyLocationSwitch = b_center, 
           offset::Real = 0, ref_origin::BodyLocationSwitch = b_center, wrap::Bool = true)
  if typeof(ref) == Branch
    ref_ele = ref.ele[1]
  else
    ref_ele = ref
  end

  for refele in collect(ref_ele)
    # Get insertion branch
    branch = refele.branch
    if branch.type <: LordBranch 
      branch = refele.slaves[1].branch
      ref_ix_ele = refele.slaves[1].ix_ele
    else
      ref_ix_ele = refele.ix_ele
    end

    L_super = super_ele.L
    offset = offset * refele.orientation
    machine_ref_origin = machine_location(ref_origin, refele.orientation)  # Convert from entrance/exit to up/dowstream
    machine_ele_origin = machine_location(ele_origin, refele.orientation)

    # Insertion of zero length element with zero offset at edge of an element.
    if L_super == 0 && offset == 0 
      if machine_ref_origin == upstream_end || (machine_ref_origin == center && refele.L == 0)
        ix_insert = max(ref_ix_ele, 2)
        insert!(branch, ix_insert, super_ele)
        return
      elseif machine_ref_origin == downstream_end 
        ix_insert = min(ref_ix_ele+1, length(refele.branch.ele))
        insert!(branch, ix_insert, super_ele)
        return
      end
    end

    # Super_ele end locations: s1 and s2.
    if branch.type <: LordBranch
      if machine_ref_origin == upstream_end; s1 = refele.slaves[1].s
      elseif machine_ref_origin == center;   s1 = 0.5 * (refele.slaves[1].s + refele.slaves[end].s_downstream)
      else;                                  s1 = refele.slaves[end].s_downstream
      end
    else    # Not a lord branch
      if machine_ref_origin == upstream_end; s1 = refele.s
      elseif machine_ref_origin == center;   s1 = 0.5 * (refele.s + refele.s_downstream)
      else;                                  s1 = refele.s_downstream
      end
    end

    if machine_ele_origin == upstream_end; s1 = s1 + offset
    elseif machine_ele_origin == center;   s1 = s1 + offset - 0.5 * L_super
    else;                                  s1 = s1 + offset - L_super
    end

    s2 = s1 + L_super

    # If super_ele has zero length just insert it.
    if L_super == 0
      ele_at, _ = split!(branch, s1, choose_downstream = (machine_ref_origin != downstream_end), ele_near = refele)
      insert!(branch, ele_at.ix_ele, super_ele)
      return
    end

    # Below is for a super_ele that has a nonzero length
    branch_len = branch.ele[end].s_downstream - branch.ele[1].s

    if s1 < branch.ele[1].s
      if wrap
        s1 = s1 + branch_len
      else
        @ele drift = Drift(L = branch.ele[1].s - s1)
        insert!(branch, 2, drift)
      end
    end

    if s2 > branch.ele[end].s_downstream
      if wrap
        s2 = s2 - branch_len
      else
        @ele drift = Drift(L = s2 - branch.ele[end].s_downstream)
        insert!(branch.ele, length(branch.ele), drift)
      end
    end

    # Split points are chosen to avoid creating elements with non-zero length below the minimum.
    # And super_lord length will be adjusted accordingly.
    ele1 = ele_at_s(branch, s1, false, ele_near = refele)
    ele2 = ele_at_s(branch, s2, true, ele_near = refele)

    min_len = min_ele_length(branch.lat)

    if abs(ele1.s - s1) < min_len
      s1 = ele1.s
      super_ele.L = super_ele.L + s1 - ele1.s
    elseif abs(ele1.s_downstream - s1) < min_len
      s1 = ele1.s_downstream
      super_ele.L = super_ele.L + s1 - ele1.s_downstream
    end

    if abs(ele2.s - s2) < min_len
      s2 = ele2.s
      super_ele.L = super_ele.L + ele2.s - s2
    elseif abs(ele2.s_downstream - s2) < min_len
      s2 = ele2.s_downstream
      super_ele.L = super_ele.L + ele2.s_downstream - s2
    end

    # choose_downstream is set to minimize number of elements in superposition region.
    # The superposition region is from beginning of ele1 to beginning of ele2.

    ele2, _ = split!(branch, s2, false)  # Notice that s2 split must be done first!
    ele1, _ = split!(branch, s1, true)

    # If there are just drifts here then no superimpose needed.
    # Note: In this case there cannot be wrap around.
    all_drift = true
    n_ele = 0
    for ele in Region(ele1, ele2, false)
      n_ele += 1
      if typeof(ele) != Drift; all_drift = false; end
    end

    if all_drift
      super_ele.ix_ele = ele1.ix_ele
      branch.ele[ele1.ix_ele] = super_ele
      if n_ele > 1; deleatat!(branch.ele, super_ele.ix_ele+1:super_ele.ix_ele+n_ele-1); end

      index_and_s_bookkeeper!(branch)
      return 
    end

    # Here if a super_lord element needs to be constructed.
    sbranch = branch.lat.branch[:super_lord]
    push!(sbranch.ele, super_ele)
    super_ele.lord_status = super_lord
    super_ele.pdict[:slaves] = Vector{Ele}()
    index_and_s_bookkeeper!(sbranch)

    for ele in Region(ele1, ele2, false)
      println("$(ele.name)   $(ele.ix_ele)")
      if ele.L == 0; continue; end
      ix_ele = ele.ix_ele

      if typeof(ele) == Drift
        branch.ele[ix_ele] = copy(super_ele)
        ele2 = branch.ele[ix_ele]
        ele2.ix_ele = ix_ele
        ele2.slave_status = super_slave
        ele2.L = ele.L
        ele2.pdict[:super_lords] = Vector{Ele}([super_ele])
        push!(super_ele.slaves, ele2)

      elseif ele.slave_status != super_slave
        lord2 = ele
        push!(sbranch.ele, lord2)
        lord2.lord_status = super_lord
        branch.ele[ix_ele] = UnionEle(name = "", L = ele.L, super_lords = Vector{Ele}([super_ele]))
        slave = branch.ele[ix_ele]
        slave.slave_status = super_slave
        lord2.pdict[:slaves] = Vector{Ele}([slave])
        push!(slave.pdict[:super_lords], lord2)
        push!(super_ele.pdict[:slaves], slave)

      else  # Is super_slave and not Drift
        if typeof(ele) != UnionEle   # That is, has a single super_lord
          branch.ele[ix_ele] = UnionEle(name = "", L = ele.L, super_lords = ele.super_lords)
          old_lord = ele.super_lords[1]
          for (ix, slave) in enumerate(old_lord.slaves)
            if slave === ele; old_lord.slaves[ix] = branch.ele[ix_ele]; end
          end
        end

        slave = branch.ele[ix_ele]
        push!(slave.pdict[:super_lords], super_ele)
        push!(super_ele.pdict[:slaves], slave)
      end
    end

    index_and_s_bookkeeper!(branch)
    for lord in sbranch.ele
      set_super_slave_names!(lord)
    end

  end   # for refele in collect(ref_ele)
end
