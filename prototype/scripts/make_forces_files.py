"""
This script gets the external potential from input_nowalls.yaml and creates a txt file with the binned forces for each species.
"""
from matplotlib import pyplot as plt
import numpy as np
import yaml
import scipy.constants as const
import sys

sys.path.insert(0, '/scratch/fb590/code/gcmc-dev/src')
from external_potentials import initialize_external_potentials

yamlfile = "input_nowalls.yaml"
with open(yamlfile, 'r') as file:
    config = yaml.safe_load(file)

T = config['T']
low = config['particle_types']['C']['low']
high = config['particle_types']['C']['high']
phi = config['particle_types']['C']['phi_0_hi'] * const.Boltzmann * T
d = config['particle_types']['C']['d_hi']
beta = 1 / (const.Boltzmann * T)

bin_edges = x_positions = np.linspace(0, config['box_length_x'], 2001)
bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
xbins = np.array([bin_centers])
a = np.append(bin_centers[::]-bin_centers[::][0], bin_centers[::][-1]-bin_centers[::][0]+bin_centers[::][0])
np.savetxt(f"zbins.txt", a)

r_low = xbins[0] - low
r_high = high - xbins[0]

# test if exponential or sine:
if phi == 0:
    haswalls = False
else:
    haswalls = True

# calculate binned forces
species_list = ["C", "O", "N", "X"]

for species in species_list:
    mu = config['particle_types'][species]['mu'] * const.Boltzmann * T
    q = config['particle_types'][species]['q']
    if haswalls:
        Vext_values_low = phi * np.exp(-r_low/d) * q
        Vext_values_high = phi * np.exp(-r_high/d) * q
        Vext_values = Vext_values_low + Vext_values_high
    else:
        Vext = initialize_external_potentials(config)[species]
        Vext_values = Vext(xbins)
    muloc_profile = (Vext_values - mu) * beta
    muloc_profile_in_kcal_per_mol = muloc_profile * const.Boltzmann * T * const.Avogadro / 4184 # keeping all the beta stuff here beause it helps me visualise conversions
    plt.plot(muloc_profile_in_kcal_per_mol)
    force_profile = np.gradient(-muloc_profile_in_kcal_per_mol, bin_centers) # computes d/dx (-u(x)) for each bin
    plt.plot(force_profile)
    plt.show()
    np.savetxt(f"force{species}.txt", force_profile)