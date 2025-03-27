(c:ele)=
# Lattice Elements

This chapter discusses lattice elements including how to create them and how to manipulate them.

%---------------------------------------------------------------------------------------------------
(s:ele.types)=
## Element Types

Lattice element types (`Quadrupole`, `RFCavity`, etc.) are structs that inherit from the abstract 
type `Ele`. Lattice elements documentation is in chapter~[](#c:ele.types). 
In the REPL, to see a list of all element types, use the command `subtypes(Ele)`:
```{code} yaml
  julia> subtypes(Ele)
  41-element Vector\{Any\}:
   ACKicker
   BeamBeam
   BeginningEle
   Bend
   ...
```

%---------------------------------------------------------------------------------------------------
(s:ele.def)=
## Instantiating a Lattice Element

Elements are defined using the `@ele` or `@eles` macros. 
The general syntax of the `@ele` macro is:
```{code} yaml
  @ele eleName = eleType(param1 = val1, param2 = val2, ...)
```
where `eleName` is the name of the element, `eleType` is the type of element, 
`param1`, `param2`,
etc. are parameter names and `val1`, `val2`, etc. are the parameter values.
Example:
```{code} yaml
  @ele qf = Quadrupole(L = 0.6, Kn1 = 0.370)
```
The `@ele` macro will construct a Julia variable with the name `eleName`. 
Additionally, the element
that this variable references will also hold `eleName` as the name of the element. So with this
example, `qf.name` will be the string `"qf"`. If multiple elements are being defined in a 
group, a single
`@eles` macro can be used instead of multiple `@ele` macros using the syntax:
```{code} yaml
  @eles begin
    eleName1 = eleType1(p11 = v11, p12 = v12, ...)
    eleName2 = eleType2(p21 = v21, p22 = v22, ...)
    ... etc...
  end
```
Example:
```{code} yaml
  @eles begin
    s1 = Sextupole(L = ...)
    b2 = Bend(...)
    ...
  end
```

%---------------------------------------------------------------------------------------------------
(s:ele.groups)=
## Element Parameter Paramss

Generally, element parameters are grouped into "`element` `parameter` `group`" 
structs which inherit from the abstract type `EleParams`. 
Element parameter documentation is in Chapter~[](#c:ele.groups). In the REPL,
To see a list of parameter groups, use the `suptypes` function:
```{code} yaml
  julia> subtypes(EleParams)
  28-element Vector{Any}:
   BodyShiftParams
   ApertureParams
   BMultipoleParams
   ...
```
Chapter~[](#c:ele.types) documents the parameters groups that are associated with any particular element type.
In the REPL, the associated parameter groups can be viewed using Julia's help function. Example: 
```{code} yaml
  help?> Quadrupole
    mutable struct Quadrupole <: Ele
    Type of lattice element.

    Associated parameter groups
    ===========================
      •  BodyShiftParams -> Element position/orientation shift.
      •  ApertureParams -> Vacuum chamber aperture.
      •  BMultipoleParams -> Magnetic multipoles.
      •  EMultipoleParams -> Electric multipoles.
      •  FloorParams -> Floor position and orientation.
      •  LengthParams -> Length and s-position parameters.
      •  LordSlaveParams -> Element lord and slave status.
      •  MasterParams -> Contains field_master parameter.
      •  ReferenceParams -> Reference energy and species.
      •  DescriptionParams -> String labels for element.
      •  TrackingParams -> Default tracking settings.
```
Alternatively, 

%---------------------------------------------------------------------------------------------------
(s:ele.params)=
## Element Parameters

For example, the `LengthParams` holds the length and s-positions of the element and is defined by:
```{code} yaml
  @kwdef struct LengthParams <: EleParams
    L::Number = 0.0               # Length of element
    s::Number = 0.0               # Starting s-position
    s_downstream::Number = 0.0    # Ending s-position
    orientation::Int = 1          # Longitudinal orientation
  end
```
The `@kwdef` macro automatically defines a keyword-based constructor for `LengthParams`.
See the Julia manual for more information on `@kwdef`. 
To see a list of all element parameter groups use the `subtypes(EleParamterParams)` command.
To see the components of a given group use the `fieldnames` function. For information on
a given element parameter use the `info(::Symbol)` function where the argument is the
symbol corresponding to the component. For example, the information on
the `s_downstream` parameter which is a field of the `LengthParams` is:
```{code} yaml
  julia> info(:s_downstream)
    User name:       s_downstream
    Stored in:       LengthParams.s_downstream
    Parameter type:  Number
    Units:           m
    Description:     Longitudinal s-position at the downstream end.
```
Notice that the argument to the `info` function is the symbol associated with the parameter.
the "user name" is the name used when setting the parameter. For instance, if `q` is a
lattice element, `q.s_downstream` would be used to access the `s_downstream` component of `q`.
This works, even though `s_downstream` is not a direct component of an element, since the dot
selection operator for lattice elements has been overloaded as explained in [](#s:ele.access).
For most parameters, the user name and the name of the corresponding component in the element parameter
group are the same. However, there are exceptions. For example:
```{code} yaml
  julia> info(:theta)
    User name:       theta_floor
    Stored in:       FloorParams.theta
    Parameter type:  Number
    Units:           rad
    Description:     Element floor theta angle orientation
```
In this example, the user name is `theta_floor` so that this parameter can be set via
```{code} yaml
  @ele bg = BeginningEle(theta_floor = 0.3)    # Set at element definition time.
  bg.theta_floor = 2.7                         # Or set after definition.
```
But the component in the `FloorParams` is `theta` so
```{code} yaml
  bg.FloorParams.theta = 2.7   # Equivalent to the set above.
```

%---------------------------------------------------------------------------------------------------
(s:ele.access)=
## How Element Parameters are Stored in an Element

All lattice element types have a single field of type `Dict\{Symbol,Any\`} named `pdict`.
The values of `pdict` will, with a few exceptions, be an
element parameter group. The corresponding key for a parameter group in `pdict` is the symbol associated 
with the type. For example, a `LengthParams` struct would be stored in `pdict[:LengthParams]`.

To (partially) hide the complexity of parameter groups, the dot selection operator is overloaded for elements.
This is achieved by overloading the `Base.setproperty` and `Base.getproperty` functions, 
which get called when the dot selection operator is used.
For example, if `q` is an element instance, `q.s` will get mapped to `q.pdict[:LengthParams].s`.
Additionally, `q.LengthParams` is mapped to `q.pdict[:LengthParams]`.

Besides simplifying the syntax, overloading the dot selection operator has a second purpose which
is to allow the AcceleratorLattice bookkeeping routines to properly do dependent parameter bookkeeping ([](#param.depend)).
To illustrate this, consider the following two statements which both set the `s_downstream`
parameter of an element named `q1`:
```{code} yaml
  q1.pdict[:Length_group].s_downstream = q1.pdict[:Length_group].s + 
                                                     q1.pdict[:Length_group].L
  q1.s_downstream = q1.s + q1.L
```
These two statements are not equivalent. The difference is that in the first statement when
`setproperty` is called to handle `q1.pdict`, the code will simply return `q1.pdict` 
(the code knows that `pdict` is special) and do nothing else. 
However, with the second statement, `setproperty` not only sets
`q1.s_downstream` but additionally records the set by adding an entry to
`q1.pdict[:changed]` which is a dict within `pdict`. 
The key of the entry will, in this case, be the symbol `:s_downstream` 
and the value will be the old value of the parameter. 
When the `bookkeeper(::Lattice)` function is called ([](#xxx)), the bookkeeping code will use the
entries in `ele.pdict[:changed]` to limit the bookkeeping to what is necessary and thus
minimize computation time. 
Knowing what has been changed is also important in resolving what
dependent parameters need to be changed. 
For example, if the bend `angle` is changed, the bookkeeping code will set the 
bending strength `g` using the equation `g` = `angle` / `L`. If, instead,
`g` is changed, the bookkeeping code will set `angle` appropriately. 

While the above may seem complicated, in practice the explicit use of `q1.pdict` should be avoided
since it prevents the bookkeeping from dealing with dependent parameters.
The place where `q1.pdict` is needed is in the bookkeeping code itself to avoid infinite loops.
 

%---------------------------------------------------------------------------------------------------
(s:param.depend)=
## Bookkeeping and Dependent Element Parameters

After lattice parameters are changed, the function `bookkeeper(::Lattice)` needs to be called
so that dependent parameters can be updated. 
Since bookkeeping can take a significant amount of time if bookkeeping is done every time
a change to the lattice is made, and since there is no good way to tell when bookkeeping should
be done, After lattice expansion, `bookkeeper(::Lattice)` is never called directly by AcceleratorLattice 
functions and needs to be called by the User when appropriate (generally before tracking or
other computations are done).

Broadly, there are two types of dependent parameters: intra-element dependent parameters where
the changed parameters and the dependent parameters are all within the same element and
cascading dependent parameters where changes to one element cause changes to parameters of 
elements downstream.

The cascading dependencies are:
%
\item [s-position dependency:]
Changes to an elements length `L` or changes to the beginning element's `s` parameter will
result in the s-positions of all downstream elements changing.
%
\item [Reference energy dependency:] Changes to the be beginning element's reference energy (or
equivilantly the referece momentum), or changes to the `voltage` of an `LCavity` element
will result in the reference energy of all downstream elements changing.
%
- **Floor position dependency:**
The position of a lattice element in the floor coordinate system ([](#s:floor)) is affected
by a) the lengths of all upstream elements, b) the bend angles of all upstream elements, and c)
the position in floor coordinates of the beginning element.


%---------------------------------------------------------------------------------------------------
(s:ele.new.type)=
## Defining a New Element Type

To construct a new type, use the `@construct_ele_type` macro. Example:
```{code} yaml
  @construct_ele_type MyEle
```
And this defines a new type called `MyEle` which inherits from the abstract type `Ele` and
defines `MyEle` to have a single field called `pdict` which is of type `Dict\{Symbol,Any\`}.
This macro also pushes the name

%---------------------------------------------------------------------------------------------------
(s:ele.new.param)=
## Defining New Element Parameters

```{footbibliography}
```
