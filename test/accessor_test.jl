using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = Species("electron"))
@ele qf = Quadrupole(L = 0.6, alias = "z1", type = "abc", description = "xyt")
@ele d = Drift(L = 0.4);
@ele d2 = Drift(L = -1.5);
@ele d3 = Drift(L = 2);
@ele b1 = Bend(L = 1.2);
@ele s1 = Sextupole(type = "abc", Kn0 = 1, Ks1 = 2, Kn2L = 3, Ks3L = 4, 
                                  Bn4 = 5, Bs5 = 6, Bn6L = 7, Bs70L = 8, 
                                  En80 = 9, Es9 = 10, En10L = 11, Es11L = 12,
                                  tilt2 = 20, Etilt2 = 30);
@ele z1 = Bend(L = 0.02);
@ele z2 = Sextupole(L = 2.2, type = "abc");
@ele m1 = Marker(type = "qf");

bl = BeamLine
ln3 = bl([beginning, d, b1, m1, d3], name = "ln3")

lat = Lattice(ln3, name = "honeybee")

#---------------------------------------------------------------------------------------------------

bele = lat.branch[1].ele[1]

@testset "getproperty" begin
  @test [s1.Kn0, s1.Ks1, s1.Kn2L, s1.Ks3L] == [1, 2, 3, 4]
  @test [s1.Bn4, s1.Bs5, s1.Bn6L, s1.Bs70L] == [5, 6, 7, 8] 
  @test [s1.En80, s1.Es9, s1.En10L, s1.Es11L] == [9, 10, 11, 12]
  @test [s1.tilt2, s1.Etilt2] == [20, 30] 
  @test [s1.integrated0, s1.integrated2, s1.Eintegrated80, s1.Eintegrated10] == [false, true, false, true]
  @test [qf.alias, qf.type, qf.description] == ["z1", "abc", "xyt"]
  @test lat.name == "honeybee"
  @test lat.branch[1].name == "ln3"
  @test ln3.name == "ln3"
  @test !(beginning === lat.branch[1].ele[1])
end

