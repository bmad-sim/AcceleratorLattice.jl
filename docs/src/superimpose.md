(c:super)=
# Superposition
Superposition is the insertion of elements into a lattice after the lattice has been created by the
`expand` function. Superposition is beneficial for various purposes. A common use of superposition is to
insert `marker` elements within other elements. For example, placing a marker element in the middle
of a quadrupole.
Another use case is when the field in some region is due to the overlap of several
elements. For example, a quadrupole magnet inside a larger solenoid magnet.

%-----------------------------------------------------------------------------
(s:super.fund)=
## Superposition on a Drift
```{figure} figures/superimpose-positioning.svg
caption[Superposition Offset.]{
The superposition `offset` is the longitudinal {math}`s`-distance from the origin point of the
reference element to the origin point of the element being superimposed.
}
:name: f:superimpose
```

A simple example illustrates how superposition works (also see section [](#s:lord.slave)):
```{code} yaml
using AcceleratorLattice
@ele dd = Drift(L = 12)
@ele bb = BeginningEle(species_ref = species("proton"), pc_ref = 1e11)
@ele ss = Solenoid(L = 1)
zline = beamline("z", [bb, dd])
lat = Lattice("lat", zline)

ref_ele = find_eles(lat, "dd")
superimpose!(ss, ref_ele, offset = 0.2)
```
Before superposition, branch 1 of lattice `lat` looks like
```{code} yaml
Branch 1: "z"  geometry => open             L           s      s_downstream
1  "bb"           BeginningEle        0.000000    0.000000 ->    0.000000
2  "dd"           Drift              12.000000    0.000000 ->   12.000000
3  "end_ele"      Marker              0.000000   12.000000 ->   12.000000
```

The `superimpose!` function has the signature
```{code} yaml
function superimpose!(super_ele::Ele, ref::T;
ele_origin::BodyLocationSwitch = b_center, offset::Real = 0,
ref_origin::BodyLocationSwitch = b_center, wrap::Bool = true)
where {E <: Ele, T <: Union{Branch, Ele, Vector{Branch}, Vector{E}}}
```
The superimpose

statement inserts a copy of the element `ss` in the lattice.




After insertion, branch 1 looks like:
```{code} yaml
Branch 1: "z"  geometry => open             L           s      s_downstream
1  "bb"           BeginningEle        0.000000    0.000000 ->    0.000000
2  "dd!1"         Drift               5.700000    0.000000 ->    5.700000
3  "ss"           Solenoid            1.000000    5.700000 ->    6.700000
4  "dd!2"         Drift               5.300000    6.700000 ->   12.000000
5  "end_ele"      Marker              0.000000   12.000000 ->   12.000000
```
The insertion of the `ss` copy is within the `drift` named `dd`. The position

With superpositions, `Drift` elements are handled differently from other elements. This is done
to simplify the bookkeeping code. T



Rules:
begin{itemize}
%
- The `super_ele` element cannot be a `Drift`.
%
- %
The `bookkeeper!` function must be called after any superpositions or
%
end{itemize}


Branch 1: "z"  geometry => open                 L           s       s_downstream
1  "bb"           BeginningEle        0.000000    0.000000 ->    0.000000
2  "dd"           Drift              12.000000    0.000000 ->   12.000000
3  "end_ele"      Marker              0.000000   12.000000 ->   12.000000


```{code} yaml
using AcceleratorLattice
@ele qq = Quadrupole(L = 4)
@ele dd = Drift(L = 12)
@ele ss = Solenoid(L = 1)
@ele bb = BeginningEle(species_ref = species("proton"), pc_ref = 1e11)
zline = beamline("z", [bb, qq, dd])
lat = Lattice("lat", zline)

ref_ele = find_eles (lat, "dd")
superimpose!(ss, ref_ele, offset = 0.2)
```

parameter of element `S` superimposes `S` over the lattice vn{(Q,
D)}. The placement of `S` is such that the beginning of `S` is coincident with the center of
`Q` (this is is explained in more detail below). Additionally, a marker `M` is superimposed at
a distance of +1~meter from the center of `S`. The tracking part of the lattice
([](#s:lord.slave)) looks like:
```{code} yaml
Element   Key         Length  Total
1)    Q{#}1       Quadrupole   2        2
2)    Q{B}S       Sol_quad     2        4
3)    S{#}1       Solenoid     3        7
4)    M         Marker       0
4)    S{#}2       Solenoid     3       10
5)    D{#}2       Drift        4       14
```
What Bmad has done is to split the original elements `(Q, D)` at the edges of `S` and then
`S` was split where `M` is inserted. The first element in the lattice, `Q#1`, is the part
of `Q` that is outside of `S`. Since this is only part of `Q`, Bmad has put a `#1` in
the name so that there will be no confusion. (a single `#` has no special meaning other than the
fact that Bmad uses it for mangling names. This is opposed to a double `##` which is used to
denote the {math}`N`Th instance of an element ([](#s:ele.match)). The next element, `Q{B`S}, is the
part of `Q` that is inside `S`. `Q{B`S} is a combination solenoid/quadrupole element as
one would expect. `S{#`1} is the part of `S` that is outside `Q` but before `M`. This
element is just a solenoid. Next comes `M`, `S{#`1}, and finally `D#2` is the rest of the
drift outside `S`.

In the above example, `Q` and `S` will be super lord elements (`s:lord.slave`) and
four elements in the tracking part of the lattice will be `super_slave` elements. This is
illustrated in {numref}`f:super.ex`B.

Notice that the name chosen for the `sol_quad` element `Q{B`S} is dependent upon what is
being superimposed upon what. If `Q` had been superimposed upon `S` then the name would have
been `S{B`Q}.

When Bmad sets the element class for elements created from superpositions, Bmad will set the class
of the element to something other than an `em_field` element ([](#s:em.field)) if possible. If
no other possibilities exist, Bmad will use `em_field`. For example, a `quadrupole`
superimposed with a `solenoid` will produce a `sol_quad` `super_slave` element but a
`solenoid` superimposed with a `rfcavity` element will produce an `em_field` element since
there is no other class of element that can simultaneously handle solenoid and RF fields. An
`em_field` `super_slave` element will also be created if any of the superimposing elements
have a non-zero orientation ([](#s:offset)) since it is not, in general, possible to construct a slave
element that properly mimics the effect of a non-zero orientation.



With the lattice broken up like this Bmad has constructed something that can be easily
analyzed. However, the original elements `Q` and `S` still exist within the lord section of
the lattice. Bmad has bookkeeping routines so that if a change is made to the `Q` or `S`
elements then these changes can get propagated to the corresponding slaves. It does not matter which
element is superimposed. Thus, in the above example, `S` could have been put in the Beam Line
(with a drift before it) and `Q` could then have been superimposed on top and the result would
have been the same (except that the split elements could have different names).

If an element has zero length (for example, a `marker` element), is superimposed, or is
superimposed upon, then the element will remain in the tracking part of the lattice and there will
be no corresponding lord element. See {numref}`f:super.ex`.

Superimpose syntax:
```{code} yaml
Q: quad, superimpose, ...       ! Superimpose element Q.
Q: quad, superimpose = T, ...   ! Same as above.
Q: quad, ...                    ! First define element Q ...
Q[superimpose] = T              !   ... and then superimpose.
Q[superimpose] = F              ! Suppress superposition.
```
Superposition happens at the end of parsing so the last set of the `superimpose` for an element
will override previous settings.

It is also possible to superimpose an element using the `superimpose` command which has the
syntax:
```{code} yaml
superimpose, element = <ele-name>, ...
```
With the same optional superposition parameters (`ref`, `offset`, etc.) given below.
Example:
```{code} yaml
superimpose, element = Q1, ref = B12, offset = 1.3,
ele_origin = beginning, ref_origin = end
```
Note: Superposition using the superimpose statement allows superimposing the same element with
multiple reference elements and/or multiple offsets. The drawback is that superposition using the
superimpose statement may not be switched off later in the lattice file.

The placement of a superimposed element is illustrated in {numref}`f:superimpose`. The placement of a
superimposed element is determined by three factors: An origin point on the superimposed element, an
origin point on the reference element, and an offset between the points. The parameters that
determine these three quantities are:
index{ref}index{offset}
index{ref_origin}index{ele_origin}
```{code} yaml
create_jumbo_slave = <Logical>     ! See [](#s:jumbo.slave)
wrap_superimpose   = <Logical>     ! Wrap if element extends past lattice ends?
ref          = <lattice_element>
offset       = <length>            ! default = 0
ele_origin   = <origin_location>   ! Origin pt on element.
ref_origin   = <origin_location>   ! Origin pt on ref element.
```
`ref` sets the reference element. If `ref` is not present then the start of the lattice is
used (more precisely, the start of branch 0 ([](#s:branch.def))). Wild card characters
([](#s:ele.match) can be used with `ref`. If `ref` matches to multiple elements (which may
also happen without wild card characters if there are multiple elements with the name given by
`ref`) in the lattice a superposition will be done, one for each match.

The location of the origin points are determined by the setting of `ele_origin` and
`ref_origin`.  The possible settings for these parameters are
```{code} yaml
beginning       ! Beginning (upstream) edge of element
center          ! Center of element. Default.
end             ! End (downstream) edge of element
```
`center` is the default setting. `Offset` is the longitudinal offset of the origin
of the element being superimposed relative
to the origin of the reference element. The default offset is zero.
A positive offset moves the element being superimposed in the `downstream` direction if
the reference element has a normal longitudinal `orientation` ([](#s:ele.reverse)) and
vice versa for the reference element has a reversed longitudinal orientation.

Note: There is an old syntax, deprecated but still supported for now, where the origin points were
specified by the appearance of:
```{code} yaml
ele_beginning         ! Old syntax. Do not use.
ele_center            ! Old syntax. Do not use.
ele_end               ! Old syntax. Do not use.
ref_beginning         ! Old syntax. Do not use.
ref_center            ! Old syntax. Do not use.
ref_end               ! Old syntax. Do not use.
```
For example, "ele_origin = beginning" in the old syntax would be "ele_beginning".

index{drift}
index{overlay}index{group}index{girder}
The element begin superimposed may be any type of element except `drift`, `group`,
`overlay`, and `girder` control elements. The reference element used to position a
superimposed element may be a `group` or `overlay` element as long as the `group` or
`overlay` controls the parameters of exactly one element. In this case, the controlled element is
used as the reference element.

index{geometry}index{open}
By default, a superimposed element that extends beyond either end of the lattice will be wrapped
around so part of the element will be at the beginning of the lattice and part of the element will
be at the end. For consistency's sake, this is done even if the `geometry` is set to `open`
(for example, it is sometimes convenient to treat a circular lattice as linear). Example:
```{code} yaml
d: drift, l = 10
q: quad, l = 4, superimpose, offset = 1
machine: line = (d)
use, machine
```
The lattice will have five elements in the tracking section:
```{code} yaml
Element    Key             Length
0)    BEGINNING  Beginning_ele   0
1)    Q{#}2        Quadrupole      3   ! Slave representing beginning of Q element
2)    D{#}1        Drift           6
3)    Q{#}1        Quadrupole      1   ! Slave representing end of Q element
4)    END        Marker          0
```
And the lord section of the lattice will have the element `Q`.

To not wrap an element that is being superimposed, set the `wrap_superimpose` logical to `False`.
Following the above example, if the definition of`q` is extended by adding `wrap_superimpose`:
```{code} yaml
q: quad, l = 4, superimpose, offset = 1, wrap_superimpose = F
```
In this instance there are four elements in the tracking section:
```{code} yaml
Element    Key             Length
0)    BEGINNING  Beginning_ele   0
1)    Q          Quadrupole      4
2)    D{#}1        Drift           7
4)    END        Marker          0
```
And the lord section of the lattice will not have any elements.

To superimpose a zero length element "`S`" next to a zero length element "`Z`", and to
make sure that `S` will be on the correct side of `Z`, set the `ref_origin` appropriately.
For example:
```{code} yaml
S1: marker, superimpose, ref = Z, ref_origin = beginning
S2: marker, superimpose, ref = Z, ref_origin = end
Z: marker
```
The order of the elements in the lattice will be
```{code} yaml
S1, Z, S2
```
If `ref_origin` is not present or set to `center`, the ordering of the elements will be
arbitrary.

If a zero length element is being superimposed at a spot where there are other zero length elements,
the general rule is that the element will be placed as close as possible to the reference element.
For example:
```{code} yaml
S1: marker, superimpose, offset = 1
S2: marker, superimpose, offset = 1
```
In this case, after `S1` is superimposed at {math}`s = 1` meter, the superposition of `S2` will
place it as close to the reference element, which in this case is the `BEGINNING` elements at {math}`s`
= 0{math}`, as possible. Thus the final order of the superimposed elements is:`
```{code} yaml
S2, S1
```
To switch the order while still superimposing `S2` second one possibility is to use:
```{code} yaml
S1: marker, superimpose, offset = 1
S2: marker, superimpose, ref = S1, ref_origin = end
```

If a superposition uses a reference element, and there are {math}`N` elements in the lattice with the
reference element name, there will be {math}`N` superpositions. For example, the following will split in
two all the quadrupoles in a lattice:
```{code} yaml
M: null_ele, superimpose, ref = quadrupole::*
```
A `null_ele` ([](#s:null.ele)) element is used here so that there is no intervening element
between split quadrupole halves as there would be if a `marker` element was used.


index{drift!superposition}index{pipe!superposition}
When a superposition is made that overlaps a drift, the drift, not being a "real" element,
vanishes. That is, it does not get put in the lord section of the lattice.  Note that if aperture
limits ([](#s:limit)) have been assigned to a drift, the aperture limits can "disappear" when
the superposition is done. Explicitly, if the exit end of a drift has been assigned aperture limits,
the limits will disappear if the superimposed element overlays the exit end of the drift. A similar
situation applies to the entrance end of a drift. If this is not desired, use a `pipe` element
instead.

To simplify bookkeeping, a drift element may not be superimposed. Additionally, since drifts can
disappear during superposition, to avoid unexpected behavior the superposition reference element may
not be the {math}`N`Th instance of a drift with a given name. For example, if there are a number of drift
elements in the lattice named `a_drft`, the following is not allowed:
```{code} yaml
my_oct: octupole, ..., superimpose, ref = a_drft##2  ! This is an error
```

When the parameters of a super_slave are computed from the parameters of its super lords, some types
of parameters may be "missing". For example, it is, in general, not possible to set appropriate
aperture parameters ([](#s:limit)) of a super_slave if the lords of the slave have differing
aperture settings. When doing calculations, Bmad will use the corresponding parameters stored in
the lord elements to correctly calculate things.

When superposition is done in a line where there is `element reversal` ([](#s:ele.reverse)),
the calculation of the placement of a superimposed element is also "reversed" to make the relative
placement of elements independent of any element reversal.  An example will make this clear:
```{code} yaml
d1: drift, l = 1
d2: d1
q1: quad, l = 0.1, superimpose, ref = d1, offset = 0.2,
ref_origin = beginning, ele_origin = beginning
q2: q1, ref = d2
p: patch, x_pitch = pi  ! Needed to separate reversed and unreversed.
this_line: line = (d1, p, --d2)
use, this_line
```
Since the reference element of the `q2` superposition, that is `d2`, is a reversed element,
`q2` will be reversed and the sense of `offset`, `ref_origin`, and `ele_origin` will be
reversed so that the position of `q2` with respect to `d2` will be the mirror image of the
position of `q1` with respect to `d1`. The tracking part of the lattice will be:
```{code} yaml
Element:           d1{#}1    q1  d1{#}2   d2{#}2    q2   d2{#}1
Length:             0.2   0.1   0.7    0.7   0.1    0.3
Reversed element?:   No    No    No    Yes   Yes    Yes
```

Superposition with `line reflection` ([](#s:lines.wo.arg)) works the same way as line reversal.

The `no_superposition` statement ([](#s:no.sup)) can be used to turn off superpositioning

%-----------------------------------------------------------------------------
(s:super.sub.line)=
## Superposition and Sub-Lines
Sometimes it is convenient to do simulations with only part of a lattice. The rule for how
superpositions are handled in this case is illustrated in the following example. Consider a lattice
file which defines a `line` called `full` which is defined by two sublines called `sub1`
and `sub2`:
```{code} yaml
sub1: line = {..., ele1, ...}
sub2: line = {...}
full: line = {sub1, sub2}
m1: marker, superimpose, ref = ele1, offset = 3.7
use, full
```
Now suppose you want to do a simulation using only the `sub2` line. Rather than edit the original
file, one way to do this would be to create a second file which overrides the used line:
```{code} yaml
call, file = "full.bmad"
use, sub2
```
where `full.bmad` is the name of the original file. What happens to the superposition of `m1`
in this case? Since `m1` uses a reference element, `ele1`, that is not in `sub1`, Bmad
will ignore the superposition. Even though Bmad will ignore the superposition of `m1` here,
Bmad will check that `ele1` has been defined. If `ele1` has not been defined, Bmad will
assume that there is a typographic error and issue an error message.

Notice that in this case it is important for the superposition to have an explicit reference element
since without an explicit reference element the superposition is referenced to the beginning of the
lattice. Thus, in the above example, if the superposition were written like:
```{code} yaml
m1: marker, superimpose, offset = 11.3
```
then when the `full` line is used, the superposition of `m1` is referenced to the beginning of
`full` (which is the same as the beginning of `sub1`) but when the `sub2` line is used, the
superposition of `m1` is referenced to the beginning of `sub2` which is not the same as the
beginning of `full`.

%-----------------------------------------------------------------------------
(s:jumbo.slave)=
## Jumbo Super_Slaves
The problem with the way `super_slave` elements are created as discussed above is that edge
effects will not be dealt with properly when elements with non-zero fields are misaligned. When this
is important, especially at low energy, a possible remedy is to instruct Bmad to construct
"`jumbo`" super_slave elements. The general idea is to create one large `super_slave` for
any set of overlapping elements. Returning to the superposition example at the start of
Section~[](#s:super), If the superposition of solenoid `S` is modified to be
```{code} yaml
S: solenoid, l = 8, superimpose, ref = Q, ele_origin = beginning,
create_jumbo_slave = T
```
The result is shown in {numref}`f:super.ex`C. The tracking part of the lattice will be
```{code} yaml
Element   Key         Length  Total
1)    Q{B}S       Sol_quad     2        4
2)    M         Marker       0
3)    S{#}2       Solenoid     3       10
4)    D{#}2       Drift        4       14
```
index{lord_pad1}index{lord_pad2}
`Q` and part of `S` have been combined into a jumbo `super_slave` named `Q{B`S}. Since
the super lord elements of a jumbo `super_slave` may not completely span the slave two
parameters of each lord will be set to show the position of the lord within the slave. These two
parameters are
```{code} yaml
lord_pad1    ! offset at upstream end
lord_pad2    ! offset at downstream end
```
`lord_pad1` is the distance between the upstream edge of the jumbo `super_slave` and a
super lord. `lord_pad2` is the distance between the downstream edge of a super lord and
the downstream edge of the jumbo `super_slave`. With the present example, the lords have the
following padding:
```{code} yaml
lord_pad1    lord_pad2
Q            0            3
S            2            0
```
The following rule holds for all super lords with and without jumbo slaves:
```{code} yaml
Sum of all slave lengths = lord length + lord_pad1 + lord_pad2
```

One major drawback of jumbo `super_slave` elements is that the `tracking_method`
([](#s:tkm)) will, by necessity, have to be `runge_kutta`, or `time_runge_kutta` and the
`mat6_calc_method` ([](#s:xfer)) will be set to `tracking`.

Notice that the problem with edge effects for non-jumbo `super_slave` elements only occurs when
elements with nonzero fields are superimposed on top of one another. Thus, for example, one does not
need to use jumbo elements when superimposing a `marker` element.

index{field_overlaps}
Another possible way to handle overlapping fields is to use the `field_overlaps` element
parameter as discussed in [](#s:overlap).

%-----------------------------------------------------------------------------
(s:super.length)=
## Changing Element Lengths when there is Superposition
When a program is running, if `group` ([](#s:group)) or `overlay` ([](#s:overlay))
elements are used to vary the length of elements that are involved in superimposition, the results
are different from what would have resulted if instead the lengths of the elements where changed in
the lattice file. There are two reasons for this. First, once the lattice file has been parsed,
lattices can be "mangled" by adding or removing elements in a myriad of ways. This means that it
is not possible to devise a general algorithm for adjusting superimposed element lengths that
mirrors what the effect of changing the lengths in the lattice file.

Second, even if a lattice has not been mangled, an algorithm for varying lengths that is based on
the superimpose information in the lattice file could lead to unexpected results. To see this
consider the first example in Section~[](#s:super). If the length of `S` is varied in the
lattice file, the upstream edge of `S` will remain fixed at the center of `Q` which means that
the length of the `super_slave` element `Q{#`1} will be invariant. On the other hand, if
element `S` is defined by
```{code} yaml
S: solenoid, l = 8, superimpose, offset = 6
```
This new definition of `S` produces exactly the same lattice as before. However, now varying the
length of `S` will result in the center of `S` remaining fixed and the length of `Q{#`1}
will not be invariant with changes of the length of `S`. This variation in behavior could be very
confusing since, while running a program, one could not tell by inspection of the element positions
what should happen if a length were changed.

To avoid confusion, Bmad uses a simple algorithm for varying the lengths of elements involved in
superposition: The rule is that the length of the most downstream `super_slave` is varied.  With
the first example in Section~[](#s:super), the `group` `G` varying the length of `Q`
defined by:
```{code} yaml
G: group = {Q}, var = {l}
```
would vary the length of `Q{B`S} which would result in an equal variation of the length of
`S`. To keep the length of `S` invariant while varying `Q` the individual `super_slave`
lengths can be varied. Example:
```{code} yaml
G2: group = {Q{#}1, S{#}1:-1}, var = {l}
```
The definition of `G2` must be placed in the lattice file after the superpositions so that the
super slaves referred to by `G2` have been created.

In the above example there is another, cleaner, way of achieving the same result by varying the
downstream edge of `Q`:
```{code} yaml
G3: group = {Q}, var = {end_edge}
```


*) Difference from Bmad: Superposition is always done after lattice expansion.

*) Superimposing using the same given Drift as a reference element multiple times is not allowed (unlike Bmad).
Instead, superimpose a Null ele at the beginning or end of the drift and then use that as the reference.
At the end, remove the Null element

```{footbibliography}
```
