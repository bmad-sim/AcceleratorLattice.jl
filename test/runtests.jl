using AcceleratorLattice, Test

@testset verbose = true "AcceleratorLattice" begin

  @testset "string_test" begin
    include("string_test.jl")
  end

  @testset "find_test" begin
    include("find_test.jl")
  end

  @testset "superimpose_test" begin
    include("superimpose_test.jl")
  end

#  @testset "lat_construction_test" begin
#    include("lat_construction_test.jl")
#  end


end;

print("")  # To surpress trailing garbage output