FROM jupyter/minimal-notebook
USER root

##
# Install PHP Kernel
##
# install dependencies
RUN apt-get update && apt-get install -yq --no-install-recommends \
    vim \
    pandoc \
    # build-essential \
    # python-dev \
    # libsm6 \
    # libxrender1 \
    inkscape \
    php-cli php-dev php-pear php-zip php-mysql\
    pkg-config \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install zeromq and zmq php extension
RUN wget https://github.com/zeromq/zeromq4-1/releases/download/v4.1.5/zeromq-4.1.5.tar.gz && \
    tar -xvf zeromq-4.1.5.tar.gz && \
    cd zeromq-* && \
    ./configure && make && make install && \
    printf "\n" | pecl install zmq-beta && \
    ls -lR /etc/php/ && \ 
    echo "extension=zmq.so" > /etc/php/7.2/cli/conf.d/zmq.ini

# install PHP composer
RUN wget https://getcomposer.org/installer -O composer-setup.php && \
    wget https://litipk.github.io/Jupyter-PHP-Installer/dist/jupyter-php-installer.phar && \
    php composer-setup.php && \
    php ./jupyter-php-installer.phar -vvv install && \
    mv composer.phar /usr/local/bin/composer && \
    rm -rf zeromq-* jupyter-php*

##
# Install C# Kernel
##
RUN apt-get update && apt-get install -yq --no-install-recommends \
    gnupg \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt-get update && apt-get install -yq --no-install-recommends \
    mono-complete \
    mono-dbg \
    mono-runtime-dbg \
    ca-certificates-mono \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#RUN mozroots --import --machine --sync
RUN cert-sync /etc/ssl/certs/ca-certificates.crt && \
    git clone --recursive https://github.com/zabirauf/icsharp.git /icsharp && \
    cd /icsharp/Engine && \
    mono ./.nuget/NuGet.exe restore ./ScriptCs.sln && \
    cd /icsharp && \
    mono ./.nuget/NuGet.exe restore ./iCSharp.sln && \
    xbuild ./iCSharp.sln /property:Configuration=Release /nologo /verbosity:normal && \
    mkdir -p build/Release/bin && \
    for line in $(find ./*/bin/Release/*); do cp $line ./build/Release/bin; done

# Install kernel
RUN chown -R $NB_USER:users $HOME/.local && \
    # chown -R $NB_USER:users $HOME/.mono && \
    chown -R $NB_USER:users $HOME/.nuget && \
    echo '{' > /icsharp/kernel-spec/kernel.json && \
    echo '    "argv": ["mono", "/icsharp/build/Release/bin/iCSharp.Kernel.exe", "{connection_file}"],' >> /icsharp/kernel-spec/kernel.json && \
    echo '    "display_name": "C#",' >> /icsharp/kernel-spec/kernel.json && \
    echo '    "language": "csharp"' >> /icsharp/kernel-spec/kernel.json && \
    echo '}' >> /icsharp/kernel-spec/kernel.json

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER
RUN cd /icsharp && \
    jupyter-kernelspec install --user kernel-spec

##
# Install R Kernel
##
USER root
# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc \
    gfortran \
    gcc && \
    rm -rf /var/lib/apt/lists/*

# Fix for devtools https://github.com/conda-forge/r-devtools-feedstock/issues/4
RUN ln -s /bin/tar /bin/gtar

USER $NB_UID

# R packages
RUN conda install --quiet --yes \
    'r-base=3.6.1' \
    'r-caret=6.0*' \
    'r-crayon=1.3*' \
    'r-devtools=2.0*' \
    'r-forecast=8.7*' \
    'r-hexbin=1.27*' \
    'r-htmltools=0.3*' \
    'r-htmlwidgets=1.3*' \
    'r-irkernel=1.0*' \
    'r-nycflights13=1.0*' \
    'r-plyr=1.8*' \
    'r-randomforest=4.6*' \
    'r-rcurl=1.95*' \
    'r-reshape2=1.4*' \
    'r-rmarkdown=1.14*' \
    'r-rodbc=1.3*' \
    'r-rsqlite=2.1*' \
    'r-shiny=1.3*' \
    'r-sparklyr=1.0*' \
    'r-tidyverse=1.2*' \
    'unixodbc=2.3.*' \
    && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR

# Install e1071 R package (dependency of the caret R package)
RUN conda install --quiet --yes r-e1071

# Reset user from jupyter/base-notebook
USER $NB_USER

RUN mkdir notebooks
WORKDIR ./notebooks