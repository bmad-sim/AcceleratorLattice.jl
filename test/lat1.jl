@ele begin_ln2 = BeginningEle(pc_ref = 1e7, species_ref = species("electron"))
@ele begin_fodo = BeginningEle(E_tot_ref = 1.23456789012345678e3, s = 0.3, species_ref = species("photon"))
#@ele qf = Quadrupole(L = 0.6, K2 = 0.3, tilt0 = 1, x_rot = 2, alias = "qz", Es8L = 123, Etilt8 = 2)
@ele qf = Quadrupole(L = 0.6, x_rot = 2, alias = "qz", Ks8L = 123, tilt8 = 2)
@ele qd = Quadrupole(L = 0.6, Kn1 = -0.3)
@ele d = Drift(L = 0.4)
@ele z1 = Bend(L = 1.2, angle = 0.001)
@ele z2 = Sextupole(Kn2L = 0.2)
@ele m1 = Marker()

bl = BeamLine
ln1 = bl([qf, d])
ln2 = bl([qd, d, qd], geometry = CLOSED, multipass = true)
fodo = bl("fodo", [z1, z2, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), reverse(bl("sub", [qd, ln1]))])

lat = expand([bl([begin_fodo, fodo]), bl([begin_ln2, ln2]))
