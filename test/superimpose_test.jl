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

ln1 = beamline("ln1", [beginning, d1, d2, d1, m1, d3]);
lat = expand([ln1]);

#---------------------------------------------------------------------------------------------------

superimpose!(zs1, eles(lat, "d1"), offset = 0.2);
superimpose!(zm1, eles(lat, "m1"), ref_origin = entrance_end);
superimpose!(zm2, eles(lat, "m1"), ref_origin = b_center);
superimpose!(zm3, eles(lat, "m1"), ref_origin = exit_end);

@testset "Superimpose" begin
  @test ele_at_s(lat.branch[1], 0.3, true).ix_ele == 1
  @test ele_at_s(lat.branch[1], 0.3, false).ix_ele == 2
end



ln2 = beamline([beginning, qd, d, qd], geometry = Closed, multipass = true);


fodo = beamline("fodo", [z1, z2, -2*ln1, m1, m1, ln2, reverse(qf), reverse(ln2), reverse(beamline("sub", [qd, ln1]))]);
