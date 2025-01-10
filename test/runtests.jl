using AcceleratorLattice, Test

@testset verbose = true "AcceleratorLattice" begin

  @testset "accessor_test" begin
    include("accessor_test.jl")
  end

  @testset "bookkeeper_test" begin
    include("bookkeeper_test.jl")
  end

  @testset "find_test" begin
    include("find_test.jl")
  end

#  @testset "fork_test" begin
#    include("fork_test.jl")
#  end

  @testset "string_test" begin
    include("string_test.jl")
  end

  @testset "superimpose_test" begin
    include("superimpose_test.jl")
  end

#  @testset "lat_construction_test" begin
#    include("lat_construction_test.jl")
#  end

#  @testset "multipass_test" begin
#    include("multipass_test.jl")
#  end


end;

print("")  # To surpress trailing garbage output

# Fork test with multipass and superimpose. 
# lattice copy test. Make sure forked to element pointers are properly handled.