See SaxonC documentation for full guide on installing SaxonC python extension:

https://www.saxonica.com/saxon-c/documentation/index.html#!starting/installingpython
The SaxonC python extension is now available as a pypi package which can be installed using pip

You can also install the python extension using the following command:
python3 setup.py build_ext -if

pydoc3 -w saxonc[EDITION]

Run pytest-3:

pytest-3 test_saxonc.py
