using AcceleratorLattice, Test

@ele beginning = BeginningEle(s = 0.3, pc_ref = 1e7, species_ref = Species("electron"))
@ele qf = Quadrupole(L = 0.6, alias = "z1")
@ele d = Drift(L = 0.4);
@ele d2 = Drift(L = -1.5);
@ele d3 = Drift(L = 2);
@ele b1 = Bend(L = 1.2);
@ele s1 = Sextupole(type = "abc");
@ele z1 = Bend(L = 0.02);
@ele z2 = Sextupole(L = 2.2, type = "abc");
@ele m1 = Marker(type = "qf");

bl = BeamLine
ln3 = bl([beginning, d, b1, m1, d3], name = "ln3")

lat = Lat(ln3, name = "honeybee")

#---------------------------------------------------------------------------------------------------

bele = lat.branch[1].ele[1]

@testset "getproperty" begin
  @test lat.name == "honeybee"
  @test lat.branch[1].name == "ln3"
  @test ln3.name == "ln3"
  @test !(beginning === lat.branch[1].ele[1])
end

