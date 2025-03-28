(c:construct-lat)=
# Constructing Lattices
Note:
```{code} yaml
@ele qq = Quadrupole()
bl = beamline([.., qq, ..., qq, ...], ...)
```
Here changing parameters of qq will affect the parameters of the qq's in any beamline.
However, lattice expansion constructs the lattice with copies of qq so changing the
parameters of qq will not affect any of the copies in the lattice. This is done so that
parameters in the various qq's in the lattice are independent and an therefore differ from each
other.

Branch geometry is inherited from the root line. To use a line with the "wrong" geometry, create
a new line using the old line with the "correct" geometry. EG
ln2 = beamline(ln1.name, [ln1], geometry = CLOSED)
lat = Lattice([ln2])

Note: OPEN and CLOSED are aliases for BranchGeometry.OPEN and BranchGeometry.CLOSED

* Show how to construct a Bmad replacement line using a function.

* Show how to get the effect of a Bmad List by replacing elements after expansion.

* Default name for end element is `"endN"` where N is the index of the branch.
```{footbibliography}
```
