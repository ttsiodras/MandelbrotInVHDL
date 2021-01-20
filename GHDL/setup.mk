MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(dir $(MKFILE_PATH))

V?=0
ifeq ($(V),0)
Q=@
else
Q=
endif


