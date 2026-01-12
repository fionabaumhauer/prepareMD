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

# get LJ wall parameters from input.yaml (assumes that walls are symmetric)
low=$(awk '/^[[:space:]]*C:/ {f=1} f && /low:/ {print $2; exit}' input.yaml)
high=$(awk '/^[[:space:]]*C:/ {f=1} f && /high:/ {print $2; exit}' input.yaml)
cutoff=$(awk '/^[[:space:]]*C:/ {f=1} f && /cutoff_lo:/ {print $2; exit}' input.yaml)
epsilon=$(awk '/^[[:space:]]*C:/ {f=1} f && /epsilon_lo:/ {print $2; exit}' input.yaml)
sigma=$(awk '/^[[:space:]]*C:/ {f=1} f && /sigma_lo:/ {print $2; exit}' input.yaml)

wallstr_high="fix wallhi all wall/lj93 zlo ${high} ${epsilon} ${sigma} ${cutoff} units box"
wallstr_low="fix walllo all wall/lj93 zhi ${low} ${epsilon} ${sigma} ${cutoff} units box"

# if there are are LJ walls, then insert them into in.lammps. otherwise delete the placeholder
if [ "$(echo "$epsilon != 0" | bc -l)" -eq 1 ]; then
    sed -i "s|__LJWALL_HIGH__|$wallstr_high|" in.lammps
    sed -i "s|__LJWALL_LOW__|$wallstr_low|" in.lammps
else
    sed -i "/__LJWALL_HIGH__/d" in.lammps
    sed -i "/__LJWALL_LOW__/d" in.lammps
fi
