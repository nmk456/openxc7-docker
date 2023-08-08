# OpenXC7 Docker

A Docker image for the OpenXC7 toolchain.

Based on:
* https://github.com/openXC7/openXC7-snap
* https://github.com/openXC7/yosys-snap
* https://github.com/openXC7/demo-projects

Basically everything in this project was copied from those projects and simply refractored to work in Docker.

## Usage

* Build image (see below)
    * Eventually image will be uploaded to Docker hub so building isn't required
* Set up chip database
    * Each chip need a relatively large database generated to be generated. These only need to be built once per chip so we store them on /opt/chipdb for use across multiple projects. This location can be changed, but it must be created and the user must have write permissions for it before building anything. These take up on the order of 100 MB each.
* Build example
    * `cd example-basys`
    * `make`
* Add to your own project
    * Copy Makefile from example
    * Change the following settings at the top of the Makefile:
        * PART - the target FPGA, for a list of options see [prjxray-db](https://github.com/f4pga/prjxray-db)
        * TARGET - project name, doesn't have to be anything specific but this will be the filename of the generated bitstream and intermediate files
        * SRC - a list of source verilog files, separated by spaces
        * CONSTRAINTS - a list of constraint files, separated by spaces
        * TOP - the name of the top module
        * BUILD_DIR - name of the directory to contain the outputs, will be created if it does not exist

## Building Image

Building will several minutes (x minutes on an i5-6500) and the image will be about 3.5 GB (7.5GB without `--squash`).

Run `docker build --pull --rm --squash -t openxc7:latest .`

`--squash` required experimental features in Docker to be enabled. It reduces image size by about 1/2 but can be omitted for testing.
