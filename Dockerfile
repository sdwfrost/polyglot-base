FROM jupyter/minimal-notebook:latest

LABEL maintainer="Simon Frost <sdwfrost@gmail.com>"

USER root

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -yq dist-upgrade\
    && apt-get install -yq \
    autoconf \
    automake \
    ant \
    apt-file \
    apt-utils \
    apt-transport-https \
    asymptote \
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
    ffmpeg \
    fonts-liberation \
    fonts-dejavu \
    gcc \
    gcc-multilib \
    g++ \
    g++-multilib \
    gdebi-core \
    gfortran \
    gfortran-multilib \
    ghostscript \
    ginac-tools \
    git \
    gnuplot \
    gnupg \
    gnupg-agent \
    graphviz \
    graphviz-dev \
    groovy \
    gzip \
    haskell-stack \
    lib32z1-dev \
    libatlas-base-dev \
    libc6-dev \
    libffi-dev \
    libgdal-dev \
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
    libgeos-c1v5 \
    libginac-dev \
    libginac6 \
    libgit2-dev \
    libgl1-mesa-dev \
    libgl1-mesa-glx \
    libglfw3 \
    libglfw3-dev \
    libgraphviz-dev \
    libgs-dev \
    libjsoncpp-dev \
    libnetcdf-dev \
    libopenblas-dev \
    libproj-dev \
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
    libv8-dev \
    llvm-6.0-dev \
    libclang-6.0-dev \
    lmodern \
    locales \
    m4 \
    mercurial \
    musl-dev \
    netcat \
    ocaml \
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
    opam \
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
    sqlite \
    sqlite3 \
    sudo \
    swig \
    tzdata \
    ubuntu-dev-tools \
    unzip \
    uuid-dev \
    xorg-dev \
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

RUN conda install ipython

RUN pip install \
    cython \
    gr \
    ipywidgets \
    joblib \
    jupyter-console \
    matplotlib \
    networkx \
    nteract_on_jupyter \
    nxpd \
    numba \
    numexpr \
    pandas \
    papermill \
    plotly \
    ply \
    pydot \
    pygraphviz \
    pythran \
    scipy \
    seaborn \
    setuptools \
    sympy \
    tqdm \
    tzlocal \
    ujson && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    npm cache clean --force && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions /home/$NB_USER

# R
RUN add-apt-repository ppa:marutter/rrutter3.5 && \
    apt-get update && \
    apt-get install -yq \
    r-base r-base-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/jupyter/kernels
RUN R -e "setRepositories(ind=1:2);install.packages(c(\
    'devtools'), dependencies=TRUE, clean=TRUE, repos='https://cran.microsoft.com/snapshot/2018-11-01')"
RUN R -e "devtools::install_github('IRkernel/IRkernel')" && \
    R -e "IRkernel::installspec()" && \
    mv $HOME/.local/share/jupyter/kernels/ir* /usr/local/share/jupyter/kernels/ && \
    chmod -R go+rx /usr/local/share/jupyter && \
    fix-permissions /usr/local/share/jupyter /usr/local/lib/R
RUN pip install rpy2

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
RUN choosenim update 0.19.0
RUN nimble update && \
    yes 'y' | nimble install https://github.com/stisa/jupyternim && \
    jupyternim
RUN fix-permissions ${NIMBLE_DIR}

# Julia

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.0.1

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
RUN julia -e 'using Pkg;Pkg.update()' && \
    julia -e 'using Pkg;Pkg.add("IJulia")' && \
    # Precompile Julia packages \
    julia -e 'using IJulia' && \
    # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* /usr/local/share/jupyter/kernels/ && \
    chmod -R go+rx /usr/local/share/jupyter && \
    fix-permissions $JULIA_PKGDIR /usr/local/share/jupyter

# Gnuplot
RUN pip install gnuplot_kernel && \
    python3 -m gnuplot_kernel install

# Graphviz
RUN cd /tmp && \
    git clone https://github.com/laixintao/jupyter-dot-kernel.git && \
    cd jupyter-dot-kernel && \
    jupyter kernelspec install dot_kernel_spec && \
    cd /tmp && \
    rm -rf jupyter-dot-kernel


# Asymptote magic
RUN mkdir -p ${HOME}/.ipython/extensions && \
    cd ${HOME}/.ipython/extensions && \
    wget https://raw.githubusercontent.com/jrjohansson/ipython-asymptote/master/asymptote.py

# Octave
  RUN pip install oct2py octave_kernel

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

# PARI-GP
RUN pip install pari_jupyter

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
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# GR for C
RUN cd /tmp && \
    wget https://gr-framework.org/downloads/gr-latest-Ubuntu-x86_64.tar.gz && \
    tar xvf gr-latest-Ubuntu-x86_64.tar.gz -C /usr/local --strip-components=1 && \
    rm gr-latest-Ubuntu-x86_64.tar.gz && \
    fix-permissions /usr/local

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

# MKL
RUN cd /tmp && \
    wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list' && \
    apt-get update && \
    apt-get install -yq intel-mkl-64bit-2018.2-046 && \
    update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so     libblas.so-x86_64-linux-gnu      /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
    update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so.3   libblas.so.3-x86_64-linux-gnu    /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
    update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so   liblapack.so-x86_64-linux-gnu    /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
    update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so.3 liblapack.so.3-x86_64-linux-gnu  /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
    echo "/opt/intel/lib/intel64"     >  /etc/ld.so.conf.d/mkl.conf && \
    echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/mkl.conf && \
    ldconfig && \
    echo "MKL_THREADING_LAYER=GNU" >> /etc/environment && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Rust and Rust
RUN mkdir /opt/cargo && \
    mkdir /opt/rustup
ENV CARGO_HOME=/opt/cargo \
    RUSTUP_PATH=/opt/rustup
ENV PATH=/opt/cargo/bin:$PATH
RUN cd /tmp && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    cargo install cargo-script && \
    echo '// cargo-deps: eom="0.10.0", ndarray="0.11"\nfn main(){}' > hello.rs && \
    cargo script hello.rs && \
    rm hell*
RUN cargo install evcxr_jupyter && \
    evcxr_jupyter --install && \
    mv ${HOME}/.local/share/jupyter/kernels/rust /usr/local/share/jupyter/kernels/rust && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# Haskell
RUN mkdir ${HOME}/.stack && \
    fix-permissions ${HOME}/.stack
RUN stack upgrade
ENV PATH=/home/jovyan/.local/bin:$PATH
RUN cd /tmp && \
    git clone https://github.com/gibiansky/IHaskell && \
    cd IHaskell && \
    pip install jupyter \
    jupyter_nbextensions_configurator \
    jupyter_contrib_nbextensions \
    ipykernel \
    ipywidgets \
    jupyter-client \
    jupyter-console \
    jupyter-core && \
    stack install gtk2hs-buildtools && \
    stack install --fast && \
    ihaskell install --stack && \
    rm -rf /home/$NB_USER/.cache/pip && \
    mv ${HOME}/.local/share/jupyter/kernels/haskell /usr/local/share/jupyter/kernels/haskell && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# Node
RUN mkdir /opt/npm && \
    echo 'prefix=/opt/npm' >> ${HOME}/.npmrc 
ENV PATH=/opt/npm/bin:$PATH
ENV NODE_PATH=/opt/npm/lib/node_modules
RUN fix-permissions /opt/npm

# Go
RUN cd /tmp && \
    wget https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz && \
    mkdir /opt/go && \
    tar xvf go1.11.2.linux-amd64.tar.gz -C /opt/go --strip-components=1 && \
    rm go1.11.2.linux-amd64.tar.gz && \
    fix-permissions /opt/go
ENV GOPATH=${HOME}/.local/go
ENV PATH=/opt/go/bin:${HOME}/.local/go/bin:$PATH
RUN go get -u github.com/gopherdata/gophernotes && \
    mkdir -p /usr/local/share/jupyter/kernels/gophernotes && \
    cp $GOPATH/src/github.com/gopherdata/gophernotes/kernel/* /usr/local/share/jupyter/kernels/gophernotes
RUN fix-permissions $GOPATH /usr/local/share/jupyter/kernels

# .Net
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt update && \
    apt-get install -yq --no-install-recommends mono-complete \
    mono-dbg \
    mono-csharp-shell \
    mono-runtime-dbg \
    fsharp && \
    mozroots --import --machine --sync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb && \
    yes 'y' | dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
    dotnet-sdk-2.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# F#
RUN cd /opt && \
    mkdir ifsharp && \
    cd ifsharp && \
    wget https://github.com/fsprojects/IfSharp/releases/download/v3.0.0/IfSharp.v3.0.0.zip && \
    unzip IfSharp.v3.0.0.zip && \
    mono ifsharp.exe && \
    mv ${HOME}/.local/share/jupyter/kernels/ifsharp /usr/local/share/jupyter/kernels/ifsharp && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME} /opt/ifsharp

# OCAML
RUN yes 'y' | opam init
ENV CAML_LD_LIBRARY_PATH=/home/jovyan/.opam/system/lib/stublibs:/usr/lib/ocaml/stublibs
ENV MANPATH=/home/jovyan/.opam/system/man:$MANPATH
ENV PERL5LIB=/home/jovyan/.opam/system/lib/perl5:$PERL5LIB
ENV OCAML_TOPLEVEL_PATH=/home/jovyan/.opam/system/lib/toplevel
ENV PATH=/home/jovyan/.opam/system/bin:$PATH
RUN yes 'Y' | opam install jupyter && \
    yes 'Y' | opam install jupyter-archimedes && \
    jupyter kernelspec install --name ocaml-jupyter "$(opam config var share)/jupyter"
RUN fix-permissions ${HOME}/.opam ${HOME}/.local

# SBCL
RUN cd /opt && \
    git clone https://github.com/fredokun/cl-jupyter && \
    cd cl-jupyter && \
    python3 ./install-cl-jupyter.py && \
    sbcl --load /opt/quicklisp/setup.lisp --non-interactive ./cl-jupyter.lisp && \
    sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:update-all-dists)' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "alexandria")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "babel")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "cffi")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "pzmq")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "trivial-features")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "ironclad")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "nibbles")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "trivial-utf-8")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "uuid")' && \
    yes 'y' | sbcl --load /opt/quicklisp/setup.lisp --non-interactive --eval '(ql:quickload "cl-base64")' && \
    mv ${HOME}/.ipython/kernels/lisp /usr/local/share/jupyter/kernels/lisp && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# YACAS
RUN cd /opt && \
    git clone https://github.com/grzegorzmazur/yacas && \
    cd yacas && \
    git checkout develop && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_CYACAS_GUI=0 -DENABLE_CYACAS_KERNEL=1  .. && \
    make && \
    make install && \
    fix-permissions /usr/local/share/jupyter/kernels ${HOME}

# JVM languages
## kotlin
RUN cd /opt && \
    wget https://github.com/JetBrains/kotlin/releases/download/v1.3-M2/kotlin-compiler-1.3-M2.zip && \
    unzip kotlin-compiler-1.3-M2.zip && \
    rm kotlin-compiler-1.3-M2.zip && \
    cd /opt/kotlinc/bin && \
    chmod +x kotli* && \
    fix-permissions /opt/kotlinc
ENV PATH=/opt/kotlinc/bin:$PATH

## Scala
RUN cd /tmp && \
    wget www.scala-lang.org/files/archive/scala-2.13.0-M5.deb && \
    dpkg -i scala-2.13.0-M5.deb && \
    rm scala-2.13.0-M5.deb

## Clojure
RUN cd /tmp && \
    curl -O https://download.clojure.org/install/linux-install-1.9.0.391.sh && \
    chmod +x linux-install-1.9.0.391.sh && \
    yes 'y' | bash ./linux-install-1.9.0.391.sh && \
    rm linux-install-1.9.0.391.sh

RUN pip install beakerx && \
    beakerx install --prefix /usr/local && \
    jupyter nbextension enable beakerx --py --system && \
    rm -rf /home/$NB_USER/.cache/pip && \
    fix-permissions /home/$NB_USER /usr/local/share/jupyter/kernels

# SOS
RUN pip install sos sos-notebook && \
    python3 -m sos_notebook.install

# Stan
RUN cd /opt && \
    git clone https://github.com/stan-dev/cmdstan.git --recursive && \
    cd cmdstan && \
    make build
ENV PATH=/opt/cmdstan/bin:$PATH
ENV JULIA_CMDSTAN_HOME=/opt/cmdstan

USER ${NB_USER}

RUN npm install -g ijavascript \
    plotly-notebook-js && \
    ijsinstall

USER root
RUN mv ${HOME}/.local/share/jupyter/kernels/javascript /usr/local/share/jupyter/kernels/javascript

# Tidy up permissions and ownership
RUN fix-permissions /tmp /opt ${HOME} /usr/local/share/jupyter/kernels /usr/local/lib/python3.6 && \
    chown -R ${NB_USER}:users /opt && \
    chown -R ${NB_USER}:users /tmp && \
    chown -R ${NB_USER}:users ${HOME}

USER ${NB_USER}
RUN cd ${HOME}
