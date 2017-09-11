from setuptools import setup, Extension

# core = Extension('pysproto.core',
        # sources = ["pysproto/python_sproto.c", "pysproto/sproto.c"],
        # extra_compile_args = ["-g3", "-O0"],
        # )
from Cython.Build import cythonize
ext = Extension("pysproto.core",
        sources = ["pysproto/core.pyx", "pysproto/sproto.c"],
        # extra_compile_args = ["-g3", "-O0"],
        )
core = cythonize(ext)

setup(
        name = "pysproto",
        version = '0.5',
        packages = ["pysproto"],
        description = "python binding for cloudwu's sproto",
        author = "bttscut",
        license = "MIT",
        url="http://github.com/bttscut/pysproto",
        keywords=["sproto", "python"],
        # py_modules = ["sproto.py"],
        ext_modules = core,
        )
