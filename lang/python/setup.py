from setuptools import setup, find_packages

LONG_DESCRIPTION = """
This is an experimental project

https://packaging.python.org/
https://devcenter.heroku.com/articles/python-pip
https://packaging.python.org/tutorials/distributing-packages
"""

def _supported_python_versions():
    py3_vers = ['!=3.{}.*'.format(sub_ver) for sub_ver in range(5)]
    return '>= 2.7, {}, <4'.format(', '.join(py3_vers))

setup(
    name='PySpinnenKrawl',
    version='0.1',
    description='build and distributing stuffs',
    long_description=LONG_DESCRIPTION,
    author='Philip Yang',
    author_email='phissenschaft@gmail.com',
    url='https://phi9t.y',
    packages=[
        'crawler'
    ],
    python_requires=_supported_python_versions(),
    classifiers=[
        # How mature is this project? Common values are
        #   3 - Alpha
        #   4 - Beta
        #   5 - Production/Stable
        'Development Status :: 3 - Alpha',

        # Indicate who your project is intended for
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Build Tools',

        # Pick your license as you wish (should match "license" above)
        'License :: OSI Approved :: MIT License',

        # Specify the Python versions you support here. In particular, ensure
        # that you indicate whether you support Python 2, Python 3 or both.
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ], )
