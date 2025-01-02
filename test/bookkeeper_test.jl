using AcceleratorLattice, Test

@ele begin1 = BeginningEle(species_ref = Species("electron"), pc_ref = 1e6)
@ele begin2 = BeginningEle(species_ref = Species("proton"), pc_ref = 1e6)

@ele bend1 = Bend(g = 1, angle = pi/2, Kn2L = 0.1, Bs3 = 0.2, En4 = 0.3, Es5L = 0.4)
bend2 = copy(bend1)
bend2.name = "bend2"
bend2.tilt_ref = pi/2

@ele bend3 = Bend(g = 0, L = 2)

line1 = BeamLine([begin1, bend1, bend3])
line2 = BeamLine([begin2, bend2])
lat = Lattice([line1, line2])

b1 = lat.branch[1]
b2 = lat.branch[2]

@testset "bend_bookkeeping" begin


end

# test patches