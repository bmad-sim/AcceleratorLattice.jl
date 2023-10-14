#---------------------------------------------------------------------------------------------------
# TrackPoint

"""
Abstract base type for describing a particle at a given point in space.
"""
abstract type AbstractTrackPoint end

@kwdef mutable struct SingleTrackPoint <: AbstractTrackPoint
  vec::Vector64 = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  s::Float64 = NaN
  t::Float64 = NaN
  spin::Vector64 = [0.0, 0.0, 0.0]
  charge_weight:: Float64 = NaN
  pc_ref::Float64 = NaN
  beta::Float64 = NaN
  state::TrackingStateSwitch = Alive
  direction::Int = 1
  time_dir::Float64 = 1
  species::Species = Species("NotSet")
  location::PositionSwitch = UpstreamEnd
end
