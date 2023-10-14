#-------------------------------------------------------------------------------------
# vector

"""
Return a vector version of `this`.
That is: 
  returns `this` if `this` is a vector.
  returns the vector version of `this` if `this` is a `Tuple`. 
  returns `[this]` if `this` is a scaler.
""" vector

function vector(this)
  if this isa Vector; return this; end
  if this isa Tuple; return [this...]; end
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
""" cos_one

cos_one(x) = -2.0 * sin(x/2.0)^2

#-------------------------------------------------------------------------------------
# modulo2

"""
! Function to return
!     mod2 = x + 2 * n * amp
! where n is an integer chosen such that
!    -amp <= mod2 < amp
"""

function modulo2(x, amp)
  m2 = mod(x, 2*amp)
  m2 < amp ? (return m2) : (return m2 - 2.0*amp)
end