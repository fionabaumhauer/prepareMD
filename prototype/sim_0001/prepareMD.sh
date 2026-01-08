#!/bin/bash

# activate conda environment
source /home/fb590/miniconda3/etc/profile.d/conda.sh
conda activate prepareMD

# copy necessary files
cp /scratch/fb590/co2n2/electric/prepareMD/prototype/templates/packmol.inp .
cp /scratch/fb590/co2n2/electric/prepareMD/prototype/templates/in.lammps .

# get sim_id from directory name
dir_name=$(basename "$PWD")
sim_id=${dir_name#sim_}

# get average numbers of molecules
averagesfile="/scratch/fb590/co2n2/electric/prepareMD/prototype/gcmc_averages.txt"
read CO2 N2 < <(awk -v sim="$sim_id" 'BEGIN{FS="\t"} $1==sim {printf "%.0f %.0f", $3, $4}' "$averagesfile")

# multiply by 3 because MD box is 90x90x30 rather than 30x30x30                                                                                                                                                                                                                            
CO2_forMD=$(( CO2 * 3 ))
N2_forMD=$(( N2 * 3 ))

# edit packmol input file and run to output temp.xyz
sed -i "s/NUMBER_N2/${N2_forMD}/g" packmol.inp
sed -i "s/NUMBER_CO2/${CO2_forMD}/g" packmol.inp
packmol -i packmol.inp
 
# take coordinates from temp.xyz and put them in a data file
python /scratch/fb590/co2n2/electric/prepareMD/prototype/scripts/convert_xyz_to_data.py

# make a copy of input.yaml where all LJ walls (if there are any) are zeroed by setting all epsilons to 0.0
sed \
    -e 's/^\(\s*epsilon_lo:\s*\).*/\10.0/' \
    -e 's/^\(\s*epsilon_hi:\s*\).*/\10.0/' \
    input.yaml > input_nowalls.yaml

# create txt files for each species containing binned forces calculated from the external potential in input_nowalls.yaml
python /scratch/fb590/co2n2/electric/prepareMD/prototype/scripts/make_forces_files.py

# clean up the directory a little
rm input_nowalls.yaml
rm temp.xyz

# get T from input.yaml and insert it into in.lammps
T=$(awk -F: '/^T:/ {gsub(/^[ \t]+/, "", $2); print $2}' input.yaml)
sed -i "s/__TEMPERATURE__/${T}/g" in.lammps

