def pytest_addoption(parser):
    parser.addoption("--data-dir", action="store", default="samples/data/")
    parser.addoption("--files-dir", action="store", default="samples/php")