#!/bin/bash
#
# Nagios plugin to monitor Java JMX (http://java.sun.com/jmx)attributes.
#
RDIR=`dirname $0`

if [[ ! -z $JAVA_HOME ]]; then
  JAVA=$JAVA_HOME/bin/java
elif [[ $(echo $(which java | grep -v "no")) ]]; then
  JAVA=$(which java)
else
  echo "Can't find java in your PATH"
  exit 1
fi

export JAVA_OPTS="-Djava.util.logging.manager=java.util.logging.LogManager -Djava.util.logging.config.file=logging.properties"
$JAVA $JAVA_OPTS -jar $RDIR/jbossMultiQuery.jar "$@"
