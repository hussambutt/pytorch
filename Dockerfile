FROM nvidia/cuda:11.0.3-devel-centos7

ENV PYTHON_VERSION=3.6.10

ENV CONDA_DIR=/opt/conda

ENV PATH="${CONDA_DIR}/bin:${PATH}"

RUN yum install -y \
    # libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
    # libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 \
    build-essential \
    cmake \
    git \
    curl \
    vim \
    tmux \
    mlocate \
    htop \
    ca-certificates \
    wget \
    # libnccl2=2.0.5-3+cuda9.0 \
    # libnccl-dev=2.0.5-3+cuda9.0 \
    libjpeg-dev \
    libpng-dev &&\
    rm -rf /var/lib/apt/lists/*

# RUN wget https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda-repo-rhel7-11-3-local-11.3.1_465.19.01-1.x86_64.rpm && \
#     rpm -i cuda-repo-rhel7-11-3-local-11.3.1_465.19.01-1.x86_64.rpm && \
#     yum -y install nvidia-driver-latest-dkms cuda && \
#     yum -y install cuda-drivers && \
#     yum clean all

# ---- Miniforge installer ----
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
# Check https://github.com/conda-forge/miniforge/releases
# Conda version
ARG conda_version="4.10.1"
# Miniforge installer patch version
ARG miniforge_patch_number="5"
# Miniforge installer architecture
ARG miniforge_arch="x86_64"
# Package Manager and Python implementation to use (https://github.com/conda-forge/miniforge)
# - conda only: either Miniforge3 to use Python or Miniforge-pypy3 to use PyPy
# - conda + mamba: either Mambaforge to use Python or Mambaforge-pypy3 to use PyPy
ARG miniforge_python="Mambaforge"

# Miniforge archive to install
ARG miniforge_version="${conda_version}-${miniforge_patch_number}"
# Miniforge installer
ARG miniforge_installer="${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh"
# Miniforge checksum
ARG miniforge_checksum="069e151cae85ed4747721e938e7974aa00889a1ae87cff33ddbdde9530fc4c6d"

RUN wget --quiet "https://github.com/conda-forge/miniforge/releases/download/${miniforge_version}/${miniforge_installer}" && \
    echo "${miniforge_checksum} *${miniforge_installer}" | sha256sum --check && \
    /bin/bash "${miniforge_installer}" -f -b -p "${CONDA_DIR}" && \
    rm "${miniforge_installer}" && \
    # Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html
    echo "conda ${CONDA_VERSION}" >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    if [[ "${PYTHON_VERSION}" != "default" ]]; then conda install --yes python="${PYTHON_VERSION}"; fi && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    conda install --quiet --yes \
    "conda=${CONDA_VERSION}" \
    'pip' && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    rm -rf "/home/${NB_USER}/.cache/yarn"

# RUN curl -o ~/anaconda3-latest.sh -O https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh  && \
#     chmod +x ~/anaconda3-latest.sh && \
#     ~/anaconda3-latest.sh -b -p "${CONDA_DIR}" && \
#     rm ~/anaconda3-latest.sh && \
#     conda install conda-build && \
#     conda create -y cuda11 python=${PYTHON_VERSION} \
#     conda clean -ya

# ENV PATH /opt/conda/envs/cuda11/bin:$PATHs

#RUN conda install pytorch torchvision torchaudio cudatoolkit=11.1 -c pytorch -c nvidia
# RUN conda activate cuda11 && \
RUN pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html
