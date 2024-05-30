

#include "XdmNode.h"

#ifdef MEM_DEBUG
#define new new (__FILE__, __LINE__)
#endif

XdmNode::XdmNode(int64_t obj)
    : XdmItem(obj), baseURI(nullptr), nodeName(nullptr), localName(nullptr),
      childCount(-1), children(nullptr), parent(nullptr), typedValue(nullptr),
      attrValues(nullptr), attrCount(-1), nodeKind(UNKNOWN), axisCount(0),
      nodeToString(nullptr) {}

XdmNode::XdmNode(XdmNode *p, int64_t obj, XDM_NODE_KIND kind)
    : XdmItem(obj), baseURI(nullptr), nodeName(nullptr), localName(nullptr),
      childCount(-1), children(nullptr), parent(p), typedValue(nullptr),
      attrValues(nullptr), attrCount(-1), nodeKind(kind), axisCount(0),
      nodeToString(nullptr) {}

XdmNode::XdmNode(const XdmNode &other) {
  baseURI = other.baseURI;
  value = other.value;
  nodeName = other.nodeName;
  localName = other.localName;
  childCount = other.childCount;
  parent = other.parent;
  typedValue = other.typedValue;
  attrCount = other.attrCount;
  nodeKind = other.nodeKind;
  nodeToString = other.nodeToString;
  axisCount = other.axisCount;
}

bool XdmNode::isAtomic() { return false; }

XDM_NODE_KIND XdmNode::getNodeKind() {
  if (nodeKind == UNKNOWN) {
    int kvalue =
        (int)j_getNodeKind(SaxonProcessor::sxn_environ->thread, (void *)value);
    nodeKind = static_cast<XDM_NODE_KIND>(kvalue);
  }
  return nodeKind;
}

XdmNode::~XdmNode() {
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "~XdmNode destructor called:" << refCount
              << " ob ref=" << (this) << std::endl;
  }
  // if(getRefCount() <= 1) {
  if (baseURI != nullptr) {
    operator delete((char *)baseURI);
    baseURI = nullptr;
  }
  if (nodeName != nullptr) {
    operator delete((char *)nodeName);
    nodeName = nullptr;
  }
  if (localName != nullptr) {
    operator delete((char *)localName);
    localName = nullptr;
  }

  /* if (nodeToString != nullptr) {
    delete[] nodeToString;
    nodeToString = nullptr;
  }

  if (children != nullptr) {

       for (int p = 0; p < childCount; ++p) {
           delete children[p];

       }
       delete[] children;
   }
   if (attrCount > 0 && attrValues != nullptr) {
       for (int p = 0; p < attrCount; ++p) {
           delete attrValues[p];

       }
       delete[] attrValues;
   }     */

  //}
}

const char *XdmNode::getLocalName() {
  if (localName != nullptr) {
    return localName;
  }
  XDM_NODE_KIND kind = getNodeKind();
  allocFn fn = operator new;
  switch (kind) {
  case DOCUMENT:
  case TEXT:
  case COMMENT:
    return nullptr;
  case PROCESSING_INSTRUCTION:
  case NAMESPACE:
  case ELEMENT:
  case ATTRIBUTE:
    localName = j_getLocalName(SaxonProcessor::sxn_environ->thread, (void *)fn,
                               (void *)value);

    return localName;

  default:
    return nullptr;
  }
}

const char *XdmNode::getNodeName() {
  if (nodeName != nullptr) {
    return nodeName;
  }
  allocFn fn = operator new;
  XDM_NODE_KIND kind = getNodeKind();
  switch (kind) {
  case DOCUMENT:
  case TEXT:
  case COMMENT:
    return nullptr;
  case PROCESSING_INSTRUCTION:
  case NAMESPACE:
  case ELEMENT:
  case ATTRIBUTE:
    nodeName = j_getNodeName(SaxonProcessor::sxn_environ->thread, (void *)fn,
                             (void *)value);
    return nodeName;
  default:
    return nullptr;
  }
}

// TODO we still don't know if the result is an XdmAtomicValue, EmptySequence or
// XdmValue
XdmValue *XdmNode::getTypedValue() {
  if (typedValue == nullptr) {
    int64_t result =
        j_getTypedValue(SaxonProcessor::sxn_environ->thread, (void *)value);
    if (result > 0) {
      typedValue = new XdmValue();
      typedValue->addUnderlyingValue(result);
      return typedValue;
    }
    return nullptr;

  } else {
    return typedValue;
  }
}

XdmItem *XdmNode::getHead() { return this; }

const char *XdmNode::getStringValue() { return XdmItem::getStringValue(); }

const char *XdmNode::toString() {
  const char *nodeToStringi = nullptr;
  // if (nodeToString == nullptr) {
  allocFn fn = operator new;
  nodeToStringi = xdmNodeToString(SaxonProcessor::sxn_environ->thread,
                                  (void *)fn, (void *)value);
  if (nodeToStringi == nullptr) {
    throw SaxonApiException();
  }
  //}
  return nodeToStringi;
}

const char *XdmNode::getBaseUri() {
  if (baseURI != nullptr) {
    return baseURI;
  }
  allocFn fn = operator new;
  baseURI = getBaseURIForXdmNode(SaxonProcessor::sxn_environ->thread,
                                 (void *)fn, (void *)value);
  return baseURI;
}

XdmNode *XdmNode::getParent() {
  if (parent == nullptr) {
    int64_t nodeRef =
        getParentForXdmNode(SaxonProcessor::sxn_environ->thread, (void *)value);
    if (nodeRef > SXN_UNSET) {
      parent = new XdmNode(nullptr, nodeRef, UNKNOWN);
      // parent->incrementRefCount();
      return parent;
    }
    return nullptr;

  } else {
    return parent;
  }
}

const char *XdmNode::getAttributeValue(const char *str) {

  if (str == nullptr) {
    return nullptr;
  }
  allocFn fn = operator new;
  const char *stri =
      j_getAttributeValue(SaxonProcessor::sxn_environ->thread, (void *)value,
                          (char *)str, (void *)fn);

  return stri;
}

XdmNode **XdmNode::getAttributeNodes(bool cached) {
  if (cached && attrValues != nullptr) {
    return attrValues;
  } else {
    getAttributeCount();
    allocFn fn = operator new;
    long long *results = j_getAttributeNodes(
        SaxonProcessor::sxn_environ->thread, (void *)fn, (void *)value);

    if (attrCount == 0) {
      return nullptr;
    }
    XdmNode **attrValuesi = nullptr;

    attrValuesi = new XdmNode *[attrCount];
    XdmNode *tempNode = nullptr;
    for (int p = 0; p < attrCount; ++p) {
      tempNode = new XdmNode(this, results[p], ATTRIBUTE);
      // this->incrementRefCount();
      attrValuesi[p] = tempNode;
    }

    if (cached) {
      attrValues = attrValuesi;
    }
    operator delete(results);
    return attrValuesi;
  }
}

int XdmNode::axisNodeCount() { return axisCount; }

XdmNode **XdmNode::axisNodes(EnumXdmAxis axis) {
  allocFn fn = operator new;
  long long *results = j_axisIterator(SaxonProcessor::sxn_environ->thread,
                                      (void *)fn, (void *)value, int(axis));
  if (results == nullptr) {
    return nullptr;
  }
  axisCount = results[0];
  if (axisCount == 0) {
    return nullptr;
  }
  if (getenv("SAXONC_DEBUG_FLAG")) {
    std::cerr << "axisNodes count=" << axisCount << std::endl;
  }
  XdmNode **valuesi = nullptr;

  valuesi = new XdmNode *[axisCount];
  XdmNode *tempNode = nullptr;
  for (int p = 1; p < axisCount + 1; ++p) {

    tempNode = new XdmNode(this, results[p], UNKNOWN);
    // this->incrementRefCount();
    valuesi[p - 1] = tempNode;
  }

  operator delete(results);

  return valuesi;
}

int XdmNode::getAttributeCount() {
  if (attrCount == -1) {

    attrCount =
        j_getAttributeCount(SaxonProcessor::sxn_environ->thread, (void *)value);
  }
  return attrCount;
}

int XdmNode::getChildCount() {
  if (childCount == -1) {
    childCount =
        j_getChildCount(SaxonProcessor::sxn_environ->thread, (void *)value);
  }
  return childCount;
}

XdmNode **XdmNode::getChildren(bool cached) {
  if (cached && children != nullptr) {
    return children;
  } else {
    if (childCount < 0) {
      getChildCount();
    }

    if (childCount == 0) {
      return nullptr;
    }
    allocFn fn = operator new;
    long long *childNodes = j_getChildren(SaxonProcessor::sxn_environ->thread,
                                          (void *)fn, (void *)value);
    if (childNodes == nullptr) {
      return nullptr;
    }
    children = new XdmNode *[childCount];
    for (int p = 0; p < childCount; ++p) {
      children[p] = new XdmNode(this, (int64_t)childNodes[p], UNKNOWN);
    }
    operator delete(childNodes);
    return children;
  }
}

XdmNode *XdmNode::getChild(int i, bool cached) {

  if (i < 0) {
    return nullptr;
  }

  if (cached) {

    if (children == nullptr) {
      getChildren(cached);
    }

    if (i < childCount && children[i] != nullptr) {
      return children[i];

    } else {
      return nullptr;
    }
  } else {
    XdmNode *child = nullptr;

    int64_t childRef =
        j_getChild(SaxonProcessor::sxn_environ->thread, (void *)value, i);

    if (childRef == SXN_UNSET) {
      return nullptr;
    }

    child = new XdmNode(this, childRef, UNKNOWN);

    return child;
  }
}
