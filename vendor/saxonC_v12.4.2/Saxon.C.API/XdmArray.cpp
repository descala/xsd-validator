#include "XdmArray.h"

#include "XdmMap.h"

XdmArray::XdmArray() : XdmFunctionItem(), arrayLen(-1) {}

XdmArray::XdmArray(const XdmArray &d) : XdmFunctionItem(d) {
  arrayLen = d.arrayLen;
}

// TODO arrayLen should be set upfront
XdmArray::XdmArray(int64_t obj) : XdmFunctionItem(obj), arrayLen(-1) {}

XdmArray::XdmArray(int64_t obj, int aLen)
    : XdmFunctionItem(obj), arrayLen(aLen) {}

int XdmArray::arrayLength() {
  if (arrayLen == -1) {
    arrayLen = j_xdmArray_arrayLength(SaxonProcessor::sxn_environ->thread,
                                      (void *)value);
  }
  return arrayLen;
}

XdmValue *XdmArray::get(int n) {
  if (n < 0) {
    return nullptr;
  }
  int64_t result =
      j_xdmArray_get(SaxonProcessor::sxn_environ->thread, (void *)value, n);
  return getXdmValueSubClass(result);
}

const char *XdmArray::toString() {
  allocFn fn = operator new;
  const char *str = j_xdmArray_toString(SaxonProcessor::sxn_environ->thread,
                                        (void *)fn, (void *)value);

  return str;
}

const char *XdmArray::getStringValue() {
  throw SaxonApiException("An array has no string value", "FOTY0014", nullptr,
                          -1);
}

XdmArray *XdmArray::put(int n, XdmValue *valuei) {
  if (n < 0) {
    return nullptr;
  }
  int64_t result =
      j_xdmArray_put(SaxonProcessor::sxn_environ->thread, (void *)value, n,
                     (void *)valuei->getUnderlyingValue());
  if (result <= 0) {
    return nullptr;
  }
  auto *newValue = new XdmArray(result);
  return newValue;
}

XdmArray *XdmArray::addMember(XdmValue *valuei) {
  int64_t result =
      j_xdmArray_addMember(SaxonProcessor::sxn_environ->thread, (void *)value,
                           (void *)valuei->getUnderlyingValue());
  if (result <= 0) {
    return nullptr;
  }
  auto *newValue = new XdmArray(result);
  return newValue;
}

XdmArray *XdmArray::concat(XdmArray *valuei) {
  int64_t result =
      j_xdmArray_concat(SaxonProcessor::sxn_environ->thread, (void *)value,
                        (void *)valuei->getUnderlyingValue());
  if (result <= 0) {
    return nullptr;
  }
  auto *newValue = new XdmArray(result);
  return newValue;
}

std::list<XdmValue *> XdmArray::asList() {
  std::list<XdmValue *> arr;
  int sizex = arrayLength();
  if (sizex == 0) {
    return arr;
  }
  allocFn fn = operator new;
  long long *results = j_convertXdmArrayToArrayObject(
      SaxonProcessor::sxn_environ->thread, (void *)value, (void *)fn);

  if (results) {

    XdmValue *tempValue;

    for (int p = 0; p < sizex; ++p) {

      int typeRef = j_getXdmObjectType(SaxonProcessor::sxn_environ->thread,
                                       (void *)results[p]);
      XdmItem *xdmItem = nullptr;
      if (typeRef == -2) {
        // exception = new SaxonApiException();
        return arr;
      }
      if (typeRef == 1) {
        tempValue = new XdmValue();
        xdmItem = new XdmAtomicValue(results[p]);
        tempValue->addXdmItem(xdmItem);

      } else if (typeRef == 2) {
        tempValue = new XdmValue();
        xdmItem = new XdmNode(results[p]);
        tempValue->addXdmItem(xdmItem);

      } else if (typeRef == 4) {
        tempValue = new XdmValue();
        xdmItem = new XdmMap(results[p]);
        tempValue->addXdmItem(xdmItem);

      } else if (typeRef == 3) {
        tempValue = new XdmValue();
        xdmItem = new XdmArray(results[p]);
        tempValue->addXdmItem(xdmItem);

      } else if (typeRef == 5) {
        tempValue = new XdmValue();
        xdmItem = new XdmFunctionItem(results[p]);
        tempValue->addXdmItem(xdmItem);
      } else if (typeRef == 6) {
        // Empty Sequence detected.
        // TODO Maybe we should create an EmptySequence object
        j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                          (void *)results[p]);

      } else {
        tempValue = new XdmValue(results[p], true);
      }

      arr.push_back(tempValue);
    }
    delete results;
  }

  return arr;
}

XdmValue **XdmArray::values() {
  XdmValue **arr = nullptr;

  int sizex = arrayLength();
  if (sizex == 0) {
    return arr;
  }
  allocFn fn = operator new;
  long long *results = j_convertXdmArrayToArrayObject(
      SaxonProcessor::sxn_environ->thread, (void *)value, (void *)fn);

  if (results == nullptr) {
    return nullptr;
  }

  arr = new XdmValue *[sizex];
  XdmValue *tempValue = nullptr;

  for (int p = 0; p < sizex; ++p) {

    int typeRef = j_getXdmObjectType(SaxonProcessor::sxn_environ->thread,
                                     (void *)results[p]);
    XdmItem *xdmItem = nullptr;
    if (typeRef == -2) {
      // exception = new SaxonApiException();
      std::cerr << "XdmArray.values() failed with exception" << std::endl;

      SaxonApiException *exception = new SaxonApiException();
      std::cerr << "Exception message = " << exception->getMessage()
                << std::endl;
      delete exception;
      return nullptr;
    }
    if (typeRef == 1) {
      tempValue = new XdmValue();
      xdmItem = new XdmAtomicValue(results[p]);
      tempValue->addXdmItem(xdmItem);

    } else if (typeRef == 2) {
      tempValue = new XdmValue();
      xdmItem = new XdmNode(results[p]);
      tempValue->addXdmItem(xdmItem);

    } else if (typeRef == 4) {
      tempValue = new XdmValue();
      xdmItem = new XdmMap(results[p]);
      tempValue->addXdmItem(xdmItem);

    } else if (typeRef == 3) {
      tempValue = new XdmValue();
      xdmItem = new XdmArray(results[p]);
      tempValue->addXdmItem(xdmItem);

    } else if (typeRef == 5) {
      tempValue = new XdmValue();
      xdmItem = new XdmFunctionItem(results[p]);
      tempValue->addXdmItem(xdmItem);
    } else if (typeRef == 6) {
      // Empty Sequence detected.
      // TODO Maybe we should create an EmptySequence object
      std::cerr << "XdmArray.values() failed - EmptySequence not handled"
                << std::endl;
      j_handles_destroy(SaxonProcessor::sxn_environ->thread,
                        (void *)results[p]);

    } else {
      tempValue = new XdmValue((int64_t)results[p], true);
    }

    arr[p] = tempValue;
  }
  delete results;
  return arr;
}
