using AcceleratorLattice, Test

@testset "AcceleratorLattice" begin
  t0 = time()

  @testset "Find" begin
    println("##### Testing FindTest.jl...")
    t = @elapsed include("FindTest.jl")
    println("##### done (took $t seconds).")
  end

  println("##### Running all AcceleratorLattice tests took $(time() - t0) seconds.")
end
