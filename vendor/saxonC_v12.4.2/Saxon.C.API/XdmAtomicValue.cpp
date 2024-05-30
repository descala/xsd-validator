
//

#include "XdmAtomicValue.h"

XdmAtomicValue::XdmAtomicValue() : XdmItem() {}

XdmAtomicValue::XdmAtomicValue(const XdmAtomicValue &aVal) : XdmItem(aVal) {
  valType = aVal.valType;
}

XdmItem *XdmAtomicValue::getHead() { return this; }

XdmAtomicValue::XdmAtomicValue(int64_t obj) : XdmItem(obj) {}

XdmAtomicValue::XdmAtomicValue(int64_t obj, const char *ty) : XdmItem(obj) {
  valType = std::string(ty);
}

XdmAtomicValue::~XdmAtomicValue() {
  if (getRefCount() < 1) {
    if (!valType.empty()) {
      valType.clear();
    }
  }
}

void XdmAtomicValue::setType(const char *ty) { valType = std::string(ty); }

const char *XdmAtomicValue::getPrimitiveTypeName() {
  if (!valType.empty()) {
    return valType.c_str();
  }
  allocFn fn = operator new;
  char *result = j_getPrimitiveTypeName(SaxonProcessor::sxn_environ->thread,
                                        (void *)fn, (void *)value);

  if (result != nullptr) {
    valType = std::string(result);
    operator delete(result);
    return valType.c_str();
  }

  return "Q{http://www.w3.org/2001/XMLSchema}anyAtomicType";
}

bool XdmAtomicValue::getBooleanValue() {
  char result =
      j_getBooleanValue(SaxonProcessor::sxn_environ->thread, (void *)value);
  return result != 0;
}

int XdmAtomicValue::getHashCode() {
  int result =
      j_getHashCode(SaxonProcessor::sxn_environ->thread, (void *)value);
  return result;
}

double XdmAtomicValue::getDoubleValue() {
  double result =
      j_getDoubleValue(SaxonProcessor::sxn_environ->thread, (void *)value);
  return result;
}

const char *XdmAtomicValue::getStringValue() {
  return XdmItem::getStringValue();
}

long XdmAtomicValue::getLongValue() {
  long result =
      j_getLongValue(SaxonProcessor::sxn_environ->thread, (void *)value);
  return result;
}
