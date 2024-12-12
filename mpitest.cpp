#include <mpi.h>
#include <iostream>
#include <vector>
#include <unistd.h> // For gethostname()

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);  // Get process rank
    MPI_Comm_size(MPI_COMM_WORLD, &size);  // Get total number of processes

    char hostname[256];
    gethostname(hostname, sizeof(hostname));  // Get the node name

    int num_cpus = sysconf(_SC_NPROCESSORS_ONLN);  // Get the number of CPUs on the node

    // Print information for each rank
    std::cout << "Rank: " << rank 
              << ", Hostname: " << hostname 
              << ", CPUs: " << num_cpus 
              << ", Total MPI Processes: " << size 
              << std::endl;

    MPI_Finalize();
    return 0;
}