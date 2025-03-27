(c:multipass)=
# Multipassindex{multipass|hyperbf}

%-----------------------------------------------------------------------------
(s:multipass.fund)=
## Multipass Fundamentals
`Multipass` lines are a way to handle the bookkeeping when different elements being tracked
through represent the same physical element. For example, consider the case where dual ring colliding
beam machine is to be simulated. In this case the lattice file might look like:
```{code} yaml
ring1 = beamline("r1", [..., IR_region, ...])
ring2 = beamline("r2", [..., reverse(IR_region), ...])
IR_region = beamline("IR", [Q1, ....])
lat = Lattice("dual_ring", [ring1, ring2])
```
[The `reverse` construct means go through the line backwards ([](#s:ele.reverse))]
In this case, the `Q1` element in `ring1` and the
`Q1` element in `ring2` represent the same physical element.
Thus the parameters
of both the `Q1`s should be varied in tandem. This can be done automatically using `multipass`.
The use of multipass simplifies lattice and program development since the bookkeeping details are left
to the AcceleratorLattice bookkeeping routines.

index{multipass_slave}index{multipass_lord}
To illustrate how `multipass` works, consider the example of an Energy Recovery Linac (ERL) where
the beam will recirculate back through the LINAC section to recover the energy in the beam before it
is dumped. In AcceleratorLattice, this situation can simulated by designating the LINAC section as `multipass`.
The lattice file might look like:
```{code} yaml
@ele RF1 = LCavity(...)
linac = beamline["linac", [RF1, ...], multipass = true)
erl_line = beamline("erl", [linac, ..., linac])
lat = Lattice("erl", [erl_line])
rf1p2 = find_ele(lat, "RF1!mp1")
rf1p2.multipass_phase = pi
```
The beamline called `linac` is designated as `multipass`. This `linac` line appears twice in
the line `erl_line` and `erl_line` is the root line for lattice expansion.
In branch 1 of the
lattice, which will be a tracking branch, there will be two elements derived from the `RF1` element:
```{code} yaml
RF1!mp1, ..., RF1!mp2, ...
```
Since the two elements are derived from a `multipass` line, they are given unique names by adding
an `!mpN` suffix where `N` is an integer.
These types of elements are known as `multipass_slave` elements. In
addition to the `multipass_slave` elements there will be a `multipass_lord` element (that doesn't
get tracked through) called `RF1` in the `multipass_lord` branch of the lattice ([](#s:lord.slave)).
Changes to the parameters of the lord `RF1` element will be passed to the slave elements by the AcceleratorLattice
bookkeeping routines. Assuming that the phase of `RF1!mp1` gives acceleration, to make `RF1!mp2`
decelerate, the `multipass_phase` parameter of `RF1!mp2` is set to pi. This is the one parameter
that AcceleratorLattice's bookkeeping routines will not touch when transferring parameter values from `RF1` to
its slaves. Notice that the `multipass_phase` parameter had to be set after the lattice is formed
using the `expand` function ([](#s:expand)). This is true since
`RF1!mp2` does not exist before the lattice is expanded. `multipass_phase` is useful with
relative time tracking [](#s:rf.time). However, `multipass_phase` is "unphysical" and is just
a convenient way to shift the phase pass-to-pass through a given cavity. To "correctly" simulate
the recirculating beam, absolute time tracking should be used and the length of the lattice from a
cavity back to itself needs to be properly adjusted to get the desired phase advance. See the discussion
in section~[](#s:rf.time).

Multiple elements of the same name in a multipass line are considered
physically distinct. Example:
```{code} yaml
m_line = beamline("m", [A, A, B], multipass = true)
u_line = beamline("u", [m_line, m_line])
lat = Lattice("lat", [u_line])
```
In this example, branch 1 of the lattice is:
```{code} yaml
A!mp1, A!mp1, B!mp1, A!mp2, A!mp2, B!mp2
```
In the `multipass_lord` branch of the lattice there will be two multipass lords called `A` and
one another lord called `B`.
That is, there are three physically distinct elements in the lattice. The first
`A` lord controls the 1St and 4Th elements in branch 1 and the second
`A` lord controls the 2Nd and 5Th elements. If `m_line` was {em not} marked `multipass`,
branch 1 would have four `A` and two `B` elements and there would be
no lord elements.

Sublines contained in a multipass line that are themselves not marked multipass act the same as if
the elements of the subline where substituted directly in place of the subline in the containing
line. For example:
```{code} yaml
a_line = beamline("a", [A])
m_line = beamline("m", [a_line, a_line], multipass = true)
u_line = beamline("u", [m_line, m_line])
lat = Lattice("lat", [u_line])
```
In this example, `a_line`, which is a subline of the multipass `m_line`, is {em not}
designated `multipass` and the result is the same as the previous example where `m_line` was
defined to be `(A, A, B)`. That is, there will be three physical elements represented by three
multipass lords.

Multipass lines do not have to be at the same "level" in terms of nesting of lines within
lines. Additionally, multipass can be used with line reversal ([](#s:ele.reverse)). Example:
```{code} yaml
m_line = beamline("m", [A, B], multipass = true)
m2_line = beamline("m2", m_line)
@ele P = patch(...)  # Reflection patch
u_line = beamline("u", [m_line, P, reverse(m2_line)])
lat = Lattice("lat", [u_line])
```
Here the tracking part of the lattice is
```{code} yaml
A!mp1, B!mp1, ..., B!mp2 (r), A!mp2 (r)
```
The "(r)" here just denotes that the element is reversed and is not part of the name. The lattice
will have a multipass lord `A` that controls the two `A!mp n` elements and similarly with
`B`. This lattice represents the case where, when tracking,
a particle goes through the m_line in the "forward"
direction and, at the reflection patch element `P`, the coordinate system is reversed so that the particle
is then tracked in the reverse direction through the elements of `m_line` twice.
While it is possible to use reflection "{math}`-`" ([](#s:lines.wo.arg)) instead
of reversal ([](#s:ele.reverse)), reflection here does not make physical sense.  Needed
here is a reflection patch `P` ([](#s:patch)) between reversed and unreversed elements.

The procedure for how to group lattice elements into multipass slave groups which represent the same
physical element is as follows. For any given element in the lattice, this element has some line it
came from. Call this line {math}`L_0`. The {math}`L_0` line in turn may have been contained in some other line
{math}`L_1`, etc. The chain of lines {math}`L_0`, {math}`L_1`, ..., {math}`L_n` ends at some point and the last (top) line
{math}`L_n` will be one of the root lines listed in the `use` statement ([](#s:use)) in the lattice
file. For any given element in the lattice, starting with {math}`L_0` and proceeding upwards through the
chain, let {math}`L_m` be the {em first} line in the chain that is marked as `multipass`. If no such
line exists for a given element, that element will not be a multipass slave. For elements that have
an associated {math}`L_m` multipass line, all elements that have a common {math}`L_m` line and have the same
element index when {math}`L_m` is expanded are put into a multipass slave group (for a given line the
element index with respect to that line is 1 for the first element in the expanded line, the second
element has index 2, etc.).  For example, using the example above, the first element of the lattice,
`A!mp1`, has the chain:
```{code} yaml
m_line, u_line
```
The last element in the lattice, (`A!mp2`), has the chain
```{code} yaml
m_line, m2_line, u_line
```
For both elements the {math}`L_m` line is `m_line` and both elements are derived from the element with
index 1 with respect to `m_line`. Therefore, the two elements will be slaved together.

As a final example, consider the case where a subline of a multipass line is also marked
`multipass`:
```{code} yaml
a_line = beamline("a", [A], multipass = true)
m_line = beamline("m", [a_line, a_line, B], multipass = true)
u_line = beamline("u", [m_line, m_line])
lat = Lattice("lat", [u_line])
```
In this case, branch 1 of the lattice will be:
```{code} yaml
A!mp1, A!mp2, B!mp1, A!mp3, A!mp4, B!mp2
```
There will be two lord elements representing the two physically distinct elements `A` and `B`.
The `A` lord element will will control the four `A!mpN` elements in the tracking
part of the lattice. The `B` lord will control the two `B!mpN` elements in the tracking part
of the lattice.

To simplify the constructed lattice, if the set of lattice elements to slave together only contains
one element, a multipass lord is not constructed. For example:
```{code} yaml
m_line = beamline("m", [A, A, B], multipass = true)
u_line = beamline([m_line])
lat = Lattice("lat", [u_line])
```
In this example no multipass lords are constructed and the lattice is simply
```{code} yaml
A, A, B
```

It is important to note that the floor coordinates ([](#s:floor)) of the slaves of a given
multipass lord are not constrained by AcceleratorLattice to be the same. It is up to the lattice designer to make
sure that the physical positions of the slaves makes sense (that is, are the same).

%-----------------------------------------------------------------------------
(s:ref.e.multi)=
## The Reference Energy in a Multipass Line
Consider the lattice where the tracking elements are
```{code} yaml
A!mp1, C, A!mp2
```
where `A!mp1` and `A!mp2` are multipass slaves of element `A` and `C` is a `lcavity`
element with some finite voltage. In this case, the reference energy calculation ([](#s:energy))
where the reference energy of an element is inherited from the previous element, assigns differing
reference energies to `A!mp1` and `A!mp2`. In such a situation, what should be the assigned
reference energy for the multipass lord element `A`? AcceleratorLattice calculates the lord reference energy
in one of two ways. If, in the lattice file, `static_energy_ref` is set `true`,
`e_tot_ref` or `pc_ref` the value set for the multipass lord element by the User will be used.
If `static_energy_ref` is `false` (the default),
the reference energy (or reference momentum) the reference energy of the lord is set equal to the
reference energy of the first pass slave element.
The setting of `static_energy_ref` for multipass slaves is always `false`.
```{footbibliography}
```
