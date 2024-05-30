#include "CythonExceptionHandler.h"
#include "Python.h"
#include "SaxonApiException.h"
#include <exception>
#include <string>

extern "C" PyObject *pysaxonapierror;

void raise_py_error() {
  try {
    throw;
  } catch (SaxonApiException &e) {
    const char *errorMessage = e.getMessageWithErrorCode();
    if (errorMessage == nullptr) {
      errorMessage = e.getMessage();
      if (errorMessage == nullptr) {
        PyErr_SetString(pysaxonapierror, "Unknown exception found");
      } else {
        PyErr_SetString(pysaxonapierror, errorMessage);
      }
    } else {
      PyErr_SetString(pysaxonapierror, errorMessage);
    }
  } catch (const std::exception &e) {
    PyErr_SetString(PyExc_RuntimeError, e.what());
  }
}
