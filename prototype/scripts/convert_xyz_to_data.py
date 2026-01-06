# atom types & charges 
atom_info = {
    "C": (1, 0.70),
    "O": (2, -0.35),
    "X": (3, 0.964),
    "N": (4, -0.482),
}

xyz_file = "temp.xyz"

# Read XYZ
atoms = []
X_count = 0
C_count = 0
with open(xyz_file) as f:
    lines = f.readlines()
    # num_atoms = int(lines[0].strip())
    coord_lines = lines[2:]  # skip first 2 lines

    atom_id = 1
    molecule_id = 1 
    for i,line in enumerate(coord_lines):
        parts = line.split()
        element = parts[0]
        x, y, z = map(float, parts[1:4])

        if element not in atom_info:
            raise ValueError(f"Element {element} notin atom_info")

        if element == "X":
            X_count += 1
        if element == "C":
            C_count += 1

        atom_type, charge = atom_info[element]
        atoms.append((atom_id, molecule_id, atom_type, charge, x, y, z, 0, 0, 0))
        atom_id += 1
        # every three lines increase molecule id
        if (i + 1) % 3 == 0:
            molecule_id += 1


total_atoms = X_count * 3 + C_count * 3
total_bonds = X_count * 2 + C_count * 2
total_angles = X_count + C_count

atoms_str = "Atoms # full\n\n" + "\n".join(" ".join(map(str, a)) for a in atoms)

data_contents = f"""\
LAMMPS data file for n2/co2

{total_atoms} atoms
4 atom types
{total_bonds} bonds
2 bond types
{total_angles} angles
2 angle types

0 90 xlo xhi
0 90 ylo yhi
0 30 zlo zhi

Masses

1 12.0107
2 15.9999
3 28.0134
4 2

Pair Coeffs # lj/cut/coul/long

1 0.0536548 2.8
2 0.15699 3.05
3 0 0
4 0.0715394 3.31

Bond Coeffs # harmonic

1 5000 1.16
2 5000 0.55

Angle Coeffs # harmonic

1 500 180
2 500 180

{atoms_str}
"""

with open("initialMD.data", "w") as f:
    f.write(data_contents)