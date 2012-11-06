#!/bin/bash
#
#
# Example
#./check_jmxObject.sh -U service:jmx:rmi:///jndi/rmi://lxomavmtc099.dev.qintra.com:7974/jmxrmi -O Catalina:type=ThreadPool,name=jk-7972 -A currentThreadCount -K AJP -vvv -w 100 -c 200 -2 '-A ThreadCount -K App -vvvv -w 80 -c 100' -3 '-A ThreadCount -K App -vvvv -w 80 -c 100'

export JAVA_HOME=/opt/java-1.6.0_22
export PATH=$PATH:$JAVA_HOME/bin

RDIR=`dirname $0`
while getopts ":U:O:A:K:I:J:r:w:c:2:3:4:5:6:7:8:9:p:u:m:vx" opt;
do
  case $opt in
  U) jmxURL=$OPTARG ;;
  O) jmxObject=$OPTARG ;;
  A) jmxAttribute=$OPTARG ;;
  K) jmxChildAttribute=$OPTARG ;;
  I) jmxTxtAttribute=$OPTARG ;;
  J) jmxChildTxtAttribute=$OPTARG ;;
  r) jmxNameUpdate=$OPTARG ;;
  w) jmxWarningValue=$OPTARG ;;
  c) jmxCriticalValue=$OPTARG ;;
  v) jmxVerbose="vvvv" ;;
  u) jmxUser=$OPTARG ;;
  m) mathExpression=$OPTARG ;;		# -m '/1024' will divide output by 1024
  p) jmxPasswd=$OPTARG ;;
  2) jmx2=$OPTARG; ;;
  3) jmx3=$OPTARG; ;;
  4) jmx4=$OPTARG; ;;
  5) jmx5=$OPTARG; ;;
  6) jmx6=$OPTARG; ;;
  7) jmx7=$OPTARG; ;;
  8) jmx8=$OPTARG; ;;
  9) jmx9=$OPTARG; ;;
  x) disableWarnCrit=true ;;   #Disable warning/critical performance values in graphs.
  *) echo "Usage: $0 -U service:jmx:rmi:///jndi/rmi://<server>:<port>/jmxrmi -O <MBean_Object_Name> -A <Attribute> -K optional <desc> -w # -c #"
     exit 1;;
  esac
done

if [[ -z ${jmxURL} || -z ${jmxObject} || -z ${jmxAttribute} ]]; then
  echo "Error:  Missing Required Input..."
  echo
  echo "Usage: $0 -U service:jmx:rmi:///jndi/rmi://<server>:<jmxPort>/jmxrmi -O <MBean_Object_Name> -A <Attribute> -w <warn#> -c <crit#>"
  echo "Usage: $0 -U service:jmx:rmi:///jndi/rmi://<server>:<jmxPort>/jmxrmi -O <MBean_Object_Name> -A <Attribute> -K <keyDesc> -I <childAttribute> -J <childKeyDesc> -w <warn#> -c <crit#>"
  exit 1
fi

function checkResponse(){
  Response=$1
  #output fix to replace " is " with "="
  OUTPUT=$( echo $OUTPUT | sed 's/\ is\ /=/' )
  OUTPUT=$( echo $OUTPUT | cut -d'|' -f1 )
  Status=$( echo $OUTPUT | awk '{ print $1, $2 }' )
  JmxNoValue=$( echo $OUTPUT | awk '{ print $NF }' | grep 'null' )
  JmxNoKey=$( echo $OUTPUT | awk '{ print $NF }' | grep 'Boolean' )
  if [[ ! -z $JmxNoValue ]]; then
        OUTPUT="${Status} $( echo $OUTPUT | cut -d '=' -f1)=0"
  fi
  if [[ ! -z $JmxNoKey ]]; then
	Status="JMX OK"
	if [[ ! -z $jmxNameUpdate ]]; then
		OUTPUT="${Status} ${jmxNameUpdate}=0"
	else
  		OUTPUT="${Status} NoKey=0"
	fi
  fi
  if [[ ! -z $jmxNameUpdate ]]; then
  	OUTPUT="${Status} ${jmxNameUpdate}=$( echo $OUTPUT | cut -d '=' -f2)"
  fi
  if [[ ! -z $mathExpression ]]; then
        cValue=$( echo $OUTPUT | cut -d '=' -f2)
        nValue=$(echo "${cValue}${mathExpression}"|bc)
        OUTPUT="${Status} $(echo $OUTPUT | cut -d '=' -f1)=${nValue}"
  fi
  verifyPerfOut=$( echo $OUTPUT | awk '{ print $NF }')
  verifyJmxError=$( echo $OUTPUT | awk '{ print $NF }' | egrep "Boolean|jmxquery.JMXQuery" )
  if [[ ${Response} == 1 ]]; then
        WARN_EXIT_STATUS=${Response}
        warnStatus=$Status
        OUTPUT=$( echo $OUTPUT | awk '{ print $NF }' )
  elif [[ ${Response} == 2 ]]; then
        CRIT_EXIT_STATUS=${Response}
        critStatus=$Status
        OUTPUT=$( echo $OUTPUT | awk '{ print $NF }' )
  else
        EXIT_STATUS=${Response}
        goodStatus=$Status
        OUTPUT=$( echo $OUTPUT | awk '{ print $NF }' )
  fi

  if [[ detailOutput != "" ]]; then
        detailOutput="${detailOutput} ${OUTPUT}"
	if [[ ${disableWarnCrit} == "true" ]]; then
		if [[ $verifyPerfOut != "more" && ! -z ${OUTPUT} && -z $verifyJmxError ]]; then
        		perfData="${perfData} ${OUTPUT};"
		else
        		perfData="${perfData}"
		fi
	else
		if [[ $verifyPerfOut != 'more' && ! -z ${OUTPUT} && -z $verifyJmxError ]]; then
        		perfData="${perfData} ${OUTPUT};${jmxWarningValue};${jmxCriticalValue};"
		else
        		perfData="${perfData}"
		fi
	fi
  else
        detailOutput="${OUTPUT}"
	if [[ ${disableWarnCrit} == "true" ]]; then
		if [[ $verifyPerfOut != 'more' && ! -z ${OUTPUT} && -z $verifyJmxError ]]; then
        		perfData="${perfData} ${OUTPUT};"
		else
        		perfData="${perfData}"
		fi
	else
		if [[ $verifyPerfOut != 'more' && ! -z ${OUTPUT} && -z $verifyJmxError ]]; then
        		perfData="${perfData} ${OUTPUT};${jmxWarningValue};${jmxCriticalValue};"
		else
        		perfData="${perfData}"
		fi
	fi
  fi
}

jmxQuery(){
  customquery=""
  if [[ ! -z ${jmxChildAttribute} ]]; then
	customquery="$customquery -K ${jmxChildAttribute}"
  fi
  if [[ ! -z ${jmxTxtAttribute} ]]; then 
	customquery="$customquery -I ${jmxTxtAttribute}"
  fi
  if [[ ! -z ${jmxChildTxtAttribute} ]]; then 
	customquery="$customquery -J ${jmxChildTxtAttribute}"
  fi
  if [[ ! -z ${jmxWarningValue} ]]; then 
	customquery="$customquery -w ${jmxWarningValue}"
  fi
  if [[ ! -z ${jmxCriticalValue} ]]; then 
	customquery="$customquery -c ${jmxCriticalValue}"
  fi
  if [[ ! -z ${jmxUser} && ! -z ${jmxPasswd} ]]; then 
	customquery="$customquery -username ${jmxUser} -password ${jmxPasswd}"
  fi
  OUTPUT=`java -cp $RDIR/jmxquery.jar jmxquery.JMXQuery -U ${jmxURL} -O "${jmxObject}" -A ${jmxAttribute} ${customquery}`
  checkResponse $?
}

parseArgs(){
  tmpArray=( $1 )
  size=${#tmpArray[@]}
  jmxCriticalValue=""
  jmxWarningValue=""
  jmxChildAttribute=""
  jmxTxtAttribute=""
  jmxChildTxtAttribute=""
  jmxNameUpdate=""
  for ((i=0; i<${size}; i++))
  do
    if [[ ${tmpArray[${i}]} == "-c" ]]; then
      jmxCriticalValue=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-r" ]]; then
      jmxNameUpdate=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-w" ]]; then
      jmxWarningValue=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-O" ]]; then
        i=${i}+1
        jmxObject=${tmpArray[${i}]}
      while [ -z `echo ${tmpArray[${i}+1]} | grep -` ]
      do
        jmxObject="${jmxObject} ${tmpArray[${i}+1]}"
        i=${i}+1
      done
    elif [[ ${tmpArray[${i}]} == "-U" ]]; then
      jmxURL=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-A" ]]; then
      jmxAttribute=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-K" ]]; then
      jmxChildAttribute=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-I" ]]; then
      jmxTxtAttribute=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-J" ]]; then
      jmxChildTxtAttribute=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-p" ]]; then
      jmxPasswd=${tmpArray[${i}+1]}
    elif [[ ${tmpArray[${i}]} == "-u" ]]; then
      jmxUser=${tmpArray[${i}+1]}
    fi
  done
}

# Run initial jmx Query
jmxQuery

# Look for additional JMX Queries
if [[ ! -z ${jmx2} ]]; then
  parseArgs "${jmx2}"
  jmxQuery
fi
if [[ ! -z ${jmx3} ]]; then
  parseArgs "${jmx3}"
  jmxQuery
fi
if [[ ! -z ${jmx4} ]]; then
  parseArgs "${jmx4}"
  jmxQuery
fi
if [[ ! -z ${jmx5} ]]; then
  parseArgs "${jmx5}"
  jmxQuery
fi
if [[ ! -z ${jmx6} ]]; then
  parseArgs "${jmx6}"
  jmxQuery
fi
if [[ ! -z ${jmx7} ]]; then
  parseArgs "${jmx7}"
  jmxQuery
fi
if [[ ! -z ${jmx8} ]]; then
  parseArgs "${jmx8}"
  jmxQuery
fi
if [[ ! -z ${jmx9} ]]; then
  parseArgs "${jmx9}"
  jmxQuery
fi
  if [[ ${critStatus} != "" ]]; then
	if [[ ! -z $perfData ]]; then
	  echo "$critStatus $detailOutput|$perfData"
	else
	  echo "$critStatus $detailOutput"
	fi
	exit $CRIT_EXIT_STATUS
  elif [[ ${warnStatus} != "" ]]; then
	if [[ ! -z $perfData ]]; then
	  echo "$warnStatus $detailOutput|$perfData"
	else
	  echo "$warnStatus $detailOutput"
	fi
	exit $WARN_EXIT_STATUS
  else
	if [[ ! -z $perfData ]]; then
	  echo "$goodStatus $detailOutput|$perfData"
	else
	  echo "$goodStatus $detailOutput"
	fi
	exit $EXIT_STATUS
  fi
