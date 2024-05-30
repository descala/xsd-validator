

#include "XdmItem.h"

XdmItem::XdmItem() : XdmValue() {
  value = SXN_UNSET;
  stringValue = nullptr;
  itemToString = nullptr;
}

XdmItem::XdmItem(const XdmItem &other) : XdmValue(other) {
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "XdmItem copy constructor called:" << std::endl;
  }
  value = other.value;
  xdmSize = 1;
  refCount = other.refCount;
  stringValue = other.stringValue;
  stringValue = other.stringValue;
  itemToString = other.itemToString;
}

XdmItem::XdmItem(int64_t objRef) {
  value = objRef;
  xdmSize = 1;
  refCount = 0;
  stringValue = nullptr;
  itemToString = nullptr;
}

bool XdmItem::isAtomic() { return false; }

bool XdmItem::isNode() { return false; }

bool XdmItem::isFunction() { return false; }

bool XdmItem::isMap() { return false; }

bool XdmItem::isArray() { return false; }

XdmItem *XdmItem::getHead() { return this; }

XdmItem *XdmItem::itemAt(int n) {
  if (n < 0 || n >= size()) {
    return nullptr;
  }
  return this;
}

int XdmItem::size() { return 1; }

int64_t XdmItem::getUnderlyingValue() {
  if (!value) {
    return -1;
  }
  return value;
}

const char *XdmItem::getStringValue() {
  const char *stringValuei = nullptr;
  // if (stringValue == nullptr) {
  if (value < 0) {
    return nullptr;
  }
  allocFn fn = operator new;
  stringValuei = getStringValueForXdmItem(SaxonProcessor::sxn_environ->thread,
                                          (void *)fn, (void *)value);
  //}
  return stringValuei;
}

const char *XdmItem::toString() {
  const char *itemToStringi = nullptr;
  // if (itemToString == nullptr) {
  allocFn fn = operator new;
  itemToStringi = xdmItemToString(SaxonProcessor::sxn_environ->thread,
                                  (void *)fn, (void *)value);
  //}
  return itemToStringi;
}

/**
 * Get the type of the object
 */
XDM_TYPE XdmItem::getType() { return XDM_ITEM; }

XdmItem::~XdmItem() {
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "~XdmItem destructor called:" << refCount
              << " ob ref=" << (this) << "value =" << ((long)value)
              << std::endl;
  }
  if (value > 0) {
    j_handles_destroy(SaxonProcessor::sxn_environ->thread, (void *)value);
  }
  value = -1;
  /*else {
       decrementRefCount();
   }*/
  /*if (stringValue != nullptr) {
    delete[] stringValue;
    stringValue = nullptr;
  }

  if (itemToString != nullptr) {
    delete[] itemToString;
    itemToString = nullptr;
  } */
}

void XdmItem::incrementRefCount() {
  refCount++;
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "after refCount-inc-xdmItem=" << refCount
              << " ob ref=" << (this) << std::endl;
  }
}

void XdmItem::decrementRefCount() {
  if (refCount > 0)
    refCount--;
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "after refCount-dec-xdmItem=" << refCount
              << " ob ref=" << (this) << std::endl;
  }
}
