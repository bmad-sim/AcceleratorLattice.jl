(c:design)=
# Design Decisions
This chapter discusses some of the design decisions that were made in the planning of AcceleratorLattice.
Hopefully this information will be useful as AcceleratorLattice is developed in the future.
The design of AcceleratorLattice is heavily influenced by the decades of experience constructing and maintaining
Bmad --- both in terms of what works and what has not worked.

First a clarification. The name Bmad
can be used in two senses. There is Bmad the Fortran software toolkit
that can be used to create simulation programs. But Bmad can also be used to refer to the
ecosystem of toolkit and Bmad based programs that have been developed over the years --- the
most heavily used program being Tao. In the discussion below, Bmad generally refers to the toolkit
since it is the toolkit that defines the syntax for Bmad lattice files.

paragraph{Bmad history:}
To understand Bmad it helps to understand some of the history of Bmad. The Bmad toolkit
started out as a modest project for calculating Twiss parameters and closed orbits within online control
programs for the Cornell CESR storage ring. As such, the lattice structure was simply an array
of elements. That is, early Bmad did not have the concept of interlocking branches, and tracking was very simple ---
there was only one tracking method, symplecticity was ignored and ultra-relativistic and
paraxial approximations were used.
Bmad has come a long way from the early days but design decisions made early on still haunt the Bmad
toolkit.

paragraph{Julia itself is the design language:}
One of the main problems with Bmad --- and many other simulation programs like MAD, Elegant, SAD, etc. ---
is that the design language is some custom construct with custom syntax put together by a team that
never has enough manpower. This both greatly limits the versatility of language as well as adding
the burden of developing and maintaining the language. Julia was chosen for AcceleratorLattice
due to the ability of using Julia as the design language.

There are many design decisions that flow from the fact that Julia is used for the design language
so decisions are made to follow the "Julia way".
For example, case sensitivity of names, indexing of branch element arrays starting at 1 (Bmad uses 0),
etc.

paragraph{Separation of tracking and lattice description:}
One of the first AcceleratorLattice design decisions was to separate particle tracking from the lattice description.
This was done since experience with Bmad showed that properly doing lattice bookkeeping is vastly
more complicated when tracking is involved. This is especially true when the User can choose
among multiple tracking methods for a given element and the User is free to vary the tracking method
on-the-fly.

The decision to separate lattice and tracking was also inspired by the PTC code of Etienne Forest.
The fact that Bmad did not make this separation complicated Bmad's lattice element structure,
the `ele_struct`,
to the extent that the `ele_struct` is the most complicated structure in all of Bmad. And
having complicated structures is an impediment to code sustainability.
The lack of a separation in Bmad also made bookkeeping more complicated in cases where, for example,
Twiss parameters were to be calculated under differing conditions (EG varing initial
particle positions) but the `ele_struct` can only hold Twiss parameters for one specific
condition.

paragraph{Lattice branches:}
The organization of the lattice into branches with each branch having an array of elements has
worked very well with Bmad and so is used with AcceleratorLattice. The relatively minor difference is
that with AcceleratorLattice the organization of the branches is more logical with multiple lord branches
with each lord branch containing only one type of lord.

paragraph{No Controllers:}
Bmad has control element types called `groups` and `overlays`. Elements of these types
can control the parameters of other elements.
The ability to define controllers has been tremendously useful, for example,
to simulate machine control from a control room. Nevertheless, controllers are not implemented
with AcceleratorLattice. The reason for this is that there is no need to define controllers since the Julia
language provides all the necessary tools to construct control functions that have a versatility
much greater than the ones in Bmad.

paragraph{Type stability:}
Type stability is {em not} a major concern with AcceleratorLattice. The reason being that compared to
the time needed for tracking and track analysis, lattice instantiation
and manipulation does not take an appreciable amount of time. For tracking, where computation time
is a hugh consideration, an interface layer can be
used to translate lattice parameters to a type stable form. Of much greater importance is the
flexibility of AcceleratorLattice to accomodate changing needs and software sustainability.
Hence all element, branch, and lattice structures contain a Dict (always called `pdict`) which
can store arbitrary information.

paragraph{Lattice element structure:}
All lattice element structs are very simple: They contain a single Dict and all element information
is stored within this Dict. This means that there is no restriction as to what can be stored
in an element adding custom information to an element simple.
And the ability to do customization easily is very important.

Within an element Dict, for the most part, parameters are grouped into "element group" structs.
A flattened structure, that is, without the element group structs, would be the correct strategy
if the number of possible parameters for a given element type was not as large as it is.
However, the parameterization of an element can be complicated.
For example, a field table describing the field in an element has a grid of field points plus
parameters to specify the distance between points, the frequency (if the field is oscillating), etc.
In such a case, where the number of parameters is large, and with the parameters falling into
logical groups, using substructures if preferred. Another consideration is that parameter groups
help remove the conflict that occurs when multiple parameters logically should have the same name.
For example, if an element is made up of different parts and multipole parts can have independent
misalignments, parameter groups help keep the offset parameters distinct.

paragraph{Defining multipoles using normal and skew strengths along with a tilt:}
The reason why for any order multipole there are three components,
normal, skew and tilt, that describe the field when only two would be sufficient is due convenience.
Having normal and skew components is convenient when magnet has multiple windings that control
both independently. A common case is combined horizontal and vertical steering magnets. On the
other hand, being able to "misalign" the multipole using the `tilt` component is also
useful.
```{footbibliography}
```
