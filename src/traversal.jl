#---------------------------------------------------------------------------------------------------
# EleRegion

"""
    struct EleRegion

Structure used to iterate over through a set of elements in a lattice branch.
This structure is ment to be used with non-lord branches only.

Example:
```julia
  for ele in EleRegion(start_ele, end_ele)
    ... do something ... 
  end
```
This will iterate over the region from `start_ele` to the element just before `end_ele`.
To include `end_ele` in the iteration range, use the construct:
```julia
  for ele in EleRegion(start_ele, end_ele, true)
```

If `end_ele` is before `start_ele` in the branch then the iteration region will "wrap" around
the ends of the branch.

It is permissible for `start_ele` and/or `end_ele` to be a `super_lord`. In any case, the
iteration region will never include any `super_lord` elements. but rather their corresponding `super_slave`s.
""" EleRegion

@kwdef mutable struct EleRegion
  start_ele::Ele = NULL_ELE
  end_ele::Ele = NULL_ELE
  include_end::Bool = false
end

#---------------------------------------------------------------------------------------------------

EleRegion(start_ele::Ele, end_ele::Ele) = EleRegion(start_ele = start_ele, end_ele = end_ele)

function Base.show(io::IO, er::EleRegion)
  print(f"""
EleRegion:
 start_ele: {ele_name(er.start_ele)}
 end_ele:   {ele_name(er.end_ele)}
 include_end: {er.include_end}""")
end

Base.show(io::IO, ::MIME"text/plain", er::EleRegion) = Base.show(io::IO, er::EleRegion)

#---------------------------------------------------------------------------------------------------
# Base.iterate

"""
    Base.iterate(x::EleRegion [, ele::Ele])

Iterator used to iterate over through a set of elements in a lattice branch.
See the `EleRegion` documentation for more details.
""" Base.iterate(x::EleRegion)

function Base.iterate(x::EleRegion)
  if :branch ∉ keys(x.start_ele.pdict); error("Start element not associated with a branch"); end
  if :branch ∉ keys(x.end_ele.pdict);   error("End element not associated with a branch"); end
  x.start_ele.lord_status == SuperLord ? start_ele = x.start_ele.slaves[1] : start_ele = x.start_ele
  x.end_ele.lord_status   == SuperLord ? end_ele   = x.end_ele.slaves[1]   : end_ele   = x.end_ele
  if !(start_ele.branch === end_ele.branch); error("Start and end elements are not in the same branch"); end
  if start_ele.lord_status != NotALord; error("Start element may not be a non-super_lord lord."); end
  if end_ele.lord_status   != NotALord; error("End element may not be a non-super_lord lord."); end
  return (start_ele, start_ele)
end

function Base.iterate(x::EleRegion, ele::Ele)
  end_ele = x.end_ele
  if x.end_ele.lord_status == SuperLord
    x.include_end ? end_ele = x.end_ele.save[end] : end_ele = x.end_ele.slaves[1]
  end
  if ele == end_ele && x.include_end; return nothing; end
  ele2 = next_ele(ele)
  if ele2 == end_ele && !x.include_end; return nothing; end
  return (ele2, ele2)
end

#---------------------------------------------------------------------------------------------------
# next_ele

"""
    function next_ele(ele::Ele [, offset::Integer]; wrap::Bool = true) -> ele2::Ele

Returns element in the lattice branch whose branch index is `ele.ix_ele + offset`.

If the computed index `ele.ix_ele + offset` is out of the range [1, length(branch.ele)]: 
If `wrap` is `false`, return `NULL_ELE` else if `wrap` is `true` return the element with
index `mod(ix_ele-1, length(branch.ele)) + 1`.

### Input


### Output
  `Ele` in given `branch` and given element i
""" next_ele

function next_ele(ele::Ele, offset::Integer; wrap::Bool = true)
  branch = ele.pdict[:branch]
  ix_ele = ele.ix_ele + offset
  if !wrap && (ix_ele < 1 || ix_ele > length(branch.ele)); return NULL_ELE; end
  ix_ele = mod(ix_ele-1, length(branch.ele)) + 1
  return branch.ele[ix_ele]
end

next_ele(ele::Ele; wrap::Bool = true) = next_ele(ele, 1, wrap = wrap)

