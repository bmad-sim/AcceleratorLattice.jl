# OLD! NOT USED! SLATED TO BE REMOVED!

# 2018 CODATA

const m_electron::Float64              = 0.51099895000e6               # Mass [eV]
const m_proton::Float64                = 0.93827208816e9               # Mass [eV]
const m_neutron::Float64               = 0.93956542052e9               # Mass [eV]
const m_muon::Float64                  = 105.6583755e6                 # Mass [eV]
const m_helion::Float64                = 2.808391607035771e9           # Mass He3 nucleus
const m_pion_0::Float64                = 134.9766e6                    # Mass [eV]
const m_pion_charged::Float64          = 139.57018e6                   # Mass [eV]
const m_deuteron::Float64              = 1.87561294257e9               # Mass [eV]
const atomic_mass_unit::Float64        = 931.49410242e6                # unified atomic mass unit u (or dalton) in [eV]
 
const c_light::Float64                 = 2.99792458e8                  # speed of light
const e_charge::Float64                = 1.602176634e-19               # electron charge [Coul]
const h_planck::Float64                = 4.135667696e-15               # Planck's constant [eV*sec]
const h_bar_planck::Float64            = h_planck / 2pi              # h_planck/twopi [eV*sec]
const r_e::Float64                     = 2.8179403262e-15              # classical electron radius
const r_p::Float64                     = r_e * m_electron / m_proton   # proton radius

const mu_0_vac::Float64                = 1.25663706212e-6              # Vacuum permeability 2018 CODATA.
const eps_0_vac::Float64               = 1 / (c_light*c_light * mu_0_vac) # Permittivity of free space

const classical_radius_factor::Float64 = r_e * m_electron # e^2 / (4 pi eps_0) [m*eV]
                                                                       #  = classical_radius * mass * c^2. 
                                                                       # Is same for all particles of charge +/- 1.
const N_avogadro::Float64              = 6.02214076e23                 # Number / mole  (exact)

# Anomalous magnetic moment.
# Note: Deuteron g-factor
#   g_deu = (g_p / (mu_p / mu_N)) (mu_deu / mu_N) * (m_deu / m_p) * (q_p / q_deu) * (S_p / S_deu)
# The anomlous mag moment a = (g - 2) / 2 as always.

# For Helion:
#   g_eff = 2 * R_mass * (mu_h/mu_p) / Q
#         = 2 * (2808.39160743(85) MeV / 938.27208816(29) MeV) * (−2.127625307(25)) / (2)
#         = −6.368307373
#   anom_mag_moment = (g_eff - 2) / 2 = -4.184153686e0

const fine_structure_constant::Float64  =  7.2973525693e-3
const anom_mag_moment_electron::Float64 = 1.15965218128e-3
const anom_mag_moment_proton::Float64   = 1.79284734463e0
const anom_mag_moment_muon::Float64     = 1.16592089e-3            # ~fine_structure_constant / twopi
const anom_mag_moment_deuteron::Float64 = -0.14298726925e0
const anom_mag_moment_neutron::Float64  = -1.91304273e0
const anom_mag_moment_He3::Float64      = -4.184153686e0

#---------------------------------------------------------------------------------------------------
# Species

const notset_name = "Not Set!"

@kwdef struct Species
  name::String = notset_name
end

function species(name::AbstractString)
  return Species(name)
end

"""
mass in eV / c^2
"""

function mass(species::Species)
  return 1e3
end

function charge(species::Species)
  return -1
end

function E_tot_from_pc(pc::Float64, species::Species)
  return sqrt(pc^2 + mass(species)^2)
end

function pc_from_E_tot(E_tot::Real, species::Species)
  return sqrt(E_tot^2 - mass(species)^2)
end

#---------------------------------------------------------------------------------------------------

export m_electron, m_proton, m_neutron, m_muon, m_helion, m_pion_0, m_pion_charged, m_deuteron, atomic_mass_unit
export c_light, e_charge, h_planck, h_bar_planck, r_e, r_p, mu_0_vac, eps_0_vac, classical_radius_factor, N_avogadro
export fine_structure_constant, anom_mag_moment_electron, anom_mag_moment_proton, anom_mag_moment_muon
export anom_mag_moment_deuteron, anom_mag_moment_neutron, anom_mag_moment_He3
export Species, species, mass, charge, E_tot_from_pc, pc_from_E_tot

export notset_name, Species, species, mass, E_tot_from_pc, pc_from_E_tot