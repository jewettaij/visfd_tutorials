#!/bin/bash
##################################################################
## This is an example SLURM script
## "##" is a comment "#" is a SLURM configuration
## If you don't specify here, default values will be used
##################################################################
#SBATCH --job-name=voxelize
#SBATCH -e output.err
#SBATCH -o output.out
#SBATCH --ntasks=1                   # Number of MPI tasks (i.e. processes)
#SBATCH --cpus-per-task=1             # Number of cores per MPI task 
#SBATCH --nodes=1                     # Maximum number of nodes to be allocated
##SBATCH --ntasks-per-node=16         # Maximum number of tasks on each node
##SBATCH --ntasks-per-socket=16       # Maximum number of tasks on each socket
#SBATCH --distribution=cyclic:cyclic # Distribute tasks cyclically first among nodes and then among sockets within a node
##SBATCH --mem-per-cpu=64gb            # Memory (i.e. RAM) per processor
#SBATCH --time=31-24:00:00           # Wall time limit (days-hrs:min:sec)

echo "Date              = $(date)"
echo "Hostname          = $(hostname -s)"
echo "Working Directory = $(pwd)"
echo ""
echo "Number of Nodes Allocated      = $SLURM_JOB_NUM_NODES"
echo "Number of Tasks Allocated      = $SLURM_NTASKS"
echo "Number of Cores/Task Allocated = $SLURM_CPUS_PER_TASK"

##module load intel/2018.1.163 openmpi/4.0.2
##srun --mpi=pmix_v1 /ufrc/data/training/SLURM/prime/prime_mpi
#
#srun -u $HOME/bin/lmp_rhel7 -i run_equil.in

time ~/bin/voxelize_mesh.py \
  -w 18.08 \
  -m membrane_inner.ply \
  -i orig_crop.rec \
  -o membrane_inner.rec

time ~/bin/voxelize_mesh.py \
  -w 18.08 \
  -m membrane_outer.ply \
  -i orig_crop.rec \
  -o membrane_outer.rec

time ~/bin/voxelize_mesh.py \
  -w 18.08 \
  -m membrane_host.ply \
  -i orig_crop.rec \
  -o membrane_host.rec

