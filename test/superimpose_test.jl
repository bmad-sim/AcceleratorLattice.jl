using AcceleratorLattice, Test

@eles begin
  beginning = BeginningEle(pc_ref = 1e7, species_ref = Species("electron"))
  q1 = Quadrupole(L = 0.6, x_rot = 2, ID = "qz", Ks8L = 123, tilt8 = 2)
  q2 = Quadrupole(L = 0.6, Kn1 = -0.3);
  d1 = Drift(L = 1.0);
  d2 = Drift(L = 1.0);
  d3 = Drift(L = 1.0);
  m1 = Marker();
  m2 = Marker();
  zs1 = Sextupole(Kn2L = 0.2);
  zs2 = Bend(L = 0.3, Kn2L = 0.1, Bs3 = 0.2, En4 = 0.3, Es5L = 0.4)
  zm3 = Marker();
end;

ln1 = BeamLine([beginning, d1, d2, d1, d3]);
lat = Lattice([ln1])

superimpose!(zs2, eles(lat, "d1"), offset = 0.25)
superimpose!(m1, lat.branch[1], offset = 0, ref_origin = BodyLoc.ENTRANCE_END)
superimpose!(m2, lat.branch[1], offset = 2.7)

#---------------------------------------------------------------------------------------------------

#superimpose!(zs1, eles(lat, "d1"), offset = 0.2);
#superimpose!(zm1, eles(lat, "m1"), ref_origin = BodyLoc.ENTRANCE_END);
#superimpose!(zm2, eles(lat, "m1"), ref_origin = BodyLoc.CENTER);
#superimpose!(zm3, eles(lat, "m1"), ref_origin = BodyLoc.EXIT_END);

@testset "Superimpose" begin
  # getproperty. L, s, s_downstream, name, multipoles, reference energy
end

# superimpose at boundary
# Make sure superimpose at branch start is not before beginning element.

print("")  # To surpress trailing garbage output
