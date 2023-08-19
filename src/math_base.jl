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
# magnitude of vector

mag(v::Vector{T}) where T <: Number = sqrt(sum(v .* v))

#-------------------------------------------------------------------------------------
# Misc

"NaI stands for NotAnInteger. Technically equal to -1234567890123456789."
NaI = -1234567890123456789

#-------------------------------------------------------------------------------------
# cos_one

"""
    cos_one(x)

Function to calculate cos(x) - 1 to machine precision.
This is usful if angle can be near zero where the direct evaluation of cos(x) - 1 is inaccurate.
"""

cos_one(x) = -2.0 * sin(x/2.0)^2

