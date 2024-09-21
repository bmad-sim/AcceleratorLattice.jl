using AcceleratorLattice, Test

@eles begin
  beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = species("electron"))
  q1 = Quadrupole(L = 0.6, x_rot = 2, alias = "qz", Ks8L = 123, tilt8 = 2)
  q2 = Quadrupole(L = 0.6, Kn1 = -0.3);
  d1 = Drift(L = 1.0);
  d2 = Drift(L = 1.0);
  d3 = Drift(L = 1.0);
  m1 = Marker();
  zs1 = Sextupole(Kn2L = 0.2);
  zm1 = Marker();
  zm2 = Marker();
  zm3 = Marker();
end;

ln1 = BeamLine([beginning, d1, d2, d1, m1, d3]);
lat = expand([ln1]);

#---------------------------------------------------------------------------------------------------

#superimpose!(zs1, eles(lat, "d1"), offset = 0.2);
#superimpose!(zm1, eles(lat, "m1"), ref_origin = BodyLoc.ENTRANCE_END);
#superimpose!(zm2, eles(lat, "m1"), ref_origin = BodyLoc.CENTER);
#superimpose!(zm3, eles(lat, "m1"), ref_origin = BodyLoc.EXIT_END);

@testset "Superimpose" begin
end

