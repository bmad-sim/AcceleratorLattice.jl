(c:X)=
# Electromagnetic Fields
%-----------------------------------------------------------------
(s:mag.field)=
## Magnetostatic Multipole Fields
Start with the assumption that the local magnetic field has no longitudinal component
(obviously this assumption does not work with, say, a solenoid).  Following mad, ignoring
skew fields for the moment, the vertical magnetic field along the {math}`y = 0` axis is expanded
in a Taylor series
begin{equation}
B_y(x, 0) = sum_n B_n , frac{x^n}{n!}
label{byx0b}
end{equation}
Assuming that the reference orbit is locally straight (there are correction terms if the
reference orbit is curved ([](#s:field.exact))), the field is
begin{alignat}{5}
B_x &=           &&B_1 y plus         &&B_2 , xy
&& plus && frac{1}{6} B_3 (3x^2 y - y^3) plus ldots CRNO
B_y &= B_0 plus &&B_1 x + frac{1}{2} &&B_2 (x^2 - y^2)
&& plus && frac{1}{6} B_3 (x^3 - 3x y^2) plus ldots
label{bbb}
end{alignat}
The relation between the field {math}`B_n` and the normalized field {math}`K_n` is:
begin{equation}
K_n equiv frac{q , B_n}{P_0}
label{kqlbp}
end{equation}
where {math}`q` is the charge of the reference particle (in units of the elementary charge), and {math}`P_0` is
the reference momentum (in units of eV/c).  Note that {math}`P_0/q` is sometimes written as {math}`Brho`. This
is just an old notation where {math}`rho` is the bending radius of a particle with the reference energy
in a field of strength {math}`B`. Notice that {math}`P_0` is the local reference momentum at the element which
may not be the same as the reference energy at the beginning of the lattice if there are
`lcavity` elements ([](#s:lcav)) present.

The kicks {math}`Delta p_x` and {math}`Delta p_y` that a particle experiences going through a multipole field
is
begin{alignat}{5}
Delta p_x & = frac{-q , L , B_y}{P_0} label{pqlbp1} 
& = -K_0 L ;-;
&& K_1 L , x plus
frac{1}{2} && K_2 L (y^2 - x^2) && plus
&& frac{1}{6} K_3 L (3x y^2 - x^3) plus ldots
nonumber 
Delta p_y & = frac{q , L , B_x}{P_0} label{pqlbp2} 
& =
&& K_1 L , y plus
&& K_2 L , xy && plus
&& frac{1}{6} K_3L (3x^2 y - y^3) plus ldots nonumber
end{alignat}
A positive {math}`K_1L` quadrupole component gives horizontal focusing and vertical defocusing. The
general form is
begin{align}
Delta p_x &= sum_{n = 0}^{infty} frac{K_n L}{n!}
sum_{m = 0}^{2m le n}
begin{pmatrix} n cr 2m end{pmatrix} ,
(-1)^{m+1} , x^{n-2m} , y^{2m} 
Delta p_y &= sum_{n = 0}^{infty} frac{K_n L}{n!}
sum_{m = 0}^{2m le n-1}
begin{pmatrix} n cr 2m+1 end{pmatrix} ,
(-1)^{m} , x^{n-2m-1} , y^{2m+1}
end{align}
where {math}`binom{a}{b}` ("a choose b") denotes a binomial coefficient.

The above equations are for fields with a normal component only. If a given multipole field of order
{math}`n` has normal {math}`B_n` and skew {math}`S_n` components and is rotated in the {math}`(x, y)` plane by an angle
{math}`T_n`, the magnetic field at a point {math}`(x,y)` can be expressed in complex notation as
begin{equation}
B_y(x,y) + i B_x(x,y) =
frac{1}{n!} (B_n + i S_n) , e^{-i(n+1)T_n} , e^{i n theta} , r^n
label{bib1nb}
end{equation}
where {math}`(r, theta)` are the polar coordinates of the point {math}`(x, y)`.

Note that, for compatibility with MAD, the {math}`K0L` component of a `Multipole` element rotates the
reference orbit essentially acting as a zero length bend. This is not true for multipoles of any
other type of element.

Instead of using magnitude {math}`K_n` and rotation angle {math}`theta_n`, Another representation is using
normal {math}`wt K_n` and skew {math}`wt S_n`. The conversion between the two are
begin{align}
wt K_n &= K_n , cos((n + 1) , T_n) CRNO
wt S_n &= K_n , sin((n + 1) , T_n)
end{align}

Another representation of the magnetic field used by Bmad divides the fields into normal {math}`b_n` and
skew {math}`a_n` components. In terms of these components the magnetic field for the {math}`n`Th order
multipole is
begin{equation}
frac{q , L}{P_0} , (B_y + i B_x) = (b_n + i a_n) , (x + i y)^n
label{qlpbb}
end{equation}
The {math}`a_n`, {math}`b_n` representation of multipole fields can be used in elements such as
quadrupoles, sextupoles, etc. to allow "error" fields to be represented.
The conversion between {math}`(a_n, b_n)` and {math}`(K_nL, S_nL, T_n)` is
begin{equation}
b_n + i a_n = frac{1}{n!} , (K_nL + i , S_nL) , e^{-i(n+1)T_n}
end{equation}
In the case where {math}`S_nL = 0`
begin{align}
K_n L &= n! , sqrt{a_n^2 + b_n^2} 
tan[(n+1) T_n] &= frac{-a_n}{b_n}
end{align}
To convert a normal magnet (a magnet with no skew component) into a skew magnet (a magnet with no
normal component) the magnet should be rotated about its longitudinal axis with a rotation angle of
begin{equation}
(n+1) T_n = frac{pi}{2}
end{equation}
For example, a normal quadrupole rotated by {math}`45^circ` becomes a skew quadrupole.

`Reference energy` scaling is applied if the `field_master` attribute ([](#s:field.master))
is True for an element so that the multipole values specified in the lattice file are not reference
energy normalized
begin{equation}
bigl[ a_n, b_n bigr] longrightarrow
bigl[ a_n, b_n bigr] cdot frac{q}{P_0}
label{ababq}
end{equation}

%-----------------------------------------------------------------
(s:elec.field)=
## Electrostatic Multipole Fields
Except for the `elseparator` element, Bmad specifies DC electric fields using normal
{math}`b_{en}` and skew {math}`a_{en}` components ([](#s:multip)). The potential {math}`phi_n` for the
{math}`n`Th order multipole is
begin{equation}
phi_n = -re left[ frac{b_{en} - i a_{en}}{n + 1} , frac{(x + i y)^{n+1}}{r_0^n} right]
label{pbian1}
end{equation}
where {math}`r_0` is a "measurement radius" set by the `r0_elec` attribute of an element
([](#s:multip)).

The electric field for the {math}`n`Th order multipole is
begin{equation}
E_x - i E_y = (b_{en} - i a_{en}) , frac{(x + i y)^n}{r_0^n}
label{exiey}
end{equation}
Notice that the magnetic multipole components {math}`a_n` and {math}`b_n` are normalized by the
element length, reference charge, and reference momentum (Eq{qlpbb}) while their electric
counterparts are not.

Using the paraxial approximation, The kick given a particle due to the electric field is
begin{equation}
frac{dp_x}{ds} = frac{q , E_x}{beta , P_0 , c}, qquad frac{dp_y}{ds} = frac{q , E_y}{beta , P_0 , c}
end{equation}
Where {math}`beta` is the normalized velocity.

%-----------------------------------------------------------------
(s:field.exact)=
## Exact Multipole Fields in a Bend
For static magnetic and electric multipole fields in a bend, the spacial dependence of the
field is different from multipole fields in an element with a straight geometry as given
by Eqs{qlpbb} and eq{exiey}. The analysis of the multipole fields in a bend here follows
McMillan{footcite:p}`McMillan:Multipoles`.

In the rest of this section, normalized coordinates {math}`rw = r / rho`, {math}`xw / = x /`
rho{math}`, and `yw = y / rho{math}` will be used where `rho{math}` is the bending radius of the`
reference coordinate system, {math}`r` is the distance, in the plane of the bend, from the bend
center to the observation point, {math}`x` is the distance in the plane of the from the reference
coordinates to the observation point and {math}`y` is the distance out-of-plane. With this
convention {math}`rw = 1 + xw`.

An electric or magnetic multipole can be characterized by a scalar potential {math}`phi` with
the field given by {math}`-nabla phi`.  The potential is a solution to Laplace's equation
begin{equation}
frac{1}{rw} , frac{partial}{partial , rw}
left( rw , frac{partial , phi}{partial , rw} right) +
frac{partial^2 phi}{partial , yw^2} = 0
end{equation}
As McMillian shows, it is also possible to calculate the magnetic field by constructing the
appropriate vector potential. However, from a practical point of view, it is simpler to use the
scalar potential for both the magnetic and electric fields.

Solutions to Laplace's equation can be found in form
begin{equation}
phi_{n}^r = frac{-1}{1+n} sum_{p = 0}^{2p le n+1}
begin{pmatrix} n + 1 cr 2 , p end{pmatrix} ,
(-1)^{p} , F_{n+1-2p}(rw) , yw^{2p}
label{pspn1}
end{equation}
and in the form
begin{equation}
phi_{n}^i = frac{-1}{1+n} sum_{p = 0}^{2p le n}
begin{pmatrix} n + 1 cr 2p +1 end{pmatrix} ,
(-1)^{p} , F_{n-2p}(rw) , yw^{2p+1}
label{pspn2}
end{equation}
where {math}`binom{a}{b}` ("a choose b") denotes a binomial coefficient, and {math}`n` is the order
number which can range from 0 to infinity.footnote
{
Notice that here {math}`n` is related to {math}`m` in
McMillian's paper by {math}`m = n + 1`. Also note that the {math}`phi^r` and {math}`phi^i` here have a
normalization factor that is different from McMillian.

In Eq{pspn2} the {math}`F_p(rw)` are related by
begin{equation}
F_{p+2} = (p + 1) , (p + 2) , int_1^{rw} frac{drw}{rw}
left[ int_1^{rw} drw , rw , F_{p} right]
end{equation}
with the "boundary condition":
begin{align}
F_0(rw) &= 1 CRNO
F_1(rw) &= ln , rw
end{align}
This condition ensures that the number of terms in the sums in Eqs{pspn1} and eq{pspn2}
are finite. With this condition, all the {math}`F_p` can be constructed:
begin{align}
F_1 &= ln , rw = xw - frac{1}{2}xw^2 + frac{1}{3}xw^3 - ldots CRNO
F_2 &= frac{1}{2} (rw^2 - 1) - ln rw = xw^2 - frac{1}{3}xw^3 + frac{1}{4} xw^4 - ldots CRNO
F_3 &= frac{3}{2} [-(rw^2 - 1) + (rw^2 + 1) ln rw] = xw^3 - frac{1}{2} xw^4 + frac{7}{20} xw^5 - ldots
label{ffff} 
F_4 &= 3 [ frac{1}{8} (rw^4 - 1) + frac{1}{2} (rw^2 - 1) - (rw^2 + frac{1}{2}) ln rw] =
xw^4 - frac{2}{5} xw^5 + frac{3}{10} xw^6 - ldots CRNO
&text{Etc...} nonumber
end{align}
Evaluating these functions near {math}`xw = 0` using the exact {math}`rw`-dependent functions can be
problematical due to round off error. For example, Evaluating {math}`F_4(rw)` at {math}`xw = 10^{-4}` results
in a complete loss of accuracy (no significant digits!) when using double precision numbers. In
practice, Bmad uses a Pad'e approximant for {math}`xw` small enough and then switches to the
{math}`rw`-dependent formulas for {math}`xw` away from zero.

For magnetic fields, the "real" {math}`phi_n^r` solutions will correspond to skew fields and the
"imaginary" {math}`phi_n^i` solutions will correspond to normal fields
begin{equation}
bfB = -frac{P_0}{q , L} ,
sum_{n = 0}^infty rho^n , left[ a_n , widetilde nabla phi_n^r + b_n , widetilde nabla phi_n^i right]
label{bpql}
end{equation}
where the gradient derivatives of {math}`widetilde nabla` are with respect to the normalized
coordinates. In the limit of infinite bending radius {math}`rho`, the above equations converge
to the straight line solution given in Eq{qlpbb}.

For electric fields, the "real" solutions will correspond to normal fields and the
"imaginary" solutions are used for skew fields
begin{equation}
bfE = -sum_{n = 0}^infty rho^n , left[ a_{en} , widetilde nabla phi_n^i +
b_{en} , widetilde nabla phi_n^r right]
label{enrn}
end{equation}
And this will converge to Eq{exiey} in the straight line limit.

In the vertical plane, with {math}`xw = 0`, the solutions {math}`phi_n^r` and {math}`phi_n^i` have the same
variation in {math}`yw` as the multipole fields with a straight geometry. For example, the field
strength of an {math}`n = 1` (quadrupole) multipole will be linear in {math}`yw` for {math}`xw = 0`. However, in the
horizontal direction, with {math}`yw = 0`, the multipole field will vary like {math}`dF_2/dxw` which has
terms of all orders in {math}`xw`. In light of this, the solutions {math}`phi_n^r` and {math}`phi_n^i` are
called "vertically pure" solutions.

It is possible to construct "horizontally pure" solutions as well. That is, it is possible to
construct solutions that in the horizontal plane, with {math}`yw = 0`, behave the same as the corresponding
multipole fields with a straight geometry. A straight forward way to do this, for some given
multipole of order {math}`n`, is to construct the horizontally pure solutions, {math}`psi_n^r` and {math}`psi_n^i`,
as linear superpositions of the vertically pure solutions
begin{equation}
psi_n^r = sum_{k = n}^infty C_{nk} , phi_k^r, qquad
psi_n^i = sum_{k = n}^infty D_{nk} , phi_k^i
label{p1rc}
end{equation}
with the normalizations {math}`C_{nn} = D_{nn} = 1`. The {math}`C_{nk}` and {math}`D_{nk}` are chosen, order
by order, so that {math}`psi_n^r` and {math}`psi_n^i` are horizontally pure. For the real
potentials, the {math}`C_{nk}`, are obtained from a matrix {math}`bfM` where {math}`M_{ij}` is the
coefficient of the {math}`xw^j` term of {math}`(dF_i/dxw)/i` when {math}`F_i` is expressed as an expansion in
{math}`xw` (Eq{ffff}). {math}`C_{nk}`, {math}`k = 0, ldots, infty` are the row vectors of the inverse
matrix {math}`bfM^{-1}`. For the imaginary potentials, the {math}`D_{nk}` are constructed similarly
but in this case the rows of {math}`bfM` are the coefficients in {math}`xw` for the functions {math}`F_i`.
To convert between field strength coefficients, Eqs{bpql} and eq{enrn} and Eqs{p1rc}
are combined
begin{alignat}{3}
a_n &= sum_{k = n}^infty frac{1}{rho^{k-n}} , C_{nk} , alpha_k, quad
&a_{en} &= sum_{k = n}^infty frac{1}{rho^{k-n}} , D_{nk} , alpha_{ek}, CRNO
b_n &= sum_{k = n}^infty frac{1}{rho^{k-n}} , D_{nk} , beta_k, quad
&b_{en} &= sum_{k = n}^infty frac{1}{rho^{k-n}} , D_{nk} , beta_{ek}
end{alignat}
where {math}`alpha_k`, {math}`beta_k`, {math}`alpha_{ek}`, and {math}`beta_{ek}` are the corresponding coefficients
for the horizontally pure solutions.

When expressed as a function of {math}`rw` and {math}`yw`, the vertically pure solutions {math}`phi_n` have a
finite number of terms (Eqs{pspn1} and eq{pspn2}). On the other hand, the horizontally
pure solutions {math}`psi_n` have an infinite number of terms.

The vertically pure solutions form a complete set. That is, any given field that satisfies
Maxwell's equations and is independent of {math}`z` can be expressed as a linear combination of
{math}`phi_n^r` and {math}`phi_n^i`. Similarly, the horizontally pure solutions form a complete
set. [It is, of course, possible to construct other complete sets in which the basis
functions are neither horizontally pure nor vertically pure.]

This brings up an important point. To properly simulate a machine, one must first of all
understand whether the multipole values that have been handed to you are for horizontally
pure multipoles, vertically, pure multipoles, or perhaps the values do not correspond to
either horizontally pure nor vertically pure solutions! Failure to understand this point
can lead to differing results. For example, the chromaticity induced by a horizontally
pure quadrupole field will be different from the chromaticity of a vertically pure
quadrupole field of the same strength. With Bmad, the `exact_multipoles`
([](#s:bend)) attribute of a bend is used to set whether multipole values are for
vertically or horizontally pure solutions. [Note to programmers: PTC always assumes
coefficients correspond to horizontally pure solutions. The Bmad PTC interface will
convert coefficients as needed.]

%-----------------------------------------------------------------
(s:field.map)=
## Map Decomposition of Magnetic and Electric Fields
Electric and magnetic fields can be parameterized as the sum over a number of functions
with each function satisfying Maxwell's equations. These functions are also referred to as
"maps", "modes", or "terms". Bmad has three parameterizations:
```{code} yaml
Cartesian Map              ! [](#s:cart.map.phys).
Cylindrical Map            ! [](#s:cylind.map.phys)
Generalized Gradient Map   ! [](#s:gen.grad.phys)
```
These parameterizations are three of the four `field map` parameterizations that Bmad
defines [](#s:fieldmap).

The `Cartesian map` decomposition involves a set of terms, each term a solution the
Laplace equation solved using separation of variables in Cartesian coordinates. This
decomposition can be used for DC but not AC fields. See [](#s:cart.map.phys).
for more details. The syntax for specifying the `Cartesian map` decomposition
is discussed in [](#s:cart.map).

The `cylindrical map` decomposition can be used for both DC and AC fields. See
[](#s:cylind.map.phys) for more details. The syntax for specifying the `cylindrical map`
decomposition is discussed in [](#s:cylind.map).

The `generalized gradient map` start with the cylindrical map decomposition but then express the
field using coefficients derived from an expansion of the scalar potential in powers of the radius
([](#s:gen.grad.phys)).

%-----------------------------------------------------------------
(s:cart.map.phys)=
## Cartesian Map Field Decomposition
Electric and magnetic fields can be parameterized as the sum over a number of functions
with each function satisfying Maxwell's equations. These functions are also referred to as
"maps", "modes", or "terms". Bmad has two types. The "`Cartesian`"
decomposition is explained here. The other type is the `cylindrical` decomposition
([](#s:cylind.map.phys)).

The `Cartesian` decomposition implemented by Bmad involves a set of terms, each
term a solution the Laplace equation solved using separation of variables in Cartesian
coordinates. This decomposition is for DC electric or magnetic fields. No AC Cartesian Map
decomposition is implemented by Bmad. In a lattice file, a `Cartesian` map is specified using
the `cartesian_map` attribute as explained in Sec.~[](#s:cart.map).

The `Cartesian` decomposition is modeled using an extension of the method of Sagan,
Crittenden, and Rubin{footcite:p}`Sagan:wiggler`. In this decomposition, the magnetic(or electric
field is written as a sum of terms {math}`B_i` (For concreteness the symbol {math}`B_i` is used but
the equations below pertain equally well to both electric and magnetic fields) with:
begin{equation}
bfB(x,y,z) = sum_i bfB_i(x, y, z; A, k_x, k_y, k_z, x_0, y_0, phi_z, family)
end{equation}
Each term {math}`B_i` is specified using seven numbers {math}`(A, k_x, k_y, k_z,`
x_0, y_0, phi_z){math}` and a switch called `family` which can be one of:`
```{code} yaml
x,  qu
y,  sq
```
Roughly, taking the offsets {math}`x_0` and {math}`y_0` to be zero (see the equations below), the `x`
`family` gives a field on-axis where the {math}`y` component of the field is zero. that is, the `x`
family is useful for simulating, say, magnetic vertical bend dipoles. The `y` `family` has a
field that on-axis has no {math}`x` component. The `qu` `family` has a magnetic quadrupole like
(which for electric fields is skew quadrupole like) field on-axis and the `sq` `family` has a
magnetic skew quadrupole like field on-axis. Additionally, assuming that the {math}`x_0` and {math}`y_0` offsets
are zero, the `sq` family, unlike the other three families, has a nonzero on-axis {math}`z` field
component.

Each family has three possible forms These are designated as "`hyper-y`",
"`hyper-xy`", and "`hyper-x`".

For the `x` `family` the `hyper-y` form is:
begin{alignat}{4}
B_x &=  &&A , &dfrac{k_x}{k_y} & cos(kxx) , cosh(kyy) , cos(kzz) CRNEG
B_y &=  &&A , &                 & sin(kxx) , sinh(kyy) , cos(kzz) CRNEG
B_s &= -&&A , &dfrac{k_z}{k_y} & sin(kxx) , cosh(kyy) , sin(kzz) label{cm1} 
&&&&& text{with} ,, k_y^2 = k_x^2 + k_z^2 nonumber
end{alignat}
The `x` `family` `hyper-xy` form is:
begin{alignat}{4}
B_x &=  &&A , &dfrac{k_x}{k_z} & cosh(kxx) , cosh(kyy) , cos(kzz) CRNEG
B_y &=  &&A , &dfrac{k_y}{k_z} & sinh(kxx) , sinh(kyy) , cos(kzz) CRNEG
B_s &= -&&A , &                 & sinh(kxx) , cosh(kyy) , sin(kzz) label{cm3} 
&&&&& text{with} ,, k_z^2 = k_x^2 + k_y^2 nonumber
end{alignat}
And the `x` `family` `hyper-x` form is:
begin{alignat}{4}
B_x &=  &&A , &                 & cosh(kxx) , cos(kyy) , cos(kzz) CRNEG
B_y &= -&&A , &dfrac{k_y}{k_x} & sinh(kxx) , sin(kyy) , cos(kzz) CRNEG
B_s &= -&&A , &dfrac{k_z}{k_x} & sinh(kxx) , cos(kyy) , sin(kzz) label{cm5} 
&&&&& text{with} ,, k_x^2 = k_y^2 + k_z^2 nonumber
end{alignat}

The relationship between {math}`k_x`, {math}`k_y`, and {math}`k_z` ensures that
Maxwell's equations are satisfied. Notice that which form
`hyper-y`, `hyper-xy`, and `hyper-x` a particular {math}`bfB_i`
belongs to can be computed by Bmad by looking at the values of {math}`k_x`,
{math}`k_y`, and {math}`k_z`.

Using a compact notation where {math}`Ch equiv cosh`, subscript {math}`x` is {math}`kxx`, subscript {math}`z`
is {math}`kzz`, etc., the `y` `family` of forms is:
begin{alignat}{7}
& text{Form} quad  && text{hyper-y} quad && text{hyper-xy} quad && text{hyper-x} quad CRNO
& B_x
&-& A , dfrac{k_x}{k_y} , Se_x , Sh_y , Ce_z quad
& & A , dfrac{k_x}{k_z} , Sh_x , Sh_y , Ce_z quad
& & A , hphphp          , Sh_x , Se_y , Ce_z quad CRNO
& B_y
& & A , hphphp          , Ce_x , Ch_y , Ce_z quad
& & A , dfrac{k_y}{k_z} , Ch_x , Ch_y , Ce_z quad
& & A , dfrac{k_y}{k_x} , Ch_x , Ce_y , Ce_z quad label{family.y} 
& B_z
&-& A , dfrac{k_z}{k_y} , Ce_x , Sh_y , Se_z quad
&-& A , hphphp          , Ch_x , Sh_y , Se_z quad
&-& A , dfrac{k_z}{k_x} , Ch_x , Se_y , Se_z quad CRNO
& text{with}
&& k_y^2 = k_x^2 + k_z^2
&& k_z^2 = k_x^2 + k_y^2
&& k_x^2 = k_y^2 + k_z^2 nonumber
end{alignat}

the `qu` `family` of forms is:
begin{alignat}{7}
& text{Form} quad  && text{hyper-y} quad && text{hyper-xy} quad && text{hyper-x} quad CRNO
& B_x
& & A , dfrac{k_x}{k_y} , Ce_x , Sh_y , Ce_z quad
& & A , dfrac{k_x}{k_z} , Ch_x , Sh_y , Ce_z quad
& & A , hphphp          , Ch_x , Se_y , Ce_z quad CRNO
& B_y
& & A , hphphp          , Se_x , Ch_y , Ce_z quad
& & A , dfrac{k_y}{k_z} , Sh_x , Ch_y , Ce_z quad
& & A , dfrac{k_y}{k_x} , Sh_x , Ce_y , Ce_z quad 
& B_z
&-& A , dfrac{k_z}{k_y} , Se_x , Sh_y , Se_z quad
&-& A , hphphp          , Sh_x , Sh_y , Se_z quad
&-& A , dfrac{k_z}{k_x} , Sh_x , Se_y , Se_z quad CRNO
& text{with}
&& k_y^2 = k_x^2 + k_z^2
&& k_z^2 = k_x^2 + k_y^2
&& k_x^2 = k_y^2 + k_z^2 nonumber
end{alignat}

the `sq` `family` of forms is:
begin{alignat}{7}
& text{Form} quad  && text{hyper-y} quad && text{hyper-xy} quad && text{hyper-x} quad CRNO
& B_x
&-& A , dfrac{k_x}{k_y} , Se_x , Ch_y , Ce_z quad
& & A , dfrac{k_x}{k_z} , Sh_x , Ch_y , Ce_z quad
&-& A , hphphp          , Sh_x , Ce_y , Ce_z quad CRNO
& B_y
& & A , hphphp          , Ce_x , Sh_y , Ce_z quad
& & A , dfrac{k_y}{k_z} , Ch_x , Sh_y , Ce_z quad
& & A , dfrac{k_y}{k_x} , Ch_x , Se_y , Ce_z quad label{bsq} 
& B_z
&-& A , dfrac{k_z}{k_y} , Ce_x , Ch_y , Se_z quad
&-& A , hphphp          , Ch_x , Ch_y , Se_z quad
& & A , dfrac{k_z}{k_x} , Ch_x , Ce_y , Se_z quad CRNO
& text{with}
&& k_y^2 = k_x^2 + k_z^2
&& k_z^2 = k_x^2 + k_y^2
&& k_x^2 = k_y^2 + k_z^2 nonumber
end{alignat}


The singular case where {math}`k_x = k_y = k_z = 0` is not allowed. If a uniform field is needed, a term
with very small {math}`k_x`, {math}`k_y`, and {math}`k_z` can be used. Notice that since {math}`k_y` must be non-zero for
the `hyper-y` forms (remember, {math}`k_y^2 = k_x^2 + k_z^2` for these forms and not all {math}`k`'s can be
zero), and {math}`k_z` must be non-zero for the `hyper-xy` forms, and {math}`k_x` must be nonzero for the
`hyper-x` forms. The magnetic field is always well defined even if one of the {math}`k`'s is zero.

Note: The vector potential for these fields is given in [](#s:wiggler.std).

%-----------------------------------------------------------------
(s:cylind.map.phys)=
## Cylindrical Map Decomposition
Electric and magnetic fields can be parameterized as the sum over a number of functions with each
function satisfying Maxwell's equations. These functions are also referred to as "maps",
"modes", or "terms". Bmad has two types. The "`cylindrical`" decomposition is explained
here. The other type is the `Cartesian` decomposition ([](#s:cylind.map.phys)).

In a lattice file, a `cylindrical` map is specified using the `cylindrical_map` attribute as
explained in Sec.~[](#s:cylind.map).

The `cylindrical` decomposition takes one of two forms depending upon whether the fields are time
varying or not. The DC decomposition is explained in Sec.~[](#s:cylind.dc) while the RF
decomposition is explained in Sec.~[](#s:cylind.ac).

%-----------------------------------------------------------------
(s:cylind.dc)=
## DC Cylindrical Map Decomposition
The DC `cylindrical` parametrization used by Bmad essentially follows Venturini et
al.{footcite:p}`Venturini:LHC-Quads`. See Section~[](#s:fieldmap) for details on the syntax used to cylindrical
maps in Bmad. The electric and magnetic fields are both described by a scalar potentialfootnote
{
Notice the negative sign here and in Eq{psps1k} compared to Venturini et al.{footcite:p}`Venturini:LHC-Quads`.
This is to keep the definition of the electric scalar potential {math}`psi_E` consistent with the normal
definition.
begin{equation}
bfB = -nabla , psi_B, qquad bfE = -nabla , psi_E
label{bpep}
end{equation}
The scalar potentials both satisfy the Laplace equation {math}`nabla^2 , psi = 0`.
The scalar potentials are decomposed as a sum of modes indexed by an integer {math}`m`
begin{equation}
psi_B = re left[ sum_{m = 0}^infty , psi_{Bm} right]
end{equation}
[Here and below, only equations for the magnetic field will be shown. The equations for the electric
fields are similar.] The {math}`psi_{Bm}` are decomposed in {math}`z` using a discrete Fourier
sum.footnote
{
Venturini uses a continuous Fourier transformation but Bmad uses a discrete
transformation so that only a finite number of coefficients are needed.
Expressed in cylindrical coordinates the decomposition of {math}`psi_{Bm}` is
begin{equation}
psi_{Bm} = sum_{n=-N/2}^{N/2-1} psi_{Bmn} =
sum_{n=-N/2}^{N/2-1} frac{-1}{k_n} , e^{i , k_n , z} ,
cos (m , theta - theta_{0m}) , b_m(n) , I_m(k_n , rho)
label{psps1k}
end{equation}
where {math}`I_m` is a modified Bessel function of the first kind, and the
{math}`b_m(n)` are complex coefficients. [For electric fields, {math}`e_m(n)` is
substituted for {math}`b_m(n)`] In Eq{psps1k} {math}`k_n` is
given by
begin{equation}
k_n = frac{2 pi , n}{N , dz}
end{equation}
where {math}`N` is the number of "sample points", and {math}`dz` is the longitudinal "distance between
points". That is, the above equations will only be accurate over a longitudinal length {math}`(N-1)`
, dz{math}`. Note: Typically the sum in Eq{psps1k} and other equations below runs from `0{math}` to `N-1{math}`.`
Using a sum from {math}`-N/2` to {math}`N/2-1` gives exactly the same field at the sample points ({math}`z = 0, dz,`
2,ds, ldots{math}`) and has the virtue that the field is smoother in between.`

The field associated with {math}`psi_{Bm}` is for {math}`m = 0`:
begin{align}
B_rho &= re left[
sum_{n=-N/2}^{N/2-1} e^{i , k_n , z} , b_0(n) ,
I_1(k_n , rho) right] CRNO
B_theta &= 0 
B_z &= re left[
sum_{n=-N/2}^{N/2-1} i , e^{i , k_n , z} , b_0(n) ,
I_0(k_n , rho) right]
nonumber
end{align}

And for {math}`m neq 0`:
begin{align}
B_rho &= re left[
sum_{n=-N/2}^{N/2-1} frac{1}{2} , e^{i , k_n , z} ,
cos (m , theta - theta_{0m}) , b_m(n) ,
Big[ I_{m-1}(k_n , rho) + I_{m+1}(k_n , rho) Big] right] CRNO
B_theta &= re left[
sum_{n=-N/2}^{N/2-1} frac{-1}{2} , e^{i , k_n , z} ,
sin (m , theta - theta_{0m}) , b_m(n) ,
Big[ I_{m-1}(k_n , rho) - I_{m+1}(k_n , rho) Big] right] 
B_z &= re left[
sum_{n=-N/2}^{N/2-1} i , e^{i , k_n , z} ,
cos (m , theta - theta_{0m}) , b_m(n) ,
I_m(k_n , rho) right]
nonumber
end{align}

While technically {math}`psi_{Bm0}` is not well defined due to the {math}`1/k_n` factor that is present, the
field itself is well behaved. Mathematically, Eq{psps1k} can be corrected if, for {math}`n = 0`, the term
{math}`I_m(k_n , rho) / k_n` is replaced by
begin{equation}
frac{I_m(k_0 , rho)}{k_0} rightarrow
begin{cases}
rho   &text{if } m = 0 
rho/2 &text{if } m = 1 
0      &text{otherwise}
end{cases}
end{equation}

The magnetic vector potential for {math}`m = 0` is constructed such that only {math}`A_theta` is non-zero
begin{align}
A_rho &= 0 CRNO
A_theta &= re left[
sum_{n=-N/2}^{N/2-1} frac{i}{k_n} , e^{i , k_n , z} , b_0(n) , I_1(k_n , rho) right] 
A_z    &= 0 nonumber
end{align}
For {math}`m ne 0`, the vector potential is chosen so that {math}`A_theta` is zero.
begin{align}
A_rho &= re left[
sum_{n=-N/2}^{N/2-1} frac{-i , rho}{2 , m} , e^{i , k_n , z} ,
cos (m , theta - theta_{0m}) , b_m(n) ,
Big[ I_{m-1}(k_n , rho) - I_{m+1}(k_n , rho) Big] right] CRNO
A_theta &= 0 
A_z    &= re left[
sum_{n=-N/2}^{N/2-1} frac{-i , rho}{m} , e^{i , k_n , z} ,
cos (m , theta - theta_{0m}) , b_m(n) ,
I_m(k_n , rho) right] nonumber
end{align}

Note: The description of the field using `"generalized gradients"`{footcite:p}`Newton:map` is similar to
the above equations. The difference is that, with the generalized gradient formalism, terms in
{math}`theta` and {math}`rho` are expanded in a Taylor series in {math}`x` and {math}`y`.

%-----------------------------------------------------------------
(s:cylind.ac)=
## AC Cylindrical Map Decomposition
For RF fields, the `cylindrical` mode parametrization used by Bmad essentially
follows Abell{footcite:p}`Abell:RF-maps`. The electric field is the real part of the complex field
begin{equation}
bfE({bf r}) = sum_{j=1}^M , bfE_j({bf r}) , exp[{-2 pi i , (f_j , t + phi_{0j})}]
label{eseei}
end{equation}
where {math}`M` is the number of modes. Each mode satisfies the vector Helmholtz
equation
begin{equation}
nabla^2 bfE_j + k_{tj}^2 , bfE_j = 0
label{bke}
end{equation}
where {math}`k_{tj} = 2 , pi , f_j/c` with {math}`f_j` being the mode frequency.

The individual modes vary azimuthally as {math}`cos(m , theta - theta_0)` where {math}`m` is a non-negative
integer.  [in this and in subsequent equations, the mode index {math}`j` has been dropped.]  For the {math}`m =`
0{math}` modes, there is an accelerating mode whose electric field is in the form`
begin{align}
E_rho({bf r}) &= sum_{n=-N/2}^{N/2-1} -e^{i , k_n , z} ,
i , k_n , e_0(n) , wt I_1(kappa_n, rho) CRNO
E_theta({bf r}) &= 0 
E_z({bf r}) &= sum_{n=-N/2}^{N/2-1}e^{i , k_n , z} ,
e_0(n) , wt I_0(kappa_n, rho) nonumber
end{align}
where {math}`wt I_m` is
begin{equation}
wt I_m (kappa_n, rho) equiv frac{I_m(kappa_n , rho)}{kappa_n^m}
end{equation}
with {math}`I_m` being a modified Bessel function first kind, and {math}`kappa_n` is given by
begin{equation}
kappa_n = sqrt{k_n^2 - k_t^2} =
begin{cases}
sqrt{k_n^2 - k_t^2} & |k_n| > k_t 
-i , sqrt{k_t^2 - k_n^2} & k_t > |k_n|
end{cases}
end{equation}
with
begin{equation}
k_n = frac{2 pi , n}{N , dz}
end{equation}
{math}`N` is the number of points where {math}`E_{zc}` is evaluated, and {math}`dz` is
the distance between points. The length of the field region is {math}`(N-1) , dz`. When
{math}`kappa_n` is imaginary, {math}`I_m(kappa_n , rho)` can be evaluated
through the relation
begin{equation}
I_m(-i , x) = i^{-m} , J_m(x)
end{equation}
where {math}`J_m` is a Bessel function of the first kind.
The {math}`e_0` coefficients can be obtained given knowledge of the field at some radius {math}`R` via
begin{align}
e_0(n) &= frac{1}{wt I_0(kappa_n, R)} , frac{1}{N} , sum_{p=0}^{N-1}
e^{-2 pi i n p / N} , E_{z}(R, p , dz)
end{align}

The non-accelerating {math}`m = 0` mode has an electric field in the form
begin{align}
E_rho({bf r}) &= E_z({bf r}) = 0 CRNO
E_theta({bf r}) &= sum_{n=-N/2}^{N/2-1}e^{i k_n z} ,
b_0(n) , wt I_1(kappa_n, rho)
end{align}
where the {math}`b_0` coefficients can be obtained given knowledge of the field at some radius {math}`R` via
begin{equation}
b_0(n) = frac{1}{wt I_1(kappa_n, R)} , frac{1}{N} , sum_{p=0}^{N-1}
e^{-2 pi i , n , p / N} , E_{theta}(R, p , dz)
end{equation}

For positive {math}`m`, the electric field is in the form
begin{align}
E_rho({bf r}) &= sum_{n=-N/2}^{N/2-1}
-i , e^{i , k_n , z} ,
left[
k_n , e_m(n) , wt I_{m+1}(kappa_n, rho) +
b_m(n) , frac{wt I_m(kappa_n, rho)}{rho}
right]
cos(m , theta - theta_{0m}) CRNO
E_theta({bf r}) &= sum_{n=-N/2}^{N/2-1}
-i , e^{i , k_n , z} ,
left[
k_n , e_m(n) , wt I_{m+1}(kappa_n, rho) , + right. 
& left. qquad qquad qquad qquad qquad qquad
b_m(n) , left( frac{wt I_m(kappa_n, rho)}{rho} -
frac{1}{m} , wt I_{m-1}(kappa_n, rho) right)
right]
sin(m , theta - theta_{0m}) CRNO
E_z({bf r}) &= sum_{n=-N/2}^{N/2-1}e^{i , k_n , z} ,
e_m(n) , wt I_m(kappa_n, rho) cos(m , theta - theta_{0m}) nonumber
end{align}
The `e_m` and `b_m` coefficients can be obtained given knowledge of the field at some radius {math}`R` via
begin{align}
e_m(n) &= frac{1}{wt I_m(kappa_n, R)} , frac{1}{N} , sum_{p=0}^{N-1}
e^{-2 , pi , i , n , p / N} , E_{zc}(R, p , dz) CRNO
b_m(n) &= frac{R}{wt I_m(kappa_n, R)} left[
frac{1}{N} , sum_{p=0}^{N-1}
i , e^{-2 , pi , i , n , p / N} , E_{rho c}(R, p , dz) -
k_n , e_m(n) , wt I_{m+1}(kappa_n, R)
right]
end{align}
where {math}`E_{rho c}`, {math}`E_{theta s}`, and {math}`E_{z c}` are defined by
begin{align}
E_rho(R, theta, z) &= E_{rho c}(R, z) , cos(m , theta - theta_{0m}) CRNO
E_theta(R, theta, z) &= E_{theta s}(R, z) , sin(m , theta - theta_{0m}) 
label{erpze}
E_z(R, theta, z)    &= E_{z c}(R, z)    , cos(m , theta - theta_{0m}) nonumber
end{align}

The above mode decomposition was done in the gauge where the scalar potential {math}`psi` is zero. The
electric and magnetic fields are thus related to the vector potential {math}`bfA` via
begin{equation}
bfE = -partial_t , bfA, qquad bfB = nabla times bfA
end{equation}
Using Eq{eseei}, the vector potential can be obtained from the electric field via
begin{equation}
bfA_j = frac{-i , bfE_j}{2 , pi , f_j}
label{aiew}
end{equation}

Symplectic tracking through the RF field is discussed in Section~[](#s:symp.track).  For the
fundamental accelerating mode, the vector potential can be analytically integrated using the
identity
begin{equation}
int dx ,frac{x , I_1 (a , sqrt{x^2+y^2})}{sqrt{x^2+y^2}}  =
frac{1}{a} , I_0 (a , sqrt{x^2+y^2})
end{equation}

%-----------------------------------------------------------------
(s:gen.grad.phys)=
## Generalized Gradient Map Field Modeling
Bmad has a number of `field map` models that can be used to model electric or magnetic fields
([](#s:fieldmap)). One model involves what are called `generalized gradients`{footcite:p}`Venturini:magmaps`.
This model is restricted to modeling DC magnetic or electric fields. In a lattice file, the
generalized gradient field model is specified using the `gen_grad_map` attribute as explained
in Sec.~[](#s:gen.grad.map).

The electric and magnetic fields are both described by a scalar potentialfootnote
{
Notice the negative sign here and in Eq{ppmpp} compared to Venturini et al.{footcite:p}`Venturini:magmaps`.
This is to keep the definition of the electric scalar potential {math}`psi_E` consistent with the normal
definition.
begin{equation}
bfB = -nabla , psi_B, qquad bfE = -nabla , psi_E
label{bpep2}
end{equation}
The scalar potential is then decomposed into azimuthal components
begin{equation}
psi = sum_{m = 1}^infty psi_{m,s} , sin(m theta) + sum_{m = 0}^infty psi_{m,c} , cos(m theta)
end{equation}
where the {math}`psi_{m,alpha}` ({math}`alpha = c,s`) are characterized by a using functions
{math}`C_{m,alpha}(z)` which are functions along the longitudinal {math}`z`-axis.
begin{equation}
psi_{m,alpha} = sum_{n = 0}^infty frac{(-1)^{n+1} m!}{4^n , n! , (n+m)!}
, rho^{2n+m} , C_{m,alpha}^{[2n]}(z)
label{ppmpp}
end{equation}
The notation {math}`[2n]` indicates the {math}`2n`Th derivative of {math}`C_{m,alpha}(z)`.

From Eq{ppmpp} the field is given by
begin{align}
B_rho   &= sum_{m = 1}^{infty} sum_{n = 0}^infty frac{(-1)^n , m! , (2n+m)}{4^n , n! , (n+m)!}
rho^{2n+m-1} left[ C^{[2n]}_{m,s}(z) , sin mtheta + C^{[2n]}_{m,c}(z) , cos mtheta right] + CRNO
& hspace{25 em} sum_{n = 1}^infty frac{(-1)^n , 2n}{4^n n! , n!} rho^{2n-1} , C^{[2n]}_{0,c}(z) CRNO
B_theta &= sum_{m = 1}^{infty} sum_{n = 0}^infty frac{(-1)^n , m! , m}{4^n , n! , (n+m)!}
rho^{2n+m-1} left[ C^{[2n]}_{m,s}(z) , cos mtheta - C^{[2n]}_{m,c}(z) , sin mtheta right] 
B_z      &= sum_{m = 0}^{infty} sum_{n = 0}^infty frac{(-1)^n , m!}{4^n , n! , (n+m)!}
rho^{2n+m} left[ C^{[2n+1]}_{m,s}(z) , sin mtheta + C^{[2n+1]}_{m,c}(z) , cos mtheta right] nonumber
end{align}
Even though the scalar potential only involves even derivatives of {math}`C_{m,alpha}`, the field is
dependent upon the odd derivatives as well. The multipole index {math}`m` is such that {math}`m = 0` is for
solenoidal fields, {math}`m = 1` is for dipole fields, {math}`m = 2` is for quadrupolar fields, etc. The
`sin`--like generalized gradients represent normal (non-skew) fields and the `cos`--like one
represent skew fields. The on-axis fields at {math}`x=y=0` are given by:
begin{equation}
(B_x, B_y, B_z) = (C_{1,c}, C_{1,s}, -C^{[1]}_{0,c})
end{equation}

The magnetic vector potential for {math}`m = 0` is constructed such that only {math}`A_theta` is non-zero
begin{align}
A_rho   &= 0 CRNO
A_theta &= sum_{n=1}^infty
frac{(-1)^{n+1} , 2n}{4^n , n! , n!} rho^{2n-1} , C_{0,c}^{[2n-1]} 
A_z      &= 0 nonumber
end{align}
For {math}`m ne 0`, the vector potential is chosen so that {math}`A_theta` is zero.
begin{align}
A_rho   &= sum_{m = 1}^{infty} sum_{n=0}^infty
frac{(-1)^{n} , (m-1)!}{4^n , n! , (n+m)!} rho^{2n+m+1} ,
left[ C_{m,s}^{[2n+1]} cos(m theta) - C_{m,c}^{[2n+1]} , sin(m theta) right] CRNO
A_theta &= 0 
A_z      &= sum_{m = 1}^{infty} sum_{n=0}^infty
frac{(-1)^n , (m-1)! , (2n+m)}{4^n , n! , (n+m)!} rho^{2n+m} ,
left[ -C_{m,s}^{[2n]} cos(m theta) + C_{m,c}^{[2n]} , sin(m theta) right]
nonumber
end{align}

The functions {math}`C_{m,alpha}(z)` are characterized by specifying {math}`C_{m,alpha}(z_i)` and derivatives
at equally spaced points {math}`z_i`, up to some maximum derivative order {math}`N_{m,alpha}` chosen by the
user. Interpolation is done by constructing an interpolating polynomial ("non-smoothing spline")
for each GG of order {math}`2N_{m,alpha}+1` for each
interval {math}`[z_i, z_{i+1}]` which has the correct derivatives from {math}`0` to {math}`N_{m,alpha}` at points {math}`z_i` and
{math}`z_{i+1}`. The coefficients of the interpolating polynomial are easily calculated by inverting the
appropriate matrix equation.

The advantages of a generalized gradient map over a cylindrical or Cartesian map decomposition come
from the fact that with generalized gradients the field at some point {math}`(x,y,z)` is only dependent
upon the value of {math}`C_{m,alpha}(z)` and derivatives at points {math}`z_i` and {math}`z_{i+1}` where {math}`z` is in
the interval {math}`[z_i, z_{i+1}]`. This is in contrast to the cylindrical or Cartesian map decomposition
where the field at any point is dependent upon {em all} of the terms that characterize the
field. This "`locality`" property of generalized gradients means that calculating coefficients
is easier (the calculation of {math}`C_{m,alpha}(z)` at {math}`z_i` can be done using only the field near {math}`z_i`
independent of other regions) and it is easier to ensure that the field goes to zero at the
longitudinal ends of the element. Additionally, the evaluation is faster since only coefficients to
either side of the evaluation point contribute. The disadvantage of generalized gradients is that
since the derivatives are truncated at some order {math}`N_{m,alpha}`, the resulting field does not satisfy
Maxwell's equations with the error as a function of radius scaling with the power {math}`rho^{m+N_{m,alpha}}`.

It is sometimes convenient to express the fields in terms of Cartesian coordinates. For sine like
even derivatives {math}`C_{m,s}^{[2n]}` the conversion is
begin{align}
left( B_x, B_y right) &= left( costheta , B_rho - sintheta , B_theta, ,
sintheta , B_rho + costheta , B_theta right) CRNO
&= frac{(-1)^n , m!}{4^n n! , (n+m)!} , C_{m,s}^{[2n]} , Big[ (n+m) , (x^2 + y^2)^n ,
left( S_{xy}(m-1), , C_{xy}(m-1) right) , +
label{bbtb} 
&hspace{13em}  n , (x^2 + y^2)^{n-1} ,
left( S_{xy}(m+1), , -C_{xy}(m+1) right) Big] nonumber
end{align}
and for the sine like odd derivatives {math}`C_{m,s}^{[2n+1]}`
begin{equation}
B_z = frac{(-1)^n , m!}{4^n n! , (n+m)!}
(x^2 + y^2)^n , C^{[2n+1]}_{m,s}(z) , S_{xy}(m)
end{equation}
where the last term in Eq{bbtb} is only present for {math}`n > 0`.
begin{align}
S_{xy}(m) &equiv rho^m , sin mtheta =
sum_{r=0}^{2r le m-1} (-1)^r begin{pmatrix} m cr 2r+1 end{pmatrix} ,
x^{m-2r-1} , y^{2r+1} CRNO
C_{xy}(m) &equiv rho^m , cos mtheta =
sum_{r=0}^{2r le m} (-1)^r begin{pmatrix} m cr 2r end{pmatrix} ,
x^{m-2r} , y^{2r}
end{align}
The conversion for the cosine like derivatives is:
begin{align}
left( B_x, B_y right) &=
frac{(-1)^n , m!}{4^n n! , (n+m)!} , C_{m,c}^{[2n]} , Big[ (n+m) , (x^2 + y^2)^n ,
left( C_{xy}(m-1), , -S_{xy}(m-1) right) , + CRNO
&hspace{13em}  n , (x^2 + y^2)^{n-1} ,
left( C_{xy}(m+1), , S_{xy}(m+1) right) Big] 
B_z &= frac{(-1)^n , m!}{4^n n! , (n+m)!}
(x^2 + y^2)^n , C^{[2n+1]}_{m,c}(z) , C_{xy}(m) nonumber
end{align}

%-----------------------------------------------------------------
(s:rf.fields)=
## RF fields
The following describes the how RF fields are calculated when the `field_calc`
attribute of an RF element is set to `bmad_standard`.footnote
{
Notice that the equations here are only relavent with the `tracking_method` for an RF element set
to a method like `runge_kutta` where tracking through the field of an element is done.  For
`bmad_standard` tracking, Equations for `lcavity` tracking are shown in [](#s:lcavity.std)
and `rfcavity` tracking in [](#s:rfcavity.std).
Also see Section~[](#s:rf.fringe) for how fringe fields are calculated.

With `cavity_type` set to `traveling_wave`, the setting of `longitudinal_mode` is ignored
and the field is given by
begin{align}
E_s(r, phi, s, t) &= G , cosbigl( omega , t - k , s + 2 , pi , phi bigr) CRNO
E_r(r, phi, s, t) &= -frac{r}{2} , G , k , sinbigl( omega , t - k , s + 2 , pi , phi bigr) 
B_phi(r, phi, s, t) &= -frac{r}{2 , c} , G , k , sinbigl( omega , t - k , s + 2 , pi , phi bigr) nonumber
label{egot}
end{align}
where {math}`G` is the accelerating gradient, {math}`k = omega / c` is the wave number with {math}`omega` being the
RF frequency.

For standing wave cavities, with `cavity_type` set to `standing_wave`, the RF fields are
modeled as {math}`N` half-wave cells, each having a length of {math}`lambda/2` where {math}`lambda = 2 , pi / k`
is the wavelength. If the length of the RF element is not equal to the length of {math}`N` cells, the
"active region" is centered in the element and the regions to either side are treated as field
free.

The field in the standing wave cell is modeled either with a {math}`p = 0` or {math}`p = 1` longitudinal mode
(set by the `longitudinal_mode` element parameter). The {math}`p = 1` longitudinal mode models the
fields as a pillbox with the transverse wall at infinity as detailed in Chapter 3, Section VI of
reference {footcite:p}`Lee:Physics`
begin{align}
E_s(r, phi, s, t)    &= 2 , G ,                 cos(k , s) , cos(omega , t + 2 , pi , phi) CRNO
E_r(r, phi, s, t)    &= r , G , k ,            sin(k , s) , cos(omega , t + 2 , pi , phi) 
B_phi(r, phi, s, t) &= -frac{r}{c} , G , k , cos(k , s) , sin(omega , t + 2 , pi , phi) nonumber
label{egot2}
end{align}
The overall factor of 2 in the equation is present to ensure that an ultra-relativistic particle
entering with {math}`phi = 0` will experience an average gradient equal to {math}`G`.

For the {math}`p = 0` longitudinal mode (which is the default), a "pseudo TM{math}`_{010}`" mode is used that
has the correct symmetry:
begin{align}
E_s(r, phi, s, t)    &= 2 , G ,                sin(k , s) , sin(omega , t + 2 , pi , phi) CRNO
E_r(r, phi, s, t)    &= -r , G , k ,          cos(k , s) , sin(omega , t + 2 , pi , phi) 
B_phi(r, phi, s, t) &= frac{r}{c} , G , k , sin(k , s) , cos(omega , t + 2 , pi , phi) nonumber
label{egot3}
end{align}
```{footbibliography}
```
