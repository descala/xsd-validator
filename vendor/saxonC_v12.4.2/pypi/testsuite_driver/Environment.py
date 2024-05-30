from saxonche import *
import os

optimizer_flags = '-'


class Spec:

    def __init__(self, v, fn, sspn, sav):
        self.version = v
        self.full_name = fn
        self.short_spec_name = sspn
        self.spec_and_version = sav


    @staticmethod
    def XP20():
        return Spec("2.0", "XPath2.0", "XP", "XP20")

    @staticmethod
    def XP30():
        return Spec("3.0", "XPath3.0", "XP", "XP30")

    @staticmethod
    def XP31():
        return Spec("3.1", "XPath3.1", "XP", "XP31")

    @staticmethod
    def XP40():
        return Spec("4.0", "XPath4.0", "XP", "XP40")

    @staticmethod
    def XQ10():
        return Spec("1.0", "XQuery1.0", "XQ", "XQ10")

    @staticmethod
    def XQ30():
        return Spec("3.0", "XQuery3.0", "XQ", "XQ30")

    @staticmethod
    def XQ31():
        return Spec("3.1", "XQuery3.1", "XQ", "XQ31")

    @staticmethod
    def XQ40():
        return Spec("4.0", "XQuery4.0", "XQ", "XQ40")

    @staticmethod
    def XT10():
        return Spec("1.0", "XSLT1.0", "XT", "XT10")

    @staticmethod
    def XT20():
        return Spec("2.0", "XSLT2.0", "XT", "XT20")

    @staticmethod
    def XT30():
        return Spec("3.0", "XSLT3.0", "XT", "XT30")

    @staticmethod
    def XT40():
        return Spec("4.0", "XSLT4.0", "XT", "XT40")



class Environment:




    def __init__(self):
        ...
        self.proc = PySaxonProcessor(license=True)
        '''self.proc.set_configuration_property("http://saxon.sf.net/feature/licenseFileLocation",
                                               "/Users/ond1/work/development/git/private/saxon-license.lic")'''
        if os.getenv("SAXON_LICENSE_DIR") is not None:
            self.proc.set_configuration_property("http://saxon.sf.net/feature/licenseFileLocation",
                                                   os.getenv("SAXON_LICENSE_DIR") + "/saxon-license.lic")

        self.lang = None
        self.proc.set_configuration_property('http://saxon.sf.net/feature/optimizationLevel', optimizer_flags)

        self.base_uri = ""
        self.spec = None
        '''self.xquery_proc = self.proc.new_xquery_processor()
        self.xpath_proc = self.proc.new_xpath_processor()
        self.xslt_proc = self.proc.new_xslt30_processor()'''
        self.xquery_proc = None
        self.xpath_proc = None
        self.xslt_proc = None
        self.sheet = None

        self.context_item = None

        self.source_docs = {}
        self.param_decimal_declarations = None

        self.param_declarations = None

        self.params = {}

        self.reset_actions = []
        self.usable = True

    def create_processors(self):
        self.xpath_proc = self.proc.new_xpath_processor()
        self.xquery_proc = self.proc.new_xquery_processor()
        self.xslt_proc = self.proc.new_xslt30_processor()










