#---------------------------------------------------------------------------------------------------
# Defines the types used throughout the package.

#---------------------------------------------------------------------------------------------------
# BeamLineItem

"""
    abstract type BeamLineItem

Abstract type for stuff that can be in a beam line. Subtypes are:

    BeamLine
    BeamLineEle
    Branch
    Ele
""" BeamLineItem

abstract type BeamLineItem end

#---------------------------------------------------------------------------------------------------
# Ele

"""
    mutable struct Ele <: BeamLineItem

Lattice element structure.
Note: `Ele()` will construct a NullELE

## Fields
• `name::String`                        - Name of element.
• `class::Type{T} where T <: EleClass`  - Type of element (Drift, etc.).
• `pdict::Dict{Symbol, Any}`            - Element parameters.
""" Ele
 
mutable struct Ele <: BeamLineItem
  name::String
  class::Type{T} where T <: EleClass
  pdict::Dict{Symbol,Any}
end

Ele() = Ele("NULL_ELE", NullEle, Dict{Symbol,Any}())

#---------------------------------------------------------------------------------------------------
# NullEle

"""

`NULL_ELE` is a const NullEle element to be used with bookkeeping code.
""" NULL_ELE

const NULL_ELE = Ele()

#---------------------------------------------------------------------------------------------------
# Eles

"""
    Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}

Single element or vector of elemements."
""" Eles

Eles = Union{Ele, Vector{Ele}, Tuple{Ele}}


Base.collect(x::Ele) = [x]

#---------------------------------------------------------------------------------------------------
# @ele macro

"""
    macro ele(expr)

Element constructor Example:
    @ele q1 = Quadrupole(L = 0.2, Ks1 = 0.67, ...)
Result: The variable `q1` is an `Ele` with `EleClass` set to `Quadrupole` and with the 
argument values put the the appropriate place.

Note: All element parameter structs associated with the element type will be constructed. Thus, in the
above example,`q1` above will have `q1.LengthParams` (equivalent to `q1.pdict[:LengthParams]`) created.
"""
macro ele(expr)
  expr.head == :(=) || error("Missing equals sign '=' after element name. " * 
                               "Expecting something like: \"q1 = Quadrupole(...)\"")
  name = expr.args[1]
  insert!(expr.args[2].args, 2, "$name")
  return esc(expr)   # This will call the lattice element constructor below
end

#---------------------------------------------------------------------------------------------------
# @eles macro

"""
    macro eles(block)

Constructs elements for all elements on each line in a block. Equivalent to applying the 
@ele macro to each line.

### Example:
```
@eles begin
q1 = Quadrupole(L = 0.2, Ks1 = 0.67)
q2 = Quadrupole(L = 0.6, Kn1 = -0.3)

d = Drift(L = 0.2)
end
```
"""
macro eles(block)
  block.head == :block || error("@eles must be followed by a block!")
  eles = filter(x -> !(x isa LineNumberNode), block.args)
  for ele in eles
    ele.head == :(=) || error("Missing equals sign '=' after element name in @eles block.\n" * 
                              "Error evaluating: $(string(ele))")
    try
      name = ele.args[1]
      insert!(ele.args[2].args, 2, "$name")
    catch
      println("Error in @eles block evaluating: $(string(ele))")
      rethrow()
    end
  end

  return esc(block)
end

#---------------------------------------------------------------------------------------------------
# Element class to Ele construction function 

"""
    function (ele_class::Type{T})(name::AbstractString; kwargs...) where T <: EleClass -> Ele


Lattice element constructor. Takes something like 
```
  Drift("my_drift", L = ...)
```
and returns 
```
  Ele("my_drift", Drift, pdict = Dict{Symbol,Any}(:L => ...))
```

Note: The constructor initializes `Ele.pdict[:branch]` since it is assumed by the
bookkeeping code to always exist.
"""
function (::Type{T})(name::AbstractString; kwargs...) where T <: EleClass
  ele = Ele(name, T, Dict{Symbol,Any}(:branch => nothing))
  pdict = ele.pdict
  pdict[:changed] = Dict{Union{Symbol,DataType,UnionAll},Any}()

  try
    # Setup parameter structs.
    for param_struct in PARAM_GROUPS_LIST[T]
      if typeof(param_struct) == UnionAll
        pdict[Symbol(param_struct)] = param_struct{Float64}()
      else
        pdict[Symbol(param_struct)] = param_struct()
      end
    end

    # Put parameters in parameter structs and changed area
    for (sym, val) in kwargs
      Base.setproperty!(ele, sym, val)
    end

  catch
    println("Error evaluating: $T($(str_quote(name)), ...)")
    rethrow()
  end

  return ele
end

#---------------------------------------------------------------------------------------------------
# BeamLineEle

"""
    mutable struct BeamLineEle <: BeamLineItem

An item in a `BeamLine.line[]` array that represents a lattice element.

## Fields
• `ele::Ele` \\
• `pdict::Dict{Symbol,Any}` \\

Essentially, `BeamLineEle` is an `Ele` along with some extra information stored in the `pdict` Dict
component. The extra information is the element's orientation and multipass state.

Note: All instances a given Ele in beamlines are identical so that the User can easily 
make a Change to all. When the lattice is expanded, deepcopyies of Eles will be done.
"""
mutable struct BeamLineEle <: BeamLineItem
  ele::Ele
  pdict::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
# BeamLine

"""
    mutable struct BeamLine <: BeamLineItem

Structure holding a beamline.

## Fields

• `id::String`                  - ID stringused for multipass bookkeeping. \\
• `line::Vector{BeamLineItem}`  - Vector of beam line components. \\
• `pdict::Dict{Symbol,Any}`     - Extra information. See below. \\

Standard components of `pdict` are:
• `name`          - String to be used for naming the lattice branch if this is a root branch. \\
• `orientation`   - +1 or -1. \\
• `geometry`      - `OPEN` or `CLOSED`. \\
• `multipass`     - `true` or `false`. \\
"""
mutable struct BeamLine <: BeamLineItem
  id::String
  line::Vector{BeamLineItem}
  pdict::Dict{Symbol,Any}
end

#---------------------------------------------------------------------------------------------------
# EleParamsInfo

"""
    Internal: struct EleParamsInfo

Struct holding information on a single `EleParams` struct.
Used in constructing the `ELE_PARAM_GROUP_INFO` Dict.

## Contains
• `description::String`      - Descriptive string. \\
• `bookkeeping_needed::Bool  - If true, this indicates there exists a bookkeeping function for the \\
  parameter struct that needs to be called if a parameter of the struct is changed. \\
"""
struct EleParamsInfo
  description::String
  bookkeeping_needed::Bool
end

#---------------------------------------------------------------------------------------------------
# EleParams

"""
    abstract type BaseEleParams
    abstract type EleParams <: BaseEleParams
    abstract type EleParameterSubParams <: BaseEleParams

`EleParams` is the base type for all element parameter structs.
`EleParameterSubParams` is the base type for structs that are used as components of an element
parameter struct.

To see in which element types contain a given parameter struct, use the `info(::EleParams)`
method. To see what parameter structs are contained in a Example:
```
    info(BodyShiftParams)      # List element types that contain BodyShiftParams
```
""" BaseEleParams, EleParams, EleParameterSubParams

abstract type BaseEleParams end
abstract type EleParams <: BaseEleParams end
abstract type EleParameterSubParams <: BaseEleParams end

#---------------------------------------------------------------------------------------------------
# BMultipole subparams

"""
    mutable struct BMultipole{T<:Number} <: EleParameterSubParams

Single magnetic multipole of a given order.
Used by `BMultipoleParams`.

## Fields

• `Kn::T`                 - Normal normalized component. EG: `"Kn2"`, `"Kn2L"`. \\
• `Ks::T`                 - Skew multipole component. EG: `"Ks2"`, `"Ks2L"`.  \\
• `Bn::T`                 - Normal field component. \\ 
• `Bs::T`                 - Skew field component. \\
• `tilt::T`               - Rotation of multipole around `z`-axis. \\
• `order::Int`            - Multipole order. \\
• `integrated::Union{Bool,Nothing}` - Integrated or not? \\
  Also determines what stays constant with length changes. \\
"""
@kwdef mutable struct BMultipole{T<:Number} <: EleParameterSubParams  # A single multipole
  Kn::T = 0.0                 # EG: "Kn2", "Kn2L" 
  Ks::T = 0.0                 # EG: "Ks2", "Ks2L"
  Bn::T = 0.0
  Bs::T = 0.0  
  tilt::T = 0.0
  order::Int   = -1           # Multipole order
  integrated::Union{Bool,Nothing} = nothing  # Also determines what stays constant with length changes.
end

#---------------------------------------------------------------------------------------------------
# Dispersion subparams

"""
Dispersion parameters for a single axis.

""" Dispersion1

@kwdef mutable struct Dispersion1{T<:Number} <: EleParameterSubParams
  eta::T = NaN           # Position dispersion.
  etap::T = NaN          # Momentum dispersion.
  deta_ds::T = NaN       # Dispersion derivative.
end

#---------------------------------------------------------------------------------------------------
# EMultipole subparams

"""
    mutable struct EMultipole{T<:Number} <: EleParameterSubParams

Single electric multipole of a given order.
Used by `EMultipoleParams`.

## Fields

• `En::T`                  - Normal field component. EG: "En2", "En2L" \\
• `Es::T`                  - Skew fieldEG component. EG: "Es2", "Es2L" \\
• `Etilt::T`               - Rotation of multipole around `z`-axis. \\
• `order::Int`             - Multipole order. \\
• `Eintegrated::Bool`      - Integrated field or not?. \\
  Also determines what stays constant with length changes. \\
""" EMultipole

@kwdef mutable struct EMultipole{T<:Number} <: EleParameterSubParams
  En::T = 0.0                    # EG: "En2", "En2L"
  Es::T = 0.0                    # EG: "Es2", "Es2L"
  Etilt::T = 0.0
  order::Int = -1 
  Eintegrated::Union{Bool,Nothing} = nothing
end

#---------------------------------------------------------------------------------------------------
# Twiss subparams.

"""
    mutable struct Twiss{T<:Number} <: EleParameterSubParams

Twiss parameters for used for BeamBeam element to describe the strong beam.
""" Twiss

@kwdef mutable struct Twiss{T<:Number} <: EleParameterSubParams
  beta_a::T = NaN
  alpha_a::T = NaN
  beta_b::T = NaN
  alpha_b::T = NaN
end

#---------------------------------------------------------------------------------------------------
# Twiss1 subparams

"""
    mutable struct Twiss1{T<:Number} <: EleParameterSubParams

Twiss parameters for a single mode.

""" Twiss1

@kwdef mutable struct Twiss1{T<:Number} <: EleParameterSubParams
  beta::T = NaN          # Beta Twiss
  alpha::T = NaN         # Alpha Twiss
  gamma::T = NaN         # Gamma Twiss
  phi::T = NaN           # Phase
  eta::T = NaN           # Position dispersion.
  etap::T = NaN          # Momentum dispersion.
  deta_ds::T = NaN       # Dispersion derivative.
end

#---------------------------------------------------------------------------------------------------
# VertexSubParams

"""
  abstract type VertexSubParams <: EleParameterSubParams

Abstract type that Vertex1 and VertexEllipse inherit from.
"""

abstract type VertexSubParams <: EleParameterSubParams end

#---------------------------------------------------------------------------------------------------
# Vertex1 subparams

"""
  struct Vertex1 <: VertexSubParams <: EleParameterSubParams

Single vertex point. An array of vertices can be used to construct an aperture.
Also see `VertexEllipse`.

## Fields
• `r0::Vector{Number}`       - (x, y) coordinate of vertex point. \\
""" Vertex1

@kwdef mutable struct Vertex1 <: EleParameterSubParams
  point::Vector{Number} = [NaN, NaN]
end


#---------------------------------------------------------------------------------------------------
# VertexEllipse

"""
  struct VertexEllipse  <: VertexSubParams <: EleParameterSubParams

Placed in between two `Vertex1` vertices in the `vertex` array of the `Wall2d` struct to indicate 
that the aperture outline follows an ellipse between the vertices.

## Fields

• `radius::Vector{Number}`   - Ellipse (rx, ry) ellipse radiuses. \\
• `tilt::Number`             - Tilt of ellipse. \\
""" VertexEllipse

@kwdef mutable struct VertexEllipse <: EleParameterSubParams
  radius::Vector{Number} = [0.0]
  tilt::Number = 0.0
end

#---------------------------------------------------------------------------------------------------
# Wall2D subparams

"""
    mutable struct Wall2D <: EleParameterSubParams

Vacuum chamber wall cross-section.

## Fields

• `vertex::Vector{VertexSubParams}` - Array of vertices. \\
• `r0::Vector{Number}`      - Origin point. \\
""" Wall2D

@kwdef mutable struct Wall2D <: EleParameterSubParams
  r0::Vector{Number} = [0.0, 0.0]
  absolute_vertices::Bool = false
  vertex::Vector{VertexSubParams} = Vector{VertexSubParams}()
end

#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
# ACKickerParams

"""
    mutable struct ACKickerParams <: EleParams

ACKicker parameters.

## Fields
• `amp_function::Function`    - Amplitude function. Signature:
```
  amp_function(time::T) -> amplitude::T
```

""" ACKickerParams

@kwdef mutable struct ACKickerParams <: EleParams
  amp_function::Union{Function, Nothing} = nothing
end

#---------------------------------------------------------------------------------------------------
# ApertureParams

"""
    mutable struct ApertureParams <: EleParams

Vacuum chamber aperture struct.

## Fields
• `x_limit::Vector`                     - `[x-, x+]` Limits in x-direction. \\
• `y_limit::Vector`                     - `[y-, y+]` Limits in y-direction. \\
• `wall::Wall2D`                        - Aperture defined by an array of vertices. \\
• `aperture_shape::ApertureShape.T`     - Aperture shape. Default is `ApertureShape.ELLIPTICAL`. \\
• `aperture_at::BodyLoc.T`              - Where aperture is. Default is `BodyLoc.ENTRANCE_END`. \\
• `aperture_shifts_with_body:Bool`      - Do element alignments shifts move the aperture? Default is `false`. \\
• `custom_aperture::Dict`               - Custom aperture information. \\
""" ApertureParams

@kwdef mutable struct ApertureParams <: EleParams
  x_limit::Vector = [-Inf, Inf]
  y_limit::Vector = [-Inf, Inf]
  aperture_shape::typeof(ApertureShape) = ELLIPTICAL
  aperture_at::BodyLoc.T = BodyLoc.ENTRANCE_END
  wall::Wall2D = Wall2D()
  aperture_shifts_with_body::Bool = true
  custom_aperture::Dict = Dict()
end

#---------------------------------------------------------------------------------------------------
# BeamBeamParams

#### This is incomplete ####

"""
    mutable struct BeamBeamParams{T<:Number} <: EleParams

## Fields
• `n_slice::Int`        - Number of slices the Strong beam is divided into. \\
• `n_particle::T`       - Number of particle in the strong beam. \\
• `species::Species`    - Strong beam species. Default is weak particle species. \\
• `z0_crossing::T`      - Weak particle phase space z when strong beam center.  \\
                        -   passes the BeamBeam element. \\
• `repetition_freq::T`  - Strong beam repetition rate. \\
• `twiss::Twiss{T}`     - Strong beam Twiss at IP. \\
• `sig_x::T`            - Strong beam horizontal sigma at IP. \\
• `sig_y::T`            - Strong beam vertical sigma at IP. \\
• `sig_z::T`            - Strong beam longitudinal sigma. \\
• `bbi_constant::T`     - BBI constant. Set by Bmad. See manual. \\
""" BeamBeamParams

@kwdef mutable struct BeamBeamParams{T<:Number} <: EleParams
  n_slice::T = 1
  n_particle::T = 0
  species::Species = Species()
  z0_crossing::T = 0       # Weak particle phase space z when strong beam Loc.CENTER passes
                                #   the BeamBeam element.
  repetition_freq::T = 0  # Strong beam repetition rate.
  twiss::Twiss = Twiss()        # Strong beam Twiss at IP.
  sig_x::T = 0
  sig_y::T = 0
  sig_z::T = 0
  bbi_constant::T = 0      # Will be set by Bmad. See manual.
end

#---------------------------------------------------------------------------------------------------
# BendParams

"""
    mutable struct BendParams{T<:Number} <: EleParams

## Fields
• `bend_type::BendType.T`     - Is e or e_rect fixed? 
  Also is len or len_chord fixed? Default is `BendType.SECTOR`. \\
• `angle::T`             - Reference bend angle. \\
• `g::T`                 - Reference coordinates bend curvature. \\
• `bend_field_ref::T`    - Reference bend field. \\
• `L_chord::T`           - Chord length. \\
• `tilt_ref::T`          - Tilt angle of reference (machine) coordinate system. \\
• `e1::T`                - Pole face rotation at the entrance end with respect to a sector geometry. \\
• `e2::T`                - Pole face rotation at the exit end with respect to a sector geometry. \\
• `e1_rect::T`           - Pole face rotation with respect to a rectangular geometry. \\
• `e2_rect::T`           - Pole face rotation with respect to a rectangular geometry. \\
• `edge_int1::T`         - Field integral at entrance end. \\
• `edge_int2::T`         - Field integral at exit end. \\
• `exact_multipoles::ExactMultipoles.T` - Field multipoles treatment. Default is `ExactMultipoles.OFF`. \\

## Output Parameters
• `rho::T`               - Reference bend radius. \\ 
• `L_sagitta::T`         - Sagitta length of bend semi circle. \\
• `bend_field::T`        - Actual bend field in the plane of the bend. \\
• `norm_bend_field::T`   - Actual bend strength in the plane of the bend. \\

## Notes
For tracking there is no distinction made between sector like (`BendType.SECTOR`) bends and
rectangular like (`BendType.RECTANGULAR`) bends. The `bend_type` switch is only important when the
bend angle or length is varied. See the documentation for details.

Whether `bend_field_ref` or `g` is held constant when the reference energy is varied is
determined by the `field_master` setting in the MasterParams struct.
""" BendParams

@kwdef mutable struct BendParams{T<:Number} <: EleParams
  bend_type::BendType.T = BendType.SECTOR 
  angle::T = 0.0
  g::T = 0.0           
  bend_field_ref::T = 0.0
  L_chord::T = 0.0
  tilt_ref::T = 0.0
  e1::T = 0.0
  e2::T = 0.0
  e1_rect::T = 0.0
  e2_rect::T = 0.0
  edge_int1::T = 0.5
  edge_int2::T = 0.5
  exact_multipoles::ExactMultipoles.T = ExactMultipoles.OFF
end

#---------------------------------------------------------------------------------------------------
# BMultipoleParams

"""
    mutable struct BMultipoleParams{T<:Number} <: EleParams

Vector of magnetic multipoles.

## Field
• `pole::Vector{BMultipole{T}}` - Vector of multipoles. \\

"""
@kwdef mutable struct BMultipoleParams{T<:Number} <: EleParams
  pole::Vector{BMultipole{T}} = Vector{BMultipole{T}}(undef,0)         # Vector of multipoles.
end

#---------------------------------------------------------------------------------------------------
# BodyShiftParams

"""
    mutable struct BodyShiftParams{T<:Number} <: EleParams

Defines the position and orientation of the body coordinates of an element with respect to 
the supporting girder if it exists or with respect to the machine coordinates. 

See the manual for details about how the three rotations are combined.

## Fields
• `offset::Vector`     - [x, y, z] offset. User symbol: `offset_body`. \\
• `x_rot::T`      - Rotation around the x-axis. User symbol: `x_rot_body`. \\
• `y_rot::T`      - Rotation around the y-axis. User symbol: `y_rot_body`. \\
• `z_rot::T`      - Rotation around the z-axis. User symbol: `z_rot_body`. \\

## Associated Output Parameters

The `_body_tot` parameters are the body coordinates with respect to the branch coordinates. 
These parameters are calculated by `AcceleratorLattice` and will be equal to the corresponding
non-tot fields if there is no `Girder`.

• `q_body::Quaternion{T}`       - `Quaternion` representation of `x_rot`, `y_rot`, `tilt` orientation. \\
• `q_body_tot:: Quaternion{T}`  - `Quaternion` representation of orienttion with Girder shifts. \\
• `offset_body_tot::Vector`     - `[x, y, z]` offsets including Girder alignment shifts. \\
• `x_rot_body_tot::T`           - Rotation around the x-axis including Girder alignment shifts. \\
• `y_rot_body_tot::T`           - Rotation around the y-axis including Girder alignment shifts. \\
• `z_rot_body_tot::T`           - Rotation around the z-axis including Girder alignment shifts. \\
"""

@kwdef mutable struct BodyShiftParams{T<:Number} <: EleParams
  offset::Vector = [0.0, 0.0, 0.0] 
  x_rot::T = 0
  y_rot::T = 0
  z_rot::T = 0
end

#---------------------------------------------------------------------------------------------------
# DescriptionParams

"""
    mutable struct DescriptionParams <: EleParams

Strings that can be set and used with element searches.
These strings have no affect on tracking.

# Fields

• `subtype::String` \\
• `ID::String` \\
• `label::String` \\
• `description::Dict{Any,Any}
""" DescriptionParams

@kwdef mutable struct DescriptionParams <: EleParams
  subtype::String = ""
  ID::String = ""
  label::String = ""
  description::Dict{Any,Any} = Dict{Any,Any}()
end

#---------------------------------------------------------------------------------------------------
# EMultipoleParams

"""
    mutable struct EMultipoleParams{T<:Number} <: EleParams

Vector of Electric multipoles.

## Field
• `pole::Vector{EMultipole{T}}`  - Vector of multipoles. \\
"""
@kwdef mutable struct EMultipoleParams{T<:Number} <: EleParams
  pole::Vector{EMultipole{T}} = Vector{EMultipole{T}}([])         # Vector of multipoles. 
end

#---------------------------------------------------------------------------------------------------
# FloorParams

"""
    mutable struct FloorParams{T<:Number} <: EleParams

Position and angular orientation.
In a lattice element, this struct gives the Floor coordinates at the upstream end of the element
ignoring alignment shifts.

## Fields
• `r::Vector`              - `[x,y,z]` position. User symbol: `r_floor`. \\
• `q::Quaternion{T}`  - Quaternion orientation. User symbol: `q_floor`. \\

## Associated output parameters:
• `x_rot_floor::T`   - X-axis rotation associated with quaternion `q`. \\
• `y_rot_floor::T`   - Y-axis rotation associated with quaternion `q`. \\
• `z_rot_floor::T`   - Z-axis rotation associated with quaternion `q`. \\

Note: To get the three rotations as a vector use `rot_angles(Ele.q_floor)` where `Ele` is
the lattice element.
""" FloorParams

@kwdef mutable struct FloorParams{T<:Number} <: EleParams
  r::Vector = [0.0, 0.0, 0.0]
  q::Quaternion{T} = Quaternion{T}(1.0, 0.0, 0.0, 0.0)
end

#---------------------------------------------------------------------------------------------------
# ForkParams

"""
    mutable struct ForkParams{T<:Number} <: EleParams

Fork element parameters.

## Fields
• `to_line::Union{BeamLine,Nothing}`    - Beam line to fork to. \\
• `to_ele::Union{String,Ele,Nothing}`   - On input: Element ID or element itself. \\
• `direction::Int`                      - Longitudinal Direction of injected beam. \\
• `propagate_reference::Bool`           - Propagate reference species and energy? \\


""" ForkParams

@kwdef mutable struct ForkParams{T<:Number} <: EleParams
  to_line::Union{BeamLine,Nothing} = nothing
  to_ele::Union{String,Ele,Nothing} = nothing
  direction::Int = +1
  propagate_reference::Bool = true
end

#---------------------------------------------------------------------------------------------------
# GirderParams

"""
    mutable struct GirderParams <: EleParams

Girder parameters.

## Fields
• `supported:::Vector{Ele}`        - Elements supported by girder. \\
""" GirderParams

@kwdef mutable struct GirderParams <: EleParams
  supported::Vector{Ele} = Ele[]
end

#---------------------------------------------------------------------------------------------------
# InitParticleParams

"""
    mutable struct InitParticleParams{T<:Number} <: EleParams

Initial particle position.

## Fields
• `orbit::Vector{Number}`     - Phase space 6-vector. \\
• `spin::Vector{Number}`      - Spin 3-vector. \\
"""
@kwdef mutable struct InitParticleParams{T<:Number} <: EleParams
  orbit::Vector{Number} = Vector{Number}([0,0,0,0,0,0])     # Phase space vector
  spin::Vector{Number} = Vector{Number}([0,0,0])            # Spin vector
end

#---------------------------------------------------------------------------------------------------
# LengthParams

"""
    mutable struct LengthParams{T<:Number} <: EleParams

Element length and s-positions.

# Fields

• `L::T`               - Length of element. \\
• `s::T`               - Starting s-position. \\
• `s_downstream::T`    - Ending s-position. \\
• `orientation::Int`        - Longitudinal orientation. +1 or -1. \\
""" LengthParams

@kwdef mutable struct LengthParams{T<:Number} <: EleParams
  L::T = 0.0               # Length of element
  s::T = 0.0               # Starting s-position
  s_downstream::T = 0.0    # Ending s-position
  orientation::Int = 1          # Longitudinal orientation
end

#---------------------------------------------------------------------------------------------------
# LordSlaveStatusParams

"""
    mutable struct LordSlaveStatusParams <: EleParams

Lord and slave status of an element.

## Fields
• `lord_status::Lord.T`     - Lord status. \\
• `slave_status::Slave.T`   - Slave status. \\
"""

@kwdef mutable struct LordSlaveStatusParams <: EleParams
  lord_status::Lord.T = Lord.NOT
  slave_status::Slave.T = Slave.NOT
end

#---------------------------------------------------------------------------------------------------
# MasterParams

"""
    mutable struct MasterParams <: EleParams

## Fields
• `is_on::Bool`         - Turns on or off the fields in an element. When off, the element looks like a drift. \\
• `field_master::Bool`  - The setting of this matters when there is a change in reference energy. \\
In this case, if `field_master` = true, magnetic multipoles and Bend unnormalized fields will be held constant
and normalized field strengths willbe varied. And vice versa when `field_master` is `false`. \\
""" MasterParams

@kwdef mutable struct MasterParams <: EleParams
  is_on::Bool = true
  field_master::Bool = false         # Does field or normalized field stay constant with energy changes?
end

#---------------------------------------------------------------------------------------------------
# OriginEleParams

"""
    mutable struct OriginEleParams <: EleParams

Used with `Fiducial`, `FloorShift`, and `Girder` elements.
The `OriginEleParams` is used to set the coordinate reference frame from which 
the orientation set by the `BodyShiftParams` is measured. 

## Fieldsc
• `origin_ele::Ele`           - Origin reference element. Default is NULL_ELE. \\
• `origin_ele_ref_pt::Loc.T`  - Origin reference point. Default is `Loc.CENTER`. \\
""" OriginEleParams

@kwdef mutable struct OriginEleParams <: EleParams
  origin_ele::Ele = NULL_ELE
  origin_ele_ref_pt::Loc.T = Loc.CENTER
end

#---------------------------------------------------------------------------------------------------
# PatchParams

"""
    mutable struct PatchParams{T<:Number} <: EleParams

`Patch` element parameters. Other `Patch` parameters are in PositionParams

## Fields
• `flexible::Bool`            - Flexible patch? Default is `false`. \\
• `L_user::T`            - User set Length? Default is `NaN` (length calculated by bookkeeping code). \\
• `ref_coords::BodyLoc.T`     - Reference coordinate system used inside the patch. Default is `BodyLoc.EXIT_END`. \\
""" PatchParams

@kwdef mutable struct PatchParams{T<:Number} <: EleParams
  t_offset::T = 0.0                      # Time offset
  E_tot_exit::T = NaN                    # Reference energy at exit end
  pc_exit::T = NaN                       # Reference momentum at exit end
  flexible::Bool = false
  L_user::T = NaN
  ref_coords::BodyLoc.T = BodyLoc.EXIT_END
end

#---------------------------------------------------------------------------------------------------
# PositionParams

"""
    mutable struct PositionParams{T<:Number} <: EleParams

- For `Patch` elements this is the position and orientation of the exit face with respect to the entrance face.
- For `FloorShift` and `Fiducial` elements this is the position and orientation of the element with respect
  to the reference element.

## Fields
• `offset::Vector`     - [x, y, z] offset. User symbol: `offset_body`. \\
• `x_rot::T`      - Rotation around the x-axis. User symbol: `x_rot_body`. \\
• `y_rot::T`      - Rotation around the y-axis. User symbol: `y_rot_body`. \\
• `z_rot::T`      - Rotation around the z-axis. User symbol: `z_rot_body`. \\

""" PositionParams

@kwdef mutable struct PositionParams{T<:Number} <: EleParams
  offset::Vector = [0.0, 0.0, 0.0] 
  x_rot::T = 0
  y_rot::T = 0
  z_rot::T = 0
end

#---------------------------------------------------------------------------------------------------
# ReferenceParams

"""
    mutable struct ReferenceParams{T<:Number} <: EleParams

Reference energy, time, species, etc at upstream end of an element.

## Fields
• `species_ref::Species`          - Reference species entering end. \\
• `pc_ref::T`                - Reference `momentum*c` upstream end. \\
• `E_tot_ref::T`             - Reference total energy upstream end. \\
• `time_ref::T`              - Reference time upstream end. \\
• `extra_dtime_ref::T`       - User set additional time change. \\
• `dE_ref::T`                - Sets the change in the reference energy. \\
• `static_energy_ref::Bool`       - Is the reference energy set by the User or inherited 
  - from the previous element's value? Default is `false` (inherit from previous). \\

## Associated output parameters are
• `pc_ref_downstream::T`     - Reference `momentum*c` downstream end. \\
• `E_tot_ref_downstream::T`  - Reference total energy downstream end. \\
• `time_ref_downstream::T`   - Reference time downstream end. \\
• `β_ref::T`                 - Reference `v/c` upstream end. \\
• `γ_ref::T`                 - Reference gamma factor upstream end. \\
"""
@kwdef mutable struct ReferenceParams{T<:Number} <: EleParams
  species_ref::Species = Species()
  pc_ref::T = NaN
  E_tot_ref::T = NaN
  time_ref::T = 0.0
  extra_dtime_ref::T = 0.0
  dE_ref::T = 0.0
  static_energy_ref::Bool = false
end

#---------------------------------------------------------------------------------------------------
# RFParams

"""
    mutable struct RFParams{T<:Number} <: EleParams

RF voltage parameters. Also see `RFAutoParams`.

## Fields

• `frequency::T`       - RF frequency. \\
• `harmon::T`          - RF frequency harmonic number. \\
• `voltage::T`         - RF voltage. \\
• `gradient::T`        - RF gradient. \\
• `phase::T`           - RF phase. \\
• `multipass_phase::T` - RF Phase added to multipass elements. \\
• `cavity_type::Cavity.T`   - Cavity type. Default is `Cavity.STANDING_WAVE`. \\
• `n_cell::Int`             - Number of cavity cells. Default is `1`. \\
""" RFParams

@kwdef mutable struct RFParams{T<:Number} <: EleParams
  frequency::T = 0.0
  harmon::T = 0.0
  voltage::T = 0.0
  gradient::T = 0.0
  phase::T = 0.0
  multipass_phase::T = 0.0
  cavity_type::Cavity.T = Cavity.STANDING_WAVE
  n_cell::Int = 1
end

#---------------------------------------------------------------------------------------------------
# RFAutoParams

"""
    mutable struct RFAutoParams{T<:Number} <: EleParams

RF autoscale parameters. Also see `RFParams`.

## Fields

• `do_auto_amp::Bool`           - Will autoscaling set `auto_amp`? Default is `true`. \\
• `do_auto_phase::Bool`         - Will autoscaling set `auto_phase`? Default is `true`. \\
• `auto_amp::T`            - Auto RF field amplitude scale value. \\
• `auto_phase::T`          - Auto RF phase value. \\
""" RFAutoParams

@kwdef mutable struct RFAutoParams{T<:Number} <: EleParams
  do_auto_amp::Bool = true    
  do_auto_phase::Bool = true
  auto_amp::T = 1.0    
  auto_phase::T = 0.0
end

#---------------------------------------------------------------------------------------------------
# SolenoidParams

"""
  mutable struct SolenoidParams{T<:Number} <: EleParams

Solenoid parameters.

## Fields

• `Ksol::T`        - Normalized solenoid strength. \\      
• `Bsol::T`        - Solenoid field. \\
""" SolenoidParams

@kwdef mutable struct SolenoidParams{T<:Number} <: EleParams
  Ksol::T = 0.0              
  Bsol::T = 0.0
end

#---------------------------------------------------------------------------------------------------
# TrackingParams

"""
    mutable struct TrackingParams{T<:Number} <: EleParams

Sets the nominal values for tracking prameters.

# Fields
• `num_steps::Int`    - Number of steps. \\
• `ds_step::T`   - Step length. \\

""" TrackingParams

@kwdef mutable struct TrackingParams{T<:Number} <: EleParams
  num_steps::Int   = -1
  ds_step::T = NaN
end

#---------------------------------------------------------------------------------------------------
# BeginningParams

"""
    mutable struct BeginningParams{T<:Number} <: EleParams

Lattice element parameter struct storing Twiss, dispersion and coupling parameters
for an element.
""" BeginningParams

@kwdef mutable struct BeginningParams{T<:Number} <: EleParams
  a::Twiss1 = Twiss1()                # a-mode
  b::Twiss1 = Twiss1()                # b-mode
  x::Dispersion1 = Dispersion1()      # x-axis
  y::Dispersion1 = Dispersion1()      # y-axis
  inherit_s_from_fork::Bool = false
end

#---------------------------------------------------------------------------------------------------
# BaseOutput

"""
    abstract type BaseOutput

Abstract type from which output parameter structs inherit.
AcceleratorLattice defines `OutputParams <: BaseOutput` which is used for output parameters
defined by AcceleratorLattice. Custom output parameters may be defined by defining a new 
output parameter struct and a new `output_parameter` function method.

"""
abstract type BaseOutput end

#---------------------------------------------------------------------------------------------------
# OutputParams

"""
    struct OutputParams <: BaseOutput

Holy trait struct that is used to designate output element parameters.
""" OutputParams

struct OutputParams <: BaseOutput
end

#---------------------------------------------------------------------------------------------------
# AllParams

"""
    struct AllParams 

Struct used for element parameter bookkeeping whose presence represents that parameters 
in all parameter structs may have changed.
""" AllParams

struct AllParams; end

#---------------------------------------------------------------------------------------------------
# AbstractLattice 

"""
    abstract type AbstractLattice

Abstract lattice type from which the `Lattice` struct inherits.
"""
abstract type AbstractLattice end

#---------------------------------------------------------------------------------------------------
# Branch

"""
    mutable struct Branch <: BeamLineItem

Lattice branch structure. 

## Fields
• `name::String`                      - Name of the branch. \\
• `ele::Vector{Ele}`                  - Pointer to the array of lattice element contained in the branch. \\
• `pdict::Dict{Symbol,Any}`           - Dict for holding other branch parameters. \\
• `lat::Union{AbstractLattice, Nothing}`  - Pointer to the lattice containing the branch. \\

Note: `AbstractLattice` is used here since `Lattice` is not yet defined and Julia does not allow forward 
struct declarations.

## Standard pdict keys:
• `:geometry`   - `OPEN` or `CLOSED`. \\
• `:type`       - `MultipassBranch`, `SuperBranch`, `GirderBranch`, or `TrackingBranch`.  \\
• `:ix_branch`  - Index of branch in `lat.branch[]` array. \\
• `:ix_ele_min_changed` - For tracking branches: Minimum index of elements where parameter changes have been made. \\
  Set to `typemax(Int)` if no elements have been modified. \\
• `:ix_ele_max_changed` - For tracking branches: Maximum index of elements where parameter changes have been made. \\
  Set to `0` if no elements have been modified. \\

## Notes
The constant `NULL_BRANCH` is defined as a placeholder for signaling the absense of a branch.
The test `is_null(branch)` will test if a branch is a `NULL_BRANCH`.
""" Branch

@kwdef mutable struct Branch <: BeamLineItem
  name::String              = ""
  lat::Union{AbstractLattice, Nothing}  = nothing
  ele::Vector{Ele}          = Ele[]
  pdict::Dict{Symbol,Any}   = Dict{Symbol,Any}
end

""" 
The constant NULL_BRANCH is defined as a placeholder for signaling the absense of a branch.
The test is_null(branch) will test if a branch is a NULL_BRANCH.
""" NULL_BRANCH

const NULL_BRANCH = Branch(name = "NULL_BRANCH", pdict = Dict{Symbol,Any}(:ix_branch => -1))

#---------------------------------------------------------------------------------------------------
# Branch types

abstract type BranchType end
abstract type LordBranch <: BranchType end
abstract type TrackingBranch <: BranchType end

struct MultipassBranch <: LordBranch; end
struct SuperBranch <: LordBranch; end
struct GirderBranch <: LordBranch; end

## struct GovernorBranch <: LordBranch; end  # This may never be used!

#---------------------------------------------------------------------------------------------------
# LatticeGlobal

"""
    LatticeGlobal

Struct holding "global" parameters used for tracking. 
Each Lattice will store a `LatticeGlobal` in `Lattice.pdict[:LatticeGlobal]`.
""" LatticeGlobal

mutable struct LatticeGlobal
  significant_length::Float64
  pdict::Dict{Symbol,Any}
end

LatticeGlobal() = LatticeGlobal(1.0e-10, Dict())

#---------------------------------------------------------------------------------------------------
# Lattice

"""
    mutable struct Lattice <: AbstractLattice

Lattice structure.

## Fields

• `name::String`                Name of lattice. \\
• `branch::Vector{Branch}`      Array of branches. \\
• `pdict::Dict{Symbol,Any}`     Lattice parameter dictionaries. \\
• `private::Dict{Symbol, Any}`  Private storage space. \\

## Standard pdict keys

• `:auditing_enabled`        - Bool: parameter changes monitored? \\
• `:autobookkeeping`         - Bool: Automatic bookkeeping enabled? \\
• `:parameters_have_changed` - Bool: Have any parameters changed since the last bookkeeping? \\

The `:auditing_enabled` is usually `true` but can be set `false` by bookkeeping routines that 
want to make parameter changes without ele.pdict[:changed] being added to. 
Also if `:auditing_enabled` is `false`, changes to parameters that normally should not be changed are allowed. 
This enables bookkeeping code to modify, for example, dependent parameters.
"""
@kwdef mutable struct Lattice <: AbstractLattice
  name::String = ""
  branch::Vector{Branch} = Vector{Branch}()
  pdict::Dict{Symbol,Any} = Dict{Symbol,Any}()
  private::Dict{Symbol,Any} = Dict{Symbol,Any}()
end

#---------------------------------------------------------------------------------------------------
# ChangedLedger

"""
    Internal: mutable struct ChangedLedger

When bookkeeping a branch, element-by-element, starting from the beginning of the branch,
the ledger keeps track of "properties" that have changed since the last bookkeeping so that a 
change in a property of one element can propagate to the following elements. 

Ledger parameters, when toggled to true, will never be reset for the remainder of the branch bookkeeping.
The exception is the `this_ele_length` parameter which is reset after bookkeeping is done for
an element.

# Fields
• `this_ele_length::Bool`  - The length of the current element has changed. \\
• `s_position::Bool`       - The longitudinal element position has changed. \\
• `reference::Bool`        - Reference property (species, energy, or time) has changed. \\
• `floor_position::Bool`   - The branch coordinate system has changed with respect to the floor coordinates. \\

""" ChangedLedger

@kwdef mutable struct ChangedLedger
  this_ele_length::Bool = false
  s_position::Bool = false
  reference::Bool = false
  floor_position::Bool = false
end
