# Build stage with Spack pre-installed and ready to be used
FROM spack/rockylinux8:latest as builder


# What we want to install and how we want to install it
# is specified in a manifest file (spack.yaml)
RUN mkdir -p /opt/spack-environment && \
set -o noclobber \
&&  (echo spack: \
&&   echo '  specs:' \
&&   echo '  - osu-micro-benchmarks' \
&&   echo '  - openmpi@4.1.6 fabrics=ofi +pmi +legacylaunchers' \
&&   echo '  - libfabric fabrics=sockets,tcp,udp,psm2,verbs' \
&&   echo '  concretizer:' \
&&   echo '    unify: true' \
&&   echo '  config:' \
&&   echo '    install_tree: /opt/software' \
&&   echo '  view: /opt/views/view') > /opt/spack-environment/spack.yaml

# Install the software, remove unnecessary deps
RUN  source /opt/spack/share/spack/setup-env.sh \ 
    && cd /opt/spack-environment && spack env activate . && spack install --fail-fast && spack gc -y

# Strip all the binaries
RUN find -L /opt/views/view/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip

# Modifications to the environment that are necessary to run
RUN cd /opt/spack-environment && \
    spack env activate --sh -d . > activate.sh
    
# Bare OS image to run the installed executables
FROM docker.io/rockylinux:8

COPY --from=builder /opt/spack-environment /opt/spack-environment
COPY --from=builder /opt/software /opt/software

# paths.view is a symlink, so copy the parent to avoid dereferencing and duplicating it
COPY --from=builder /opt/views /opt/views

RUN { \
      echo '#!/bin/sh' \
      && echo '.' /opt/spack-environment/activate.sh \
      && echo 'exec "$@"'; \
    } > /entrypoint.sh \
&& chmod a+x /entrypoint.sh \
&& ln -s /opt/views/view /opt/view


RUN dnf update -y && dnf install -y epel-release && dnf update -y \
 && dnf install -y libgfortran \
 && rm -rf /var/cache/dnf && dnf clean all

ENV PATH="/opt/view/bin:$PATH"
LABEL "mpi"="openmpi"
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/bin/bash" ]

