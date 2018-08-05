from glob import glob
from pkg_resources import resource_filename, Requirement
import site
import sys
import subprocess
import py4j
from py4j.java_gateway import JavaGateway

jar_file = resource_filename(Requirement.parse('py4j'),
                             "py4j{}.jar".format(py4j.__version__))

resource_filename(Requirement.parse('pyspark'), '')


# Find a bunch of classes
subprocess.check_call(['javac', '-cp', jar_file, 'JvmAPI.java'])
proc = subprocess.Popen(['java', '-cp', '{}:.'.format(jar_file), 'JvmAPI'])

gateway = JavaGateway()
random = gateway.jvm.java.util.Random()

gateway.close()
proc.kill()
