using AcceleratorLattice, Test

include("lat1.jl")

#-----------------------------

@testset "AcceleratorLattice.jl" begin
  @test 2 == 2
  @test 2 ≈ 3 atol = 2
end
