using AcceleratorLattice, Test

@testset "AcceleratorLattice" begin
  t0 = time()

  @testset "superimpose_test" begin
    println("##### Testing superimpose_test.jl...")
    t = @elapsed include("superimpose_test.jl")
    println("##### done (took $t seconds).")
  end

  @testset "find_test" begin
    println("##### Testing find_test.jl...")
    t = @elapsed include("find_test.jl")
    println("##### done (took $t seconds).")
  end

  @testset "lat_construction_test" begin
    println("##### Testing lat_construction_test.jl...")
    t = @elapsed include("lat_construction_test.jl")
    println("##### done (took $t seconds).")
  end

  println("##### Running all AcceleratorLattice tests took $(time() - t0) seconds.")
end
