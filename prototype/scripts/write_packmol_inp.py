'''
This script writes a packmol input file, but you still have to insert the number of molecules of both species (easier in bash).
'''

import yaml

# if there are walls write packmol box to only have molecules within the walls
yamlfile = "input.yaml"
with open(yamlfile, 'r') as file:
    config = yaml.safe_load(file)

low = config['particle_types']['C']['low']
high = config['particle_types']['C']['high']
epsilon_from_yaml = config['particle_types']['C']['epsilon_lo']
if epsilon_from_yaml != 0: 
    coordinates_line = f"inside box 2.0 2.0 {low + 2} 28.0 28.0 {high - 2}"
else:
    coordinates_line = f"inside box 2.0 2.0 2.0 28.0 28.0 28.0"

packmol_contents = f"""\
tolerance 2
output temp.xyz
filetype xyz
seed 28446

structure /scratch/fb590/co2n2/electric/prepareMD/prototype/templates/N2.xyz
   number NUMBER_N2
   {coordinates_line}
end structure

structure /scratch/fb590/co2n2/electric/prepareMD/prototype/templates/CO2.xyz
   number  NUMBER_CO2
   {coordinates_line}
end structure
"""

with open("packmol.inp", "w") as f:
    f.write(packmol_contents)