abstract type Ele end

mutable struct Bend <: Ele
  length::Float64
end

export Ele, Bend
