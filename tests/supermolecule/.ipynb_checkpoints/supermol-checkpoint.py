import numpy as np
import pyscf
from pyscf.hessian import thermo
from gpu4pyscf.dft import rks

from enum import Enum as ENUM

class THEORY(ENUM):
    DFT = 0
    HF = 1
    MP2 = 2
    CCSD = 3
    MP3 = 4

class BASIS(ENUM):
    def2_tzvpp = 0
    def2_tzvp = 1


class CALCS(ENUM):
    ENERGY = 0
    GRADIENT = 1
    HESSIAN = 2
    HARMONIC = 3
    THERMO = 4

all_theory = [THEORY.DFT, THEORY.HF, THEORY.MP2, THEORY.CCSD, THEORY.MP3]
all_basis = [BASIS.def2_tzvpp, BASIS.def2_tzvp]
all_calcs = [CALCS.ENERGY, CALCS.GRADIENT, CALCS.HESSIAN, CALCS.HARMONIC, CALCS.THERMO]

def create_mol(atoms):
    mol = pyscf.M(
        atom=atom,                         # water molecule
        basis=basis,                # basis set
        output=log_file,              # save log file
        verbose=verbose                          # control the level of print info
        )

def setup_mol(atom, basis, log_file='./pyscf.log', 
verbose=6, 
lebedev_grids=(99,590),
scf_tol=1e-10,
scf_max_cycle=50,
cpscf_tol=1e-3,
conv_tol=1e-10,
conv_tol_cpscf=1e-3,
):
    if type(atom) == str:
        mol = create_mol(atom)
    else:
        mol = atom
        
    mf_GPU = rks.RKS(                      # restricted Kohn-Sham DFT
        mol,                               # pyscf.gto.object
        xc='b3lyp'                         # xc funtionals, such as pbe0, wb97m-v, tpss,
        ).density_fit()                    # density fitting

    mf_GPU.grids.atom_grid = lebedev_grids      # (99,590) lebedev grids, (75,302) is often enough
    mf_GPU.conv_tol = scf_tol                # controls SCF convergence tolerance
    mf_GPU.max_cycle = scf_max_cycle                  # controls max iterations of SCF
    mf_GPU.conv_tol_cpscf = conv_tol_cpscf           # controls max iterations of CPSCF (for hessian)

    return mf_GPU, mol



def compute_dft(mol, calcs):

    engine, mol = setup_mol(mol, "b3lyp")

    output = {"mol": mol, "calcs": calcs}

    if CALCS.ENERGY in calcs:
        # Compute Energy
        e_dft = engine.kernel()
        print(f"total energy = {e_dft}")       # -76.46668196729536
        output['energy'] = e_dft

    if CALCS.GRADIENT in calcs:
        # Compute Gradient
        g = engine.nuc_grad_method()
        g_dft = g.kernel()
        output['gradient'] = g_dft

    if CALCS.HESSIAN in calcs:
        # Compute Hessian
        h = engine.Hessian()
        h.auxbasis_response = 2                # 0: no aux contribution, 1: some contributions, 2: all
        engine.cphf_grids.atom_grid = (50,194) # customize grids for solving CPSCF equation, SG1 by default
        h_dft = h.kernel()
        output['hessian'] = h_dft

    if CALCS.HARMONIC in calcs:
        # harmonic analysis
        results = thermo.harmonic_analysis(mol, h_dft)
        thermo.dump_normal_mode(mol, results)
        output['harmonic'] = results

    if CALCS.THERMO in calcs:
        results = thermo.thermo(
            engine,                            # GPU4PySCF object
            results['freq_au'],
            298.15,                            # room temperature
            101325)                            # standard atmosphere

        thermo.dump_thermo(mol, results)
        output['thermo'] = results

    if CALCS.HESSIAN in calcs:
        # force translational symmetry
        natm = mol.natm
        h_dft = h_dft.transpose([0,2,1,3]).reshape(3*natm,3*natm)
        h_diag = h_dft.sum(axis=0)
        h_dft -= np.diag(h_diag)
        output['hessian'] = h_dft

    return output




def compute_interaction_energy(monomer_a, monomer_b, basis='cc-pVDZ', xc='b3lyp'):
    # Convert string geometries to PySCF atom format
    def parse_xyz(xyz_str):
        atoms = []
        for line in xyz_str.strip().split('\n'):
            if not line.strip(): continue
            symbol, *coords = line.split()
            coords = tuple(float(x) for x in coords)
            atoms.append((symbol, coords))
        return atoms

    atom_A = parse_xyz(monomer_a)
    atom_B = parse_xyz(monomer_b)
    atom_AB = atom_A + atom_B

    # Build molecular objects
    mol_A = pyscf.M(atom=atom_A, basis=basis).build()
    mol_B = pyscf.M(atom=atom_B, basis=basis).build()
    mol_AB = pyscf.M(atom=atom_AB, basis=basis).build()

    # Create ghost-atom systems for BSSE correction
    mol_A_ghost = mol_A.copy()
    ghost_atoms_B = mol_B.atom
    mol_A_ghost.atom.extend([('X-' + atom[0], atom[1]) for atom in ghost_atoms_B])
    mol_A_ghost.build()



    mol_B_ghost = mol_B.copy()
    ghost_atoms_A = mol_A.atom
    mol_B_ghost.atom.extend([('X-' + atom[0], atom[1]) for atom in ghost_atoms_A])
    mol_B_ghost.build()

    regular_calcs = [CALCS.ENERGY, CALCS.GRADIENT, CALCS.HESSIAN, CALCS.HARMONIC, CALCS.THERMO]
    ghost_calcs = [CALCS.ENERGY]
    
    output_AB = compute_dft(mol_AB, regular_calcs)
    E_AB = output_AB["energy"]

    output_A = compute_dft(mol_A, regular_calcs)
    E_A = output_A["energy"]

    output_B = compute_dft(mol_B, regular_calcs)
    E_B = output_B["energy"]    

    output_A_ghost = compute_dft(mol_A_ghost, ghost_calcs)
    E_A_ghost = output_A_ghost["energy"]    

    output_B_ghost = compute_dft(mol_B_ghost, ghost_calcs)
    E_B_ghost = output_B_ghost["energy"]
    

    # Calculate interaction energies
    IE_no_bsse = E_AB - (E_A + E_B)
    IE_energy_bsse = E_AB - (E_A_ghost + E_B_ghost)

    intE = {
        'E_AB': E_AB,
        'E_A': E_A,
        'E_B': E_B,
        'E_A_ghost': E_A_ghost,
        'E_B_ghost': E_B_ghost,
        'IE_no_bsse': IE_no_bsse,
        'IE_energy_bsse': IE_energy_bsse,
    }
    output = {
        'results_AB': output_AB,
        'results_A': output_A,
        'results_B': output_B,
        'results_A_ghost': output_A_ghost,
        'results_B_ghost': output_B_ghost,
        'intE_results': intE
    }
    return output








