
JAVAC := javac
CFLAGS :=

uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')

ifeq ($(uname_S),Linux)
	JAVA_HOME:=$(shell sh -c 'dirname $$(dirname $$(readlink -e $$(which $(JAVAC))))')
	JAVA_PLATFORM := $(JAVA_HOME)/include/linux
	CFLAGS := -fPIC
	CFLAGS += -DLIBPYTHON_RTLD_GLOBAL=1
	SOEXT := so
	PYLDFLAGS :=  $(shell sh -c 'python-config --ldflags')
endif
ifeq ($(uname_S),Darwin)
	JAVA_HOME := $(shell /usr/libexec/java_home)
	JAVA_PLATFORM := $(JAVA_HOME)/include/darwin
	SOEXT := dylib
	PYLDFLAGS := -lPython
endif

all: dist/rubicon.jar dist/librubicon.$(SOEXT) dist/test.jar

dist/rubicon.jar: org/pybee/rubicon/Python.class org/pybee/rubicon/PythonInstance.class
	mkdir -p dist
	jar -cvf dist/rubicon.jar org/pybee/rubicon/Python.class org/pybee/rubicon/PythonInstance.class

dist/test.jar: org/pybee/rubicon/test/BaseExample.class org/pybee/rubicon/test/Example.class org/pybee/rubicon/test/ICallback.class org/pybee/rubicon/test/AbstractCallback.class org/pybee/rubicon/test/Thing.class org/pybee/rubicon/test/Test.class
	mkdir -p dist
	jar -cvf dist/test.jar org/pybee/rubicon/test/*.class

dist/librubicon.$(SOEXT): jni/rubicon.o
	mkdir -p dist
	gcc -shared -o $@ $< $(PYLDFLAGS)

test: all
	java org.pybee.rubicon.test.Test

clean:
	rm -f org/pybee/rubicon/test/*.class
	rm -f org/pybee/rubicon/*.class
	rm -f jni/*.o
	rm -rf dist

%.class : %.java
	$(JAVAC) $<

%.o : %.c
	gcc -c $(CFLAGS) -Isrc -I$(JAVA_HOME)/include -I$(JAVA_PLATFORM) -o $@ $<

