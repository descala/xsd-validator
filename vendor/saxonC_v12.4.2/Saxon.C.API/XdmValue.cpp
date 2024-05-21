#include "XdmValue.h"
#include "XdmArray.h"
#include "XdmAtomicValue.h"
#include "XdmFunctionItem.h"
#include "XdmItem.h"
#include "XdmMap.h"
#include "XdmNode.h"

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

XdmValue::XdmValue(const XdmValue &other) {
  // SaxonProcessor *proc = other.proc; //TODO
  valueType = other.valueType;
  refCount = 0;
  xdmSize = other.xdmSize;
  jValues = other.jValues;
  toStringValue = other.toStringValue;
  // values.resize(0);
  values_cap = other.values_cap;
  relinquished_values = new char[values_cap];
  memset(relinquished_values, 0, sizeof(*relinquished_values) * values_cap);
  for (int i = 0; i < xdmSize; i++) {
    addXdmItem(other.values[i]);
  }
}

const char *XdmValue::toString() {
  int count = size();
  if (count == 0) {
    return nullptr;
  }
  char *toStringValuei = nullptr;
  // if (toStringValue == nullptr) {
  allocFn fn = operator new;
  if (count == 1) {
    toStringValuei =
        xdmItemToString(SaxonProcessor::sxn_environ->thread, (void *)fn,
                        (void *)(values[0]->getUnderlyingValue()));
  } else {
    if (jValues == -1) {
      jValues = getUnderlyingValue();
    }

    toStringValuei = xdmValueArrayToString(SaxonProcessor::sxn_environ->thread,
                                           (void *)fn, (void *)jValues);
  }
  //}
  return toStringValuei;
}

int XdmValue::size() { return xdmSize; }

XdmValue::XdmValue(int64_t valRef) {
  initialize();
  XdmItem *value = new XdmItem(valRef);
  values_cap = 1;
  values = new XdmItem *[values_cap];
  relinquished_values = new char[values_cap];
  relinquished_values[0] = 0;
  addXdmItem(value);
  jValues = -1;
  valueType = nullptr;
  toStringValue = nullptr;
}

XdmValue::XdmValue(int64_t val, bool arr) {
  initialize();
  allocFn fn = operator new;
  long long *results = makeArrayFromXdmValue2(
      SaxonProcessor::sxn_environ->thread, (void *)fn, (void *)val);
  if (results == nullptr) {
    return;
  }

  int xdmSizei = results[0];
  values_cap = xdmSizei;
  values = new XdmItem *[values_cap];
  relinquished_values = new char[values_cap];
  memset(relinquished_values, 0, sizeof(*relinquished_values) * values_cap);
  int typeRef = 0;

  for (int p = 1; p <= xdmSizei; ++p) {
    typeRef = j_getXdmObjectType(SaxonProcessor::sxn_environ->thread,
                                 (void *)results[p]);
    if (getenv("SAXONC_DEBUG_FLAG")) {
      std::cerr << "C++ XdmValue - typeRef= " << typeRef << std::endl;
    }
    if (typeRef == -2) {
      std::cerr << "Exception thrown while creating XdmValue from array"
                << std::endl;
      return;
    }
    if (typeRef == XDM_ATOMIC_VALUE) {

      addXdmItem(new XdmAtomicValue(results[p]));

    } else if (typeRef == XDM_NODE) {

      addXdmItem(new XdmNode(results[p]));

    } else if (typeRef == XDM_ARRAY) {
      addXdmItem(new XdmArray(results[p]));
    } else if (typeRef == XDM_MAP) {
      addXdmItem(new XdmMap(results[p]));

    } else if (typeRef == XDM_FUNCTION_ITEM) {
      addXdmItem(new XdmFunctionItem(results[p]));
    } else {
      std::cerr << "Error creating XdmValue from array" << std::endl;
    }
  }
  operator delete(results);
}

XdmValue::~XdmValue() {

  if (xdmSize > 0 && values != nullptr) {

    for (int i = 0; i < xdmSize; i++) {
      if (relinquished_values[i] == (char)0 && values[i] != nullptr &&
          values[i]->getRefCount() < 1) {
        delete values[i];
        values[i] = nullptr;
      }
    }
    delete[] values;
    delete[] relinquished_values;
    values = nullptr;
    relinquished_values = nullptr;
    values_cap = 0;
  }
  if (valueType != nullptr) {
    delete valueType;
  }
  if (jValues > 0 && (this)->getRefCount() < 1) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)jValues);
    jValues = -1;
  }

  xdmSize = 0;

  /*if (toStringValue != nullptr) {
    delete[] toStringValue;
    toStringValue = nullptr;
  }   */
}

void XdmValue::addXdmItem(XdmItem *val) {

  if (val != nullptr) {
    if (values == nullptr) {
      values_cap = 1;
      values = new XdmItem *[values_cap];
      relinquished_values = new char[values_cap];
      relinquished_values[0] = 0;
    }

    if (xdmSize == values_cap) {
      // resizing values pointer array
      XdmItem **newValues = new XdmItem *[values_cap * 2];
      char *new_relinquish_val = new char[values_cap * 2];
      memset(new_relinquish_val, 0,
             sizeof(*new_relinquish_val) * values_cap * 2);
      for (int i = 0; i < values_cap; i++) {
        newValues[i] = values[i];
        new_relinquish_val[i] = relinquished_values[i];
      }
      delete[] values;
      delete[] relinquished_values;
      values = newValues;
      relinquished_values = new_relinquish_val;
      values_cap *= 2;
    }
    values[xdmSize] = val;
    // values.push_back(val);
    // val->incrementRefCount();
    xdmSize++;
    if (jValues >= 0) {
      jValues = -1;
    }
    if (toStringValue != nullptr) {
      operator delete(toStringValue);
      toStringValue = nullptr;
    }
  }
}

void XdmValue::addUnderlyingValue(int64_t val) {
  XdmItem *valuei = new XdmItem(val);
  valuei->incrementRefCount();
  if (xdmSize == values_cap) {
    // resizing values pointer array
    XdmItem **newValues = new XdmItem *[values_cap * 2];
    for (int i = 0; i < values_cap; i++) {
      newValues[i] = values[i];
    }
    delete values;
    values = newValues;
    values_cap *= 2;
  }
  values[xdmSize] = valuei;
  xdmSize++;
  jValues = -1; // TODO clear Graalvm reference from ObjectHandles pool
}

void XdmValue::incrementRefCount() {
  refCount++;
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "refCount-inc-xdmVal=" << refCount << " ob ref=" << (this)
              << std::endl;
  }
}

void XdmValue::decrementRefCount() {
  if (refCount > 0)
    refCount--;
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "refCount-dec-xdmVal=" << refCount << " ob ref=" << (this)
              << std::endl;
  }
}

XdmItem *XdmValue::getHead() {
  if (xdmSize > 0) {
    relinquished_values[0] = (char)1;
    return values[0];
  } else {
    return nullptr;
  }
}

int64_t XdmValue::getUnderlyingValue() {

  if (jValues == SXN_UNSET) {
    int i;

    int count = xdmSize;
    if (count == 0) {
      return -1;
    }

    if (count == 1) {
      return values[0]->getUnderlyingValue();
    }
    jValues = createProcessorDataWithCapacity(
        SaxonProcessor::sxn_environ->thread, count);

    for (i = 0; i < count; i++) {
      int64_t ivalue = values[i]->getUnderlyingValue();
      addProcessorValue(SaxonProcessor::sxn_environ->thread, (void *)jValues,
                        (void *)ivalue);
    }
  }
  return jValues;
}

void XdmValue::releaseXdmValue() {
  for (size_t i = 0; i < xdmSize; i++) {
    if (values[i] != nullptr) {
      delete values[i];
    }
  }

  jValues = SXN_UNSET;
}

XdmItem *XdmValue::itemAt(int n) {
  if (n >= 0 && (unsigned int)n < xdmSize) {
    relinquished_values[n] = (char)1;
    return values[n];
  }
  return nullptr;
}

/**
 * Get the type of the object
 */
XDM_TYPE XdmValue::getType() { return XDM_VALUE; }
