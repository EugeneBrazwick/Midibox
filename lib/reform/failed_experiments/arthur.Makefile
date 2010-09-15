
LIBARTH=../../plugins/styles/arthur.so
TARG=${LIBARTH}
QTINCDIR=/usr/include/qt4
QTLIBDIR=/usr/lib
CFLAGS=-DQT_OPENGL -DQT_NO_DEBUG -DQT_GUI_LIB -DQT_CORE_LIB -DQT_SHARED -D_REENTRANT
INCDIRS=$(addprefix -I ${QTINCDIR}/,'' QtCore QtGui)
MOCS=arthurwidgets.cpp

all: ${TARG}

${LIBARTH}: $(addprefix /tmp/moc_,${MOCS}) arthurstyle.cpp ${MOCS}
	gcc ${CFLAGS} -o $@ -shared -fPIC $^ ${INCDIRS} -L ${QTLIBDIR} -lQtCore -lQtGui

/tmp/moc_%.cpp: %.h
	moc-qt4 ${CFLAGS} ${INCDIRS} $< -o $@
clean:
	rm -f ${TARG}