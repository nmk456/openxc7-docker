FROM ubuntu:20.04

ARG YOSYS_VERSION=0.17
ARG NEXTPNR_VERSION=0.5.0

RUN \
    apt update && \
    apt upgrade -y && \
    DEBIAN_FRONTEND=noninteractive TZ=America/New_York apt install -y \
        build-essential clang bison flex cmake git libreadline-dev \
        gawk tcl-dev libffi-dev pkg-config python3 libboost-system-dev \
        libboost-python-dev libboost-filesystem-dev zlib1g-dev libtcl8.6 \
        graphviz xdot gfortran python3-dev libpython3-dev python3-pip \
        python3-yaml libboost-all-dev libeigen3-dev curl gnutls-bin openssl \
        libpython3.8 libgomp1 libboost-filesystem1.71.0 \
        libboost-iostreams1.71.0 libboost-program-options1.71.0 \
        libboost-python1.71.0 libboost-thread1.71.0 python3.8-venv \
        default-jre-headless uuid-dev libantlr4-runtime-dev wget

WORKDIR /tmp/xc7-build

# Yosys - /usr/local/bin/yosys 

RUN git clone https://github.com/YosysHQ/yosys.git \
        --depth 1 --branch yosys-${YOSYS_VERSION} && \
    export PREFIX=/usr && \
    cd yosys && \
    make config-gcc && \
    make all -j$(nproc) && \
    make install

# PyJSON

RUN git clone https://github.com/Kijewski/pyjson5.git --depth 1 --recursive && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    cd pyjson5 && \
    pip3 install -r requirements-dev.txt && \
    pip3 install -r requirements-readthedocs.txt && \
    make -j$(nproc) && \
    make install

# prjxray

RUN git clone https://github.com/f4pga/prjxray.git --depth 1 --branch master --recursive && \
    cd prjxray && \
    [ -d prjxray-db ] || git clone https://github.com/f4pga/prjxray-db.git && \
    cmake -DALLOW_ROOT=1 -DCMAKE_INSTALL_PREFIX=/usr . && \
    cmake --build . -- -j$(nproc) && \
    cmake --build . --target install

# prjxray-python

RUN cd prjxray && \
    pip3 install -r requirements.txt && \
    pip3 install wheel textx intervaltree && \
    pip3 install third_party/fasm && \
    pip3 install .
# TODO: prime stuff?

# nextpnr-xilinx

RUN git clone https://github.com/openXC7/nextpnr-xilinx.git --depth 1 --recursive --branch main && \
    cd nextpnr-xilinx && \
    cmake -DARCH=xilinx -DBUILD_GUI=0 -DCMAKE_INSTALL_PREFIX=/usr . && \
    cmake --build . -- -j$(nproc) && \
    cmake --build . --target install

# bbaexport

RUN cd nextpnr-xilinx/xilinx && \
    mkdir -p /opt/nextpnr-xilinx/python && cp python/* /opt/nextpnr-xilinx/python && \
    cp constids.inc /opt/nextpnr-xilinx/

# metadata

RUN mkdir -p /opt/nextpnr-xilinx/external && \
    cp -r nextpnr-xilinx/xilinx/external/nextpnr-xilinx-meta/ /opt/nextpnr-xilinx/external/

# prjxray-db

RUN mkdir -p /opt/nextpnr-xilinx/external && \
    cp -r nextpnr-xilinx/xilinx/external/prjxray-db/ /opt/nextpnr-xilinx/external/

# prjxray-utils

RUN mkdir -p /opt/prjxray/utils/ && cp -r prjxray/utils/ /opt/prjxray/ && \
    sed -i '5i sys.path.append("/opt/prjxray/")' /usr/local/bin/*fasm* && \
    sed -i '5i sys.path.append("/lib/python3.8/site-packages/")' /usr/local/bin/*fasm* && \
    sed -i '5i sys.path.append("/usr/lib/python3/dist-packages/")' /usr/local/bin/*fasm* && \
    sed -i '5i import sys' /usr/local/bin/*fasm* && \
    cp /usr/local/bin/fasm2frames /usr/local/bin/bit2fasm && \
    sed -i '1,$s/from utils.fasm2frames/from utils.bit2fasm/g' /usr/local/bin/bit2fasm && \
    sed -i '1,1s,/usr/bin/env python3,/usr/bin/python3.8,g' /usr/local/bin/*fasm* && \
    cp -r /usr/local/lib/python3.8/dist-packages/* /usr/lib/python3/dist-packages

RUN rm -rf /tmp/xc7-build
