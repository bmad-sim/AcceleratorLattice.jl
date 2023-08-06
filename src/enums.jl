""" Branch geometry."""
@enum Geometry open_geom closed_geom 
@enum BranchType tracking_type lord_type

"""Position with respect to a lattice element in a branch."""
@enum Position upstream_loc inside_loc downstream_loc

"""Placement with respect to physical (body) lattice element."""
@enum BodyLoc entrance_end exit_end both_ends nowhere everywhere
