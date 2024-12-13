using AcceleratorLattice, Test

@eles begin
  beginning = BeginningEle(pc_ref = 1e7, species_ref = Species("electron"))
  q1 = Quadrupole(L = 0.6, x_rot = 2, ID = "qz", Ks8L = 123, tilt8 = 2, Bn9 = 3, 
                          En1L = 1, Etilt1 = 2, Es2 = 3, Etilt2 = 4)
  q2 = Quadrupole(L = 0.6, Kn1 = -0.3);
  d1 = Drift(L = 1.0);
  lc1 = LCavity(L = 1.0, dE_ref = 2e7);
  d3 = Drift(L = 1.0);
  m1 = Marker();
  m2 = Marker();
  zs1 = Sextupole(Kn2L = 0.2);
  zs2 = Bend(L = 0.3, Kn2L = 0.1, Bs3 = 0.2, En4 = 0.3, Es5L = 0.4)
  zm1 = Marker();
  zm2 = Marker();
  zm3 = Marker();
  zm4 = Marker();
end;

ln1 = BeamLine([beginning, d1, lc1, d1, d3]);
lat = Lattice([ln1])

#---------------------------------------------------------------------------------------------------

superimpose!(m1, lat.branch[1], offset = 0, ref_origin = BodyLoc.ENTRANCE_END)
superimpose!(zm1, eles(lat, "m1"), ref_origin = BodyLoc.ENTRANCE_END);
superimpose!(zs2, eles(lat, "d1"), offset = 0.25)
superimpose!(zm4, eles(lat, "lc1"), offset = 0.2);
superimpose!(m2, lat.branch[1], offset = 2.7)
superimpose!(zm2, eles(lat, "m1"), ref_origin = BodyLoc.CENTER);
superimpose!(zm3, eles(lat, "m1"), ref_origin = BodyLoc.EXIT_END);

b1 = lat.branch[1]
b2 = lat.branch[2]

@testset "Superimpose" begin
  @test [e.name for e in b1.ele] == ["beginning", "zm1", "zm2", "m1", "zm3", "d1!1", "zs2!s", "d1!2", 
              "lc1!s1", "zm4", "lc1!s2", "d1!1", "zs2!s1", "m2", "zs2!s2", "d1!2", "d3", "end_ele"]
  @test [e.name for e in b2.ele] == ["zs2", "zs2", "lc1"]
  @test b1.ele[7].super_lords  == [b2.ele[1]]
  @test b1.ele[9].super_lords  == [b2.ele[3]]
  @test b1.ele[11].super_lords  == [b2.ele[3]]
  @test b1.ele[13].super_lords == [b2.ele[2]]
  @test b1.ele[15].super_lords == [b2.ele[2]]
  @test b2.ele[1].slaves == [b1.ele[7]]
  @test b2.ele[2].slaves == [b1.ele[13], b1.ele[15]]
  @test b2.ele[3].slaves == [b1.ele[9], b1.ele[11]]
end

# zs1 not getting superimposed!!
# No warning about no superpositions!!
# getproperty. L, s, s_downstream, name, multipoles, reference energy
# superimpose at boundary
# Make sure superimpose at branch start is not before beginning element.
# Transfer of parameters between lord/slave especially multipoles
# LCavity with marker
# UnionEle

print("")  # To surpress trailing garbage output
