#---------------------------------------------------------------------------------------------------
# TrackPoint

"""
Abstract base type for describing a particle at a given point in space.
"""
abstract type AbstractTrackPoint end


@kwdef mutable struct SingleTrackPoint <: AbstractTrackPoint
  vec::Vector{Float64} = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  s::Float64 = NaN
  t::Float64 = NaN
  spin::Vector{Float64} = [0.0, 0.0, 0.0]
  charge_weight:: Float64 = NaN
  pc_ref::Float64 = NaN
  beta::Float64 = NaN
  state::TrackingState = ALIVE
  direction::Int = 1
  time_dir::Float64 = 1
  species::Species = Species("not_set")
  location::StreamLocation = UPSTREAM_END
end
