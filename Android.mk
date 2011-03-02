#
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ifneq ($(TARGET_SIMULATOR),true)

LOCAL_PATH := $(call my-dir)

LLVM_ROOT_PATH := external/llvm

# Extract Configuration from Cache.h

libbcc_GET_CONFIG = $(shell cat "$(LOCAL_PATH)/Config.h" | \
                            grep "^\#define $1 [01]$$" | \
                            cut -d ' ' -f 3)

libbcc_USE_CACHE := $(call libbcc_GET_CONFIG,USE_CACHE)
libbcc_USE_DISASSEMBLER := $(call libbcc_GET_CONFIG,USE_DISASSEMBLER)
libbcc_USE_DISASSEMBLER_FILE := $(call libbcc_GET_CONFIG,USE_DISASSEMBLER_FILE)
libbcc_USE_LIBBCC_SHA1SUM := $(call libbcc_GET_CONFIG,USE_LIBBCC_SHA1SUM)

# Source Files

libbcc_SRC_FILES := \
  lib/ExecutionEngine/bcc.cpp \
  lib/CodeGen/CodeEmitter.cpp \
  lib/CodeGen/CodeMemoryManager.cpp \
  lib/ExecutionEngine/Compiler.cpp \
  lib/ExecutionEngine/ContextManager.cpp \
  lib/ExecutionEngine/FileHandle.cpp \
  lib/ExecutionEngine/Runtime.c \
  lib/ExecutionEngine/RuntimeStub.c \
  lib/ExecutionEngine/Script.cpp \
  lib/ExecutionEngine/ScriptCompiled.cpp \
  lib/ExecutionEngine/SourceInfo.cpp

ifeq ($(libbcc_USE_CACHE),1)
libbcc_SRC_FILES += \
  lib/ExecutionEngine/CacheReader.cpp \
  lib/ExecutionEngine/CacheWriter.cpp \
  lib/ExecutionEngine/ScriptCached.cpp \
  lib/ExecutionEngine/Sha1Helper.cpp \
  helper/sha1.c
endif

#
# Shared library for target
# ========================================================
include $(CLEAR_VARS)
LOCAL_PRELINK_MODULE := false
LOCAL_MODULE := libbcc
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := \
  $(libbcc_SRC_FILES)

ifeq ($(TARGET_ARCH),arm)
  LOCAL_SRC_FILES += \
    runtime/lib/arm/adddf3vfp.S \
    runtime/lib/arm/addsf3vfp.S \
    runtime/lib/arm/divdf3vfp.S \
    runtime/lib/arm/divsf3vfp.S \
    runtime/lib/arm/eqdf2vfp.S \
    runtime/lib/arm/eqsf2vfp.S \
    runtime/lib/arm/extendsfdf2vfp.S \
    runtime/lib/arm/fixdfsivfp.S \
    runtime/lib/arm/fixsfsivfp.S \
    runtime/lib/arm/fixunsdfsivfp.S \
    runtime/lib/arm/fixunssfsivfp.S \
    runtime/lib/arm/floatsidfvfp.S \
    runtime/lib/arm/floatsisfvfp.S \
    runtime/lib/arm/floatunssidfvfp.S \
    runtime/lib/arm/floatunssisfvfp.S \
    runtime/lib/arm/gedf2vfp.S \
    runtime/lib/arm/gesf2vfp.S \
    runtime/lib/arm/gtdf2vfp.S \
    runtime/lib/arm/gtsf2vfp.S \
    runtime/lib/arm/ledf2vfp.S \
    runtime/lib/arm/lesf2vfp.S \
    runtime/lib/arm/ltdf2vfp.S \
    runtime/lib/arm/ltsf2vfp.S \
    runtime/lib/arm/muldf3vfp.S \
    runtime/lib/arm/mulsf3vfp.S \
    runtime/lib/arm/nedf2vfp.S \
    runtime/lib/arm/negdf2vfp.S \
    runtime/lib/arm/negsf2vfp.S \
    runtime/lib/arm/nesf2vfp.S \
    runtime/lib/arm/subdf3vfp.S \
    runtime/lib/arm/subsf3vfp.S \
    runtime/lib/arm/truncdfsf2vfp.S \
    runtime/lib/arm/unorddf2vfp.S \
    runtime/lib/arm/unordsf2vfp.S
else
  ifeq ($(TARGET_ARCH),x86) # We don't support x86-64 right now
    LOCAL_SRC_FILES += \
      runtime/lib/i386/ashldi3.S \
      runtime/lib/i386/ashrdi3.S \
      runtime/lib/i386/divdi3.S \
      runtime/lib/i386/floatdidf.S \
      runtime/lib/i386/floatdisf.S \
      runtime/lib/i386/floatdixf.S \
      runtime/lib/i386/floatundidf.S \
      runtime/lib/i386/floatundisf.S \
      runtime/lib/i386/floatundixf.S \
      runtime/lib/i386/lshrdi3.S \
      runtime/lib/i386/moddi3.S \
      runtime/lib/i386/muldi3.S \
      runtime/lib/i386/udivdi3.S \
      runtime/lib/i386/umoddi3.S
  else
    $(error Unsupported TARGET_ARCH $(TARGET_ARCH))
  endif
endif

ifeq ($(TARGET_ARCH),arm)
  LOCAL_STATIC_LIBRARIES := \
    libLLVMARMCodeGen \
    libLLVMARMInfo
else
  ifeq ($(TARGET_ARCH),x86) # We don't support x86-64 right now
    LOCAL_STATIC_LIBRARIES := \
      libLLVMX86CodeGen \
      libLLVMX86Info
  else
    $(error Unsupported TARGET_ARCH $(TARGET_ARCH))
  endif
endif

LOCAL_STATIC_LIBRARIES += \
  libLLVMBitReader \
  libLLVMSelectionDAG \
  libLLVMAsmPrinter \
  libLLVMCodeGen \
  libLLVMLinker \
  libLLVMJIT \
  libLLVMTarget \
  libLLVMMC \
  libLLVMScalarOpts \
  libLLVMInstCombine \
  libLLVMipo \
  libLLVMipa \
  libLLVMTransformUtils \
  libLLVMCore \
  libLLVMSupport \
  libLLVMSystem \
  libLLVMAnalysis

LOCAL_SHARED_LIBRARIES := libdl libcutils libutils libstlport

LOCAL_C_INCLUDES := \
  $(LOCAL_PATH)/lib/ExecutionEngine \
  $(LOCAL_PATH)/lib/CodeGen \
  $(LOCAL_PATH)/helper \
  $(LOCAL_PATH)/include \
  $(LOCAL_PATH)

ifeq ($(libbcc_USE_DISASSEMBLER),1)
  ifeq ($(TARGET_ARCH),arm)
    LOCAL_STATIC_LIBRARIES += \
      libLLVMARMDisassembler \
      libLLVMARMAsmPrinter
  else
    ifeq ($(TARGET_ARCH),x86)
      LOCAL_STATIC_LIBRARIES += \
        libLLVMX86Disassembler \
        libLLVMX86AsmPrinter \
        libLLVMX86InstPrinter
    else
      $(error Unsupported TARGET_ARCH $(TARGET_ARCH))
    endif
  endif
  LOCAL_STATIC_LIBRARIES += \
    libLLVMMCParser \
    $(LOCAL_STATIC_LIBRARIES)
endif

# This makes libclcore.bc get installed if and only if the target libbcc.so is installed.
LOCAL_REQUIRED_MODULES := libclcore.bc

# -Wl,--exclude-libs=ALL would hide most of the symbols in the shared library
# and reduces the size of libbcc.so by about 800k.
# As libLLVMBitReader:libLLVMCore:libLLVMSupport are used by pixelflinger2,
# use below instead.
LOCAL_LDFLAGS += -Wl,--exclude-libs=libLLVMARMDisassembler:libLLVMARMAsmPrinter:libLLVMX86Disassembler:libLLVMX86AsmPrinter:libLLVMMCParser:libLLVMARMCodeGen:libLLVMARMInfo:libLLVMSelectionDAG:libLLVMAsmPrinter:libLLVMCodeGen:libLLVMLinker:libLLVMJIT:libLLVMTarget:libLLVMMC:libLLVMScalarOpts:libLLVMInstCombine:libLLVMipo:libLLVMipa:libLLVMTransformUtils:libLLVMSystem:libLLVMAnalysis

include $(LLVM_ROOT_PATH)/llvm-device-build.mk
include $(BUILD_SHARED_LIBRARY)

# Shared library for host
# ========================================================
include $(CLEAR_VARS)

LOCAL_MODULE := libbcc
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := \
  $(libbcc_SRC_FILES) \
  helper/DebugHelper.c

LOCAL_STATIC_LIBRARIES := \
  libcutils \
  libutils \
  libLLVMX86CodeGen \
  libLLVMX86Info \
  libLLVMARMCodeGen \
  libLLVMARMInfo \
  libLLVMBitReader \
  libLLVMSelectionDAG \
  libLLVMAsmPrinter \
  libLLVMMCParser \
  libLLVMCodeGen \
  libLLVMLinker \
  libLLVMJIT \
  libLLVMTarget \
  libLLVMMC \
  libLLVMScalarOpts \
  libLLVMInstCombine \
  libLLVMipo \
  libLLVMipa \
  libLLVMTransformUtils \
  libLLVMCore \
  libLLVMSupport \
  libLLVMSystem \
  libLLVMAnalysis

LOCAL_LDLIBS := -ldl -lpthread

LOCAL_C_INCLUDES := \
  $(LOCAL_PATH)/lib/ExecutionEngine \
  $(LOCAL_PATH)/lib/CodeGen \
  $(LOCAL_PATH)/helper \
  $(LOCAL_PATH)/include \
  $(LOCAL_PATH)

# definitions for LLVM
LOCAL_CFLAGS += -D__STDC_LIMIT_MACROS -D__STDC_CONSTANT_MACROS -DDEBUG_CODEGEN=1

ifeq ($(TARGET_ARCH),arm)
  LOCAL_CFLAGS += -DFORCE_ARM_CODEGEN=1
else
  ifeq ($(TARGET_ARCH),x86)
    LOCAL_CFLAGS += -DFORCE_X86_CODEGEN=1
  else
    $(error Unsupported TARGET_ARCH $(TARGET_ARCH))
  endif
endif

ifeq ($(libbcc_USE_DISASSEMBLER),1)
LOCAL_STATIC_LIBRARIES := \
  libLLVMARMDisassembler \
  libLLVMARMAsmPrinter \
  libLLVMX86Disassembler \
  libLLVMX86AsmPrinter \
  libLLVMX86InstPrinter \
  libLLVMMCParser \
  $(LOCAL_STATIC_LIBRARIES)
endif

include $(LLVM_ROOT_PATH)/llvm-host-build.mk
include $(BUILD_HOST_SHARED_LIBRARY)

# Build children
# ========================================================
include $(call all-makefiles-under,$(LOCAL_PATH))

endif # TARGET_SIMULATOR != true
