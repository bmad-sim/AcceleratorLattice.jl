(c:bookkeeping)=
# Lattice Bookkeeping
Bookkeeping in AcceleratorLattice mainly involves making sure that dependent parameters are updated as needed.
This includes dependent parameters within a lattice element, propagating changes through the lattice,
and lord/slave bookkeeping.

Note: An element in a branch has a pointer to the branch (`Ele.branch`) and the branch has
a pointer to the lattice (`Branch.lat`). So a lattice element "knows" about the lattice it
is in. On the other hand, elements in beam lines don't have pointers to the beamline. This is
an important factor when setting up forks.

%---------------------------------------------------------------------------------------------------
(s:lord.slave.book)=
## Lord/Slave Bookkeeping
There are two types of lords/slave groupings:
```{code} yaml
Superposition: Super lords / Super Slaves        [](#c:super)
Multipass:     Multipass lords Multipass Slaves  [](#c:multipass)
```

The lord and slave slave status of a lattice element is contained in the `LordSlaveStatusParams`
parameter group. The components of this group are ([](#s:lord.slave.g)):
```{code} yaml
lord_status::Lord.T     - Lord status.
slave_status::Slave.T   - Slave status.
```

For a given element, some combinations of lord and slave status are not possible. The possibilities are:
```{csv-table}

slave_status   , .NOT, .SUPER, .MULTIPASS
`.NOT`         , X, X, X 
`.SUPER`       , X,  ,   
`.MULTIPASS`   , X, X,   
```
Notice that the only possibility for an element to simultaneously be both a lord and a slave is
for a super lord being a multipass slave.

%---------------------------------------------------------------------------------------------------
(s:X)=
## Girders
`Girders` support a set of supported elements. A `Girder` may support other `Girders`
and so a hierarchy of `Girders` may be constructed. While a `Girder` may support many elements,
any given element may only be supported by one `Girder`.

`Girder` elements may support super and multipass lord elements, a `Girder` will never support
slave elements directly. This includes any super lord element that is also a multipass slave.

A `Girder` element will have a `Vector{Ele`} parameter of supported elements `.supported`.
Supported elements will have a `.girder` parameter pointing to the supporting `Girder`.
Elements that do not have a supporting `Girder` will not have this parameter.

%---------------------------------------------------------------------------------------------------
(s:super.book)=
## Superposition
Super lords are formed when elements are superimposed on top of other elements ([](#c:super)).
The AcceleratorLattice bookkeeping routines and take changes to lord element parameters and set the
appropriate slave parameters.

When there is a set of lattice elements that are in reality the same physical element, a
multipass lord can be used to represent the common physical element [](#c:multipass).
The AcceleratorLattice bookkeeping routines and take changes to lord element parameters and set the
appropriate slave parameters.

`Girder` lords support other elements (possibly including other `Girder` lords). Alignment
shifts of a `Girder` lord will shift the supported elements accordingly.

%---------------------------------------------------------------------------------------------------
(s:lord.slave)=
## Lord/Slave Element Pointers
All three types of lord elements contain a `Vector{ele`} of elements called `slaves`.

%---------------------------------------------------------------------------------------------------
(s:access)=
## Element Parameter Access
%---------------------------------------------------------------------------------------------------
(s:changed.param)=
## Changed Parameters and Auto-Bookkeeping
Importance of using pop!, insert!, push! and set! when modifying the branch.ele array.

The `ele.changed` parameter (which is actually `ele.pdict[:changed]`) is a dictionary.
The keys of this dict will be either symbols of the changed parameters or
will be an element parameter group.
When the key is a symbol of a changed parameter,
the dict value will be the old value of the parameter. These dict entries are set by the
overloaded `Base.setproperty(ele, param_sym, value)` function.
When the key is an element parameter group, the dict value will be the string `"changed"`.
These dict entries are set by functions that do lord/slave bookkeeping.

When bookkeeping is done, entries from the `ele.changed` dict are removed when the corresponding
parameter(s) are bookkeeped. If there are dict entries that remain after all bookkeeping is done,
this is an indication of a problem and a warning message is printed.

```{footbibliography}
```
