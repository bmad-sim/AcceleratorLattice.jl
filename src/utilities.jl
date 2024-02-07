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
        if !haskey(ele.pdict, :orientation) error(f"SanityCheck: Ele {ele_name(ele)} does not have orientation attribute."); end
      end
    end
  end

end

#---------------------------------------------------------------------------------------------------

"""
Returns the length in characters of the string representation of a Symbol.
Here the string representation includes the leading colon.
Example: length(:abc) => 4
""" Base.length

Base.length(sym::Symbol) = length(repr(sym))

#---------------------------------------------------------------------------------------------------
# index

"""
Index of substring in string. Assumes all characters are ASCII.
Returns 0 if substring is not found
"""

function index(str::AbstractString, substr::AbstractString)
  ns = length(substr)
  for ix in range(1, length(str)-ns+1)
    if str[ix:ix+ns-1] == substr; return ix; end
  end

  return 0
end

#---------------------------------------------------------------------------------------------------
# "To print memory location of object"

function memloc(@nospecialize(x))
   y = ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
   return repr(UInt64(y))
end

