from setuptools import setup, Extension
from Cython.Build import cythonize
import shutil

# This file is copied to build/pypi before running; internal
# paths are relative to that location

# read the long_description from a file.
from pathlib import Path
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

# include platform specific dynamic lib in the wheel.
from platform import system
from distutils.dir_util import copy_tree

extra_link_args = []

if system() == 'Darwin':
    extra_link_args.append('-L../libs/darwin')
elif system() == 'Windows':
    extra_link_args.append('../libs\\win\\libsaxon-hec-12.4.2.lib')
else:
    extra_link_args.append('-L../libs/nix')

# extented modules
ext_modules = [Extension(
                         "saxonche", 
                        sources=[
                            "python_saxon/saxonc.pyx",
                            "../Saxon.C.API/SaxonProcessor.cpp",
                            "../Saxon.C.API/SaxonCGlue.c",
                            "../Saxon.C.API/SaxonCXPath.c",
                            "../Saxon.C.API/XdmValue.cpp",
                            "../Saxon.C.API/XdmItem.cpp",
                            "../Saxon.C.API/XdmNode.cpp",
                            "../Saxon.C.API/XdmAtomicValue.cpp",
                            "../Saxon.C.API/XdmFunctionItem.cpp",
                            "../Saxon.C.API/XdmMap.cpp",
                            "../Saxon.C.API/XdmArray.cpp",
                            "../Saxon.C.API/DocumentBuilder.cpp",
                            "../Saxon.C.API/Xslt30Processor.cpp",
                            "../Saxon.C.API/XsltExecutable.cpp",
                            "../Saxon.C.API/XQueryProcessor.cpp",
                            "../Saxon.C.API/XPathProcessor.cpp",
                            "../Saxon.C.API/SchemaValidator.cpp",
                            "../Saxon.C.API/CythonExceptionHandler.cpp",
                            "../Saxon.C.API/SaxonApiException.cpp",],
                        language="c++",
                        include_dirs = ['../Saxon.C.API/graalvm',],
                         extra_link_args = extra_link_args,
                       libraries=['../libs/nix/saxon-hec-12.4.2']
                        ),
                ]
setup(
    name='saxonche',
    version='12.4.2',
    description='Official Saxonica python package for the SaxonC-HE 12.4.2 processor: for XSLT 3.0, XQuery 3.1, XPath 3.1 and XML Schema processing.',
    long_description=long_description,
    long_description_content_type='text/markdown',
    author='ONeil Delpratt',
    author_email='oneil@saxonica.com',
    include_package_data=True,
    url='https://www.saxonica.com/saxon-c/index.xml',
    package_dir={'saxonche':'.'},
    packages=['saxonche'],
    python_requires='>=3.8',                # Minimum version requirement of the package
    ext_modules=cythonize(ext_modules,
                          compiler_directives={'language_level': 3},
                          ),

)
