# Project settings
PART = xc7a35tcpg236-1
TARGET = blinky
SRC = src/blinky.v
CONSTRAINTS = src/blinky.xdc
TOP = ${TARGET}
BUILD_DIR = build

# Docker folders
DB_DIR = /opt/nextpnr-xilinx/external/prjxray-db
CHIPDB = /opt/chipdb

# Docker setup
DOCKER_IMAGE = openxc7:latest
DOCKER_PROJECT_DIR = /project
DOCKER_CMD = docker run -it --init --rm --user $(shell id -u):$(shell id -g) \
	--name="${TARGET}_build" \
	-v ${CHIPDB}:${CHIPDB} \
	-v $(shell pwd):${DOCKER_PROJECT_DIR} \
	-w ${DOCKER_PROJECT_DIR} \
	${DOCKER_IMAGE}

.PHONY: all
all: ${BUILD_DIR}/${TARGET}.bit

.PHONY: program
program: ${BUILD_DIR}/${TARGET}.bit
	openFPGALoader --board basys3 --bitstream $<

${BUILD_DIR}/${TARGET}.json: ${SRC}
	mkdir -p ${BUILD_DIR}
	${DOCKER_CMD} bash -c "\
	yosys -q -L ${DOCKER_PROJECT_DIR}/${BUILD_DIR}/yosys.log -p 'synth_xilinx -flatten -abc9 -nobram -arch xc7 -top ${TOP}; \
		write_json ${DOCKER_PROJECT_DIR}/${BUILD_DIR}/${TARGET}.json' $(foreach x,$(SRC),${DOCKER_PROJECT_DIR}/$(x))"

# The chip database only needs to be generated once
# that is why we don't clean it with make clean
${CHIPDB}/${PART}.bin:
	${DOCKER_CMD} bash -c "\
	python3 /opt/nextpnr-xilinx/python/bbaexport.py --device ${PART} --bba ${PART}.bba && \
	bbasm -l ${PART}.bba ${CHIPDB}/${PART}.bin && \
	rm -f ${PART}.bba"

${BUILD_DIR}/${TARGET}.fasm: ${BUILD_DIR}/${TARGET}.json ${CHIPDB}/${PART}.bin
	${DOCKER_CMD} bash -c "\
	nextpnr-xilinx -ql ${DOCKER_PROJECT_DIR}/${BUILD_DIR}/nextpnr.log --chipdb ${CHIPDB}/${PART}.bin $(foreach x,$(CONSTRAINTS),--xdc ${DOCKER_PROJECT_DIR}/$(x)) --json ${DOCKER_PROJECT_DIR}/${BUILD_DIR}/${TARGET}.json --fasm ${DOCKER_PROJECT_DIR}/$@"

${BUILD_DIR}/${TARGET}.frames: ${BUILD_DIR}/${TARGET}.fasm
	${DOCKER_CMD} bash -c "\
	fasm2frames --part ${PART} --db-root ${DB_DIR}/artix7 ${DOCKER_PROJECT_DIR}/$< > ${DOCKER_PROJECT_DIR}/$@"

${BUILD_DIR}/${TARGET}.bit: ${BUILD_DIR}/${TARGET}.frames
	${DOCKER_CMD} bash -c "\
	xc7frames2bit --part_file ${DB_DIR}/artix7/${PART}/part.yaml --part_name ${PART} --frm_file ${DOCKER_PROJECT_DIR}/$< --output_file ${DOCKER_PROJECT_DIR}/$@"

.PHONY: clean
clean:
	@rm -f ${BUILD_DIR}/*.bit
	@rm -f ${BUILD_DIR}/*.frames
	@rm -f ${BUILD_DIR}/*.fasm
	@rm -f ${BUILD_DIR}/*.json
