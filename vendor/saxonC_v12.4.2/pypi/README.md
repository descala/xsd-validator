# Welcome to SaxonC-HE

This is the official [Saxonica](https://www.saxonica.com/) Python wheel package for
Saxon, an XML document processor. [SaxonC](https://www.saxonica.com/saxon-c/index.xml) 
provides APIs to run XSLT 3.0 transformations, XQuery 3.1 queries, XPath 3.1, and 
XML Schema validation.

The SaxonC release comes in separate wheels for the three product editions:
* **saxonche** (SaxonC-HE: open-source Home Edition)
* **saxoncpe** (SaxonC-PE: Professional Edition) 
* **saxoncee** (SaxonC-EE: Enterprise Edition)

SaxonC-PE and SaxonC-EE are commercial products that require a valid
license key. Licenses can be purchased from the 
[Saxonica online store](https://www.saxonica.com/shop/shop.xml). 
Alternatively a 30-day [evaluation license](https://www.saxonica.com/download/download.xml) 
is available free of charge. By downloading the software, you are agreeing to our 
[terms and conditions](https://www.saxonica.com/license/terms.xml).

For full documentation for the latest SaxonC release, see the
[SaxonC 12 documentation](https://www.saxonica.com/saxon-c/documentation12/index.html).

## Why choose SaxonC?

The main reason for using SaxonC in preference to other XML
tools available for Python is that it supports all the latest W3C
standards: XSLT 3.0, XPath 3.1, XQuery 3.1, and XSD 1.1. It even
includes experimental support for the draft 4.0 specifications
currently under development.

## About SaxonC

SaxonC is a version of Saxon developed by compiling the Java source code to native 
executables that run on the C/C++ platform, with extensions for PHP and Python. All 
features of Saxon have been ported, other than those (such as collations) that are 
necessarily platform dependent. In particular, SaxonC provides processing in XSLT, 
XQuery and XPath, and Schema validation. It therefore makes these processing capabilities 
available to a plethora of other languages that are strongly coupled to C/C++ such as PHP, 
Perl, Python, and Ruby.


## About Saxonica

Saxon is developed by Saxonica, a company created in 2004 by Michael Kay, who was 
the editor of the XSLT 2.0 and 3.0 specifications in W3C. The original Saxon product 
on the Java platform has been continually developed for over 20 years, and has 
acquired a reputation for standards conformance, performance, and reliability.


## Installation

```bash
pip install saxonche
```

## Getting started

Either import the whole API:

```python 
from saxonche import *
```

Or specific modules:

```python 
from saxonche import PySaxonProcessor
```

The SaxonC API includes classes for constructing XDM data models
and for a variety of processors. For full details see the [SaxonC Python API 
documentation](https://www.saxonica.com/saxon-c/documentation/index.html#!api/saxon_c_python_api).

The following short example shows how to get the Saxon version from
the `PySaxonProcessor`:

```python
from saxonche import PySaxonProcessor

with PySaxonProcessor(license=False) as proc:
	print(proc.version)
```

It will print something like this:

```bash
SaxonC-HE 12.4.2 from Saxonica
```

**Note**: `license=False` requests the open-source version of Saxon, whereas 
`license=True` requests the commercial product - which requires a license file.
SaxonC looks for the license key in the directory where the main SaxonC library has been 
installed, and the directory identified by the environment variable `SAXONC_HOME`.

### Example: Running a transformation

The following basic example shows how an XSLT stylesheet can be run against a source 
XML document in Python using SaxonC:

```python 
from saxonche import *

with PySaxonProcessor(license=False) as proc:
 
xsltproc = proc.new_xslt30_processor()
document = proc.parse_xml(xml_text="<doc><item>text1</item><item>text2</item><item>text3</item></doc>")
executable = xsltproc.compile_stylesheet(stylesheet_file="test.xsl")
output = executable.transform_to_string(xdm_node=document)
print(output)
```

For more Python examples, and further details about installing and configuring the product, 
see the [SaxonC 12 documentation](https://www.saxonica.com/saxon-c/documentation12/index.html).



## Support

All users are welcome to use the public [support site](http://saxonica.plan.io) for 
reporting issues and seeking help (registration required). In addition, many 
questions are asked and answered on [StackOverflow](https://stackoverflow.com): 
please use the **saxon** tag.

## Acknowledgement

We learned a lot about how to create Python wheels for Saxon from the
Saxonpy wheel package, which is a third-party project
[on github](https://github.com/tennom/saxonpy).