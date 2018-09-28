FROM jupyter/minimal-notebook:latest

LABEL maintainer="Simon Frost <sdwfrost@gmail.com>"

USER root

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -yq dist-upgrade\
    && apt-get install -yq --no-install-recommends \
    autoconf \
    automake \
    ant \
    apt-file \
    apt-utils \
    apt-transport-https \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    darcs \
    debhelper \
    devscripts \
    dirmngr \
    ed \
    fonts-liberation \
    fonts-dejavu \
    gcc \
    gdebi-core \
    gfortran \
    ghostscript \
    ginac-tools \
    git \
    gnuplot \
    gnupg \
    gnupg-agent \
    gzip \
    haskell-stack \
    libffi-dev \
    libgmp-dev \
    libgsl0-dev \
    libtinfo-dev \
    libzmq3-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libmagic-dev \
    libblas-dev \
    liblapack-dev \
    libboost-all-dev \
    libcln-dev \
    libcurl4-gnutls-dev \
    libgeos-dev \
    libginac-dev \
    libginac6 \
    libgit2-dev \
    libgl1-mesa-glx \
    libgs-dev \
    libjsoncpp-dev \
    libnetcdf-dev \
    libqrupdate-dev \
    libqt5widgets5 \
    libsm6 \
    libssl-dev \
    libudunits2-0 \
    libudunits2-dev \
    libunwind-dev \
    libxext-dev \
    libxml2-dev \
    libxrender1 \
    libxt6 \
    libzmqpp-dev \
    lmodern \
    locales \
    mercurial \
    netcat \
    octave \
    octave-dataframe \
    octave-general \
    octave-gsl \
    octave-nlopt \
    octave-odepkg \
    octave-optim \
    octave-symbolic \
    octave-miscellaneous \
    octave-missing-functions \
    octave-pkg-dev \
    openjdk-8-jdk \
    openjdk-8-jre \
    pandoc \
    pari-gp \
    pari-gp2c \
    pbuilder \
    pkg-config \
    psmisc \
    python3-dev \
    rsync \
    sbcl \
    software-properties-common \
    sudo \
    swig \
    tzdata \
    ubuntu-dev-tools \
    unzip \
    uuid-dev \
    wget \
    xz-utils \
    zlib1g-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -yq --no-install-recommends \
    nodejs \
    nodejs-legacy \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV HOME=/home/$NB_USER

# Python libraries
RUN pip install \
    cython \
    gr \
    ipywidgets \
    matplotlib \
    nteract_on_jupyter \
    numba \
    numexpr \
    pandas \
    papermill \
    plotly \
    scipy \
    seaborn \
    setuptools \
    sympy \
    tzlocal && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    npm cache clean --force && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions /home/$NB_USER

RUN add-apt-repository ppa:marutter/rrutter && \
    apt-get update && \
    apt-get install -yq \
    r-base r-base-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN mkdir -p /usr/local/share/jupyter/kernels
RUN R -e "setRepositories(ind=1:2);install.packages(c(\
    'devtools'), dependencies=TRUE, clean=TRUE, repos='https://cran.microsoft.com/snapshot/2018-09-01')"
RUN R -e "devtools::install_github('IRkernel/IRkernel')" && \
    R -e "IRkernel::installspec()" && \
    mv $HOME/.local/share/jupyter/kernels/ir* /usr/local/share/jupyter/kernels/ && \
    chmod -R go+rx /usr/local/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions /usr/local/share/jupyter /usr/local/lib/R
RUN pip install rpy2
RUN R -e "devtools::install_github('mrc-ide/odin',upgrade=FALSE)"

# Libbi 
RUN cd /tmp && \
    wget https://github.com/thrust/thrust/releases/download/1.8.2/thrust-1.8.2.zip && \
    unzip thrust-1.8.2.zip && \
    mv thrust /usr/local/include && \
    rm thrust-1.8.2.zip && \
    fix-permissions /usr/local/include
RUN cd /opt && \
    git clone https://github.com/lawmurray/LibBi && \
    cd LibBi && \
    PERL_MM_USE_DEFAULT=1  cpan . && \
    fix-permissions /opt/LibBi
ENV PATH=/opt/LibBi/script:$PATH
RUN R -e "install.packages('rbi')"

# Nim
ENV NIMBLE_DIR=${HOME}/.nimble
RUN mkdir ${NIMBLE_DIR} && \
    cd ${NIMBLE_DIR} && \
    mkdir bin && \
    cd bin && \
    curl https://nim-lang.org/choosenim/init.sh -sSf > choosenim.sh && \
    chmod +x ./choosenim.sh && \
    ./choosenim.sh -y
ENV PATH=${NIMBLE_DIR}/bin:$PATH
RUN choosenim update 0.18.0
RUN fix-permissions ${NIMBLE_DIR}
RUN nimble update
RUN cd /opt && \
    git clone https://github.com/stisa/jupyternim && \
    cd jupyternim && \
    nimble -y build --nilseqs:on && \
    # ./jupyternim && \
    fix-permissions /opt/jupyternim

# Julia
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=0.6.4

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    # echo "dc6ec0b13551ce78083a5849268b20684421d46a7ec46b17ec1fab88a5078580 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

# Show Julia where libraries are \
RUN mkdir /etc/julia && \
    # Create JULIA_PKGDIR \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

# Add Julia packages.
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia -e 'Pkg.init()' && \
    julia -e 'Pkg.update()' && \
    julia -e 'Pkg.add("IJulia")' && \
    # Precompile Julia packages \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* /usr/local/share/jupyter/kernels/ && \
    chmod -R go+rx /usr/local/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR /usr/local/share/jupyter

# Add gnuplot kernel
RUN pip install gnuplot_kernel && \
    python3 -m gnuplot_kernel install

# Octave
  RUN pip install octave_kernel

# XPP
ENV XPP_DIR=/opt/xppaut
RUN mkdir /opt/xppaut && \
    cd /tmp && \
    wget http://www.math.pitt.edu/~bard/bardware/xppaut_latest.tar.gz && \
    tar xvf xppaut_latest.tar.gz -C /opt/xppaut && \
    cd /opt/xppaut && \
    make && \
    ln -fs /opt/xppaut/xppaut /usr/local/bin/xppaut && \
    rm /tmp/xppaut_latest.tar.gz && \
    fix-permissions $XPP_DIR /usr/local/bin

# VFGEN
# First needs MiniXML
RUN cd /tmp && \
    mkdir /tmp/mxml && \
    wget https://github.com/michaelrsweet/mxml/releases/download/v2.11/mxml-2.11.tar.gz && \
    tar xvf mxml-2.11.tar.gz -C /tmp/mxml && \
    cd /tmp/mxml && \
    ./configure && \
    make && \
    make install && \
    cd /tmp && \
    rm mxml-2.11.tar.gz && \
    rm -rf /tmp/mxml
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN mkdir /opt/vfgen && \
    cd /tmp && \
    git clone https://github.com/WarrenWeckesser/vfgen && \
    cd vfgen/src && \
    make -f Makefile.vfgen && \
    cp ./vfgen /opt/vfgen && \
    cd /tmp && \
    rm -rf vfgen && \
    ln -fs /opt/vfgen/vfgen /usr/local/bin/vfgen

# Maxima
RUN cd /tmp && \
    git clone https://github.com/andrejv/maxima && \
    cd maxima && \
    sh bootstrap && \
    ./configure --enable-sbcl && \
    make && \
    make install && \
    cd /tmp && \
    rm -rf maxima
RUN mkdir /opt/quicklisp && \
    cd /tmp && \
    curl -O https://beta.quicklisp.org/quicklisp.lisp && \
    sbcl --load quicklisp.lisp --non-interactive --eval '(quicklisp-quickstart:install :path "/opt/quicklisp/")' && \
    yes '' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:add-to-init-file)' && \
    rm quicklisp.lisp && \
    fix-permissions /opt/quicklisp
RUN cd /opt && \
    git clone https://github.com/robert-dodier/maxima-jupyter && \
    cd maxima-jupyter && \
    python3 ./install-maxima-jupyter.py --root=/opt/maxima-jupyter && \
    sbcl --load /opt/quicklisp/setup.lisp --non-interactive load-maxima-jupyter.lisp && \
    fix-permissions /opt/maxima-jupyter /usr/local/share/jupyter/kernels

# Scilab
ENV SCILAB_VERSION=6.0.1
ENV SCILAB_EXECUTABLE=/usr/local/bin/scilab-adv-cli
RUN mkdir /opt/scilab-${SCILAB_VERSION} && \
    cd /tmp && \
    wget http://www.scilab.org/download/6.0.1/scilab-${SCILAB_VERSION}.bin.linux-x86_64.tar.gz && \
    tar xvf scilab-${SCILAB_VERSION}.bin.linux-x86_64.tar.gz -C /opt/scilab-${SCILAB_VERSION} --strip-components=1 && \
    rm /tmp/scilab-${SCILAB_VERSION}.bin.linux-x86_64.tar.gz && \
    ln -fs /opt/scilab-${SCILAB_VERSION}/bin/scilab-adv-cli /usr/local/bin/scilab-adv-cli && \
    ln -fs /opt/scilab-${SCILAB_VERSION}/bin/scilab-cli /usr/local/bin/scilab-cli && \
    pip install scilab_kernel

# C
RUN pip install cffi_magic \
    jupyter-c-kernel && \
    install_c_kernel && \
    rm -rf /home/$NB_USER/.cache/pip && \
    mv ${HOME}/.local/share/jupyter/kernels/c /usr/local/share/jupyter/kernels/c && \
    rm -rf  ${HOME}/.local && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# Fortran
RUN cd /tmp && \
    git clone https://github.com/ZedThree/jupyter-fortran-kernel && \
    cd jupyter-fortran-kernel && \
    pip install . && \
    jupyter-kernelspec install fortran_spec/ && \
    cd /tmp && \
    rm -rf jupyter-fortran-kernel && \
    rm -rf /home/$NB_USER/.cache/pip && \    
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# C++
RUN conda install xeus-cling xtensor xtensor-blas -c conda-forge -c QuantStack
RUN fix-permissions /opt/conda

# Node
RUN mkdir /opt/npm && \
    echo 'prefix=/opt/npm' >> ${HOME}/.npmrc 
ENV PATH=/opt/npm/bin:$PATH
ENV NODE_PATH=/opt/npm/lib/node_modules
RUN fix-permissions /opt/npm

USER ${NB_USER}

RUN npm install -g ijavascript \
    plotly-notebook-js \
    ode-rk4 && \
    ijsinstall

USER root
RUN mv ${HOME}/.local/share/jupyter/kernels/javascript /usr/local/share/jupyter/kernels/javascript && \
    rm -rf ${HOME}/.local && \
    fix-permissions /opt/npm ${HOME} /usr/local/share/jupyter/kernels && \
    fix-permissions /usr/local/lib/python3.6 ${HOME}/.cache ${HOME} /opt/conda

USER ${NB_USER}
RUN cd ${HOME}
