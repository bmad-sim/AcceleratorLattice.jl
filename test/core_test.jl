using AcceleratorLattice, Test

s = Species("electron")

@testset "conversion" begin
  @test pc(s, E_tot = E_tot(s, pc = 1e4)) ≈ 1e4
  @test pc(s, β = β(s, pc = 1e4)) ≈ 1e4
  @test pc(s, E_kinetic = E_kinetic(s, pc = 1e4)) ≈ 1e4
  @test pc(s, γ = γ(s, pc = 1e4)) ≈ 1e4

  @test pc(s, E_tot = E_tot(s, pc = 1e12)) ≈ 1e12
  @test pc(s, E_kinetic = E_kinetic(s, pc = 1e12)) ≈ 1e12
  @test pc(s, γ = γ(s, pc = 1e12)) ≈ 1e12

  @test E_tot(s, pc = pc(s, E_tot = 6e5)) ≈ 6e5
  @test E_tot(s, β = β(s, E_tot = 6e5)) ≈ 6e5
  @test E_tot(s, E_kinetic = E_kinetic(s, E_tot = 6e5)) ≈ 6e5
  @test E_tot(s, γ = γ(s, E_tot = 6e5)) ≈ 6e5

  @test E_tot(s, pc = pc(s, E_tot = 1e12)) ≈ 1e12
  @test E_tot(s, E_kinetic = E_kinetic(s, E_tot = 1e12)) ≈ 1e12
  @test E_tot(s, γ = γ(s, E_tot = 1e12)) ≈ 1e12

  @test E_kinetic(s, E_tot = E_tot(s, E_kinetic = 1e4)) ≈ 1e4
  @test E_kinetic(s, β = β(s, E_kinetic = 1e4)) ≈ 1e4
  @test E_kinetic(s, pc = pc(s, E_kinetic = 1e4)) ≈ 1e4
  @test E_kinetic(s, γ = γ(s, E_kinetic = 1e4)) ≈ 1e4

  @test β(s, E_tot = E_tot(s, β = 0.1)) ≈ 0.1
  @test β(s, pc = pc(s, β = 0.1)) ≈ 0.1
  @test β(s, E_kinetic = E_kinetic(s, β = 0.1)) ≈ 0.1
  @test β(s, γ = γ(s, β = 0.1)) ≈ 0.1

  @test β(s, E_tot = E_tot(s, β = 0.9999)) ≈ 0.9999
  @test β(s, pc = pc(s, β = 0.9999)) ≈ 0.9999
  @test β(s, E_kinetic = E_kinetic(s, β = 0.9999)) ≈ 0.9999
  @test β(s, γ = γ(s, β = 0.9999)) ≈ 0.9999

  @test β1(s, E_tot = E_tot(s, β = 1 - 1e-6)) ≈ 1e-6
  @test β1(s, pc = pc(s, β = 1 - 1e-6)) ≈ 1e-6
  @test β1(s, E_kinetic = E_kinetic(s, β = 1 - 1e-6)) ≈ 1e-6
  @test β1(s, γ = γ(s, β = 1 - 1e-6)) ≈ 1e-6

  @test γ(s, pc = pc(s, γ = 1.0001)) ≈ 1.0001
  @test γ(s, β = β(s, γ = 1.0001)) ≈ 1.0001
  @test γ(s, E_kinetic = E_kinetic(s, γ = 1.0001)) ≈ 1.0001
  @test γ(s, E_tot = E_tot(s, γ = 1.0001)) ≈ 1.0001

  @test γ(s, pc = pc(s, γ = 1e12)) ≈ 1e12
  @test γ(s, E_kinetic = E_kinetic(s, γ = 1e12)) ≈ 1e12
  @test γ(s, E_tot = E_tot(s, γ = 1e12)) ≈ 1e12
end