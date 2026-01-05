#!/bin/bash

CO2=100
N2=200

cp /scratch/fb590/co2n2/electric/prepareMD/prototype/templates/packmol.inp .

sed -i "s/NUMBER_N2/${N2}/g" packmol.inp
sed -i "s/NUMBER_CO2/${CO2}/g" packmol.inp


bwp="Built with Packmol"
lattice='Lattice="30.0 0.0 0.0 0.0 30.0 0.0 0.0 0.0 30.0"'

packmol -i packmol.inp

sed -i "s/${bwp}/${lattice}/g" temp.xyz

python /scratch/fb590/co2n2/electric/prepareMD/prototype/scripts/convert_to_lammps.py