# Use the official Ubuntu 20.04 image as the base
FROM ubuntu:20.04

# Set environment variables
ENV OMPI_DIR=/opt/ompi \
    OMPI_VERSION=4.1.7 \
    OMPI_URL=https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.7.tar.bz2 \
    TZ=America/Indiana/Indianapolis \
    OMPI_MCA_btl_vader_single_copy_mechanism=none \
    OMPI_MCA_btl_openib_allow_ib=1

# Update the system and install required packages
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget git bash gcc gfortran g++ make file cmake hwloc libpmi2-0 libpmi2-0-dev \
    libglpk-dev libzip-dev libarmadillo-dev libboost-all-dev libblas-dev liblapack-dev && \
    echo "Installing Open MPI" && \
    mkdir -p /tmp/ompi /opt && \
    cd /tmp/ompi && \
    wget --no-check-certificate -O openmpi-$OMPI_VERSION.tar.bz2 $OMPI_URL && \
    tar -xjf openmpi-$OMPI_VERSION.tar.bz2 && \
    cd openmpi-$OMPI_VERSION && \
    ./configure --prefix=$OMPI_DIR --with-hwloc=internal --with-slurm --with-pmi=/usr --with-pmi-libdir=/usr/lib/x86_64-linux-gnu && \
    make -j$(nproc) install && \
    echo "Compiling the MPI application..." && \
    export PATH=$OMPI_DIR/bin:$PATH && \
    export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH && \
    cd /opt && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/ompi

# Add Open MPI environment variables to PATH
ENV PATH="$OMPI_DIR/bin:$PATH" \
    LD_LIBRARY_PATH="$OMPI_DIR/lib:$LD_LIBRARY_PATH" \
    MANPATH="$OMPI_DIR/share/man:$MANPATH" \
    OMPI_MCA_btl=tcp,self
# Set the default command
CMD ["/bin/bash"]
