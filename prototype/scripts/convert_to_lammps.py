import ase.io
import ase.io.lammpsdata
atoms=ase.io.read('temp.xyz')
ase.io.lammpsdata.write_lammps_data('temp.data',atoms)