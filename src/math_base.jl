#-------------------------------------------------------------------------------------
# vector

"""
Return a vector version of `this`
"""

function vector(this)
  if this isa Vector; return this; end
  if this isa Tuple; return [item for item in this]; end
  return [this]
end

#-------------------------------------------------------------------------------------
# Misc

"NaI stands for NotAnInteger. Technically equal to -987654321."
NaI = -987654321

#-------------------------------------------------------------------------------------
# magnitude of vector

mag(v::Vector{T}) where T <: Number = sqrt(sum(v .* v))
