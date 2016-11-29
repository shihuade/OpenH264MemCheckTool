#!/bin/bash

runInit()
{
  if [ ! -e ${LogFile} ]
  then
    echo "mem check log file does not exist, please double check!"
    exit 1
  fi

  # temp files for mem leak check
  MemCheckLog="MemCheck.log"
  BufferNameList="MemCheck_BufferNameList.txt"
  LeakBufferInfo="MemCheck_LeakBuffer.txt"
  LeakBufferNameList="MemCheck_LeakBufferList.txt"
  Report="MemCheck_Report.txt"
  [ -e ${BufferNameList} ]     && rm ${BufferNameList}
  [ -e ${LeakBufferNameList} ] && rm $LeakBufferNameList

  # Mem leak check info
  let "AllocateSize = 0"
  let "FreeSize     = 0"
  let "AllocatedNum = 0"
  let "FreeNum      = 0"
  let "LeakSize     = 0"
  let "OverallLeakSize = 0"

  echo "${OutFile}" >${OutFile}
  echo "*********start to parse*************"
}

runParse()
{
  while read line
  do
    if [[ "$line" =~ "WelsFree()" ]]
    then
         templine=`echo $line | awk 'BEGIN {FS="-"} {print $2}'`
    else
	    templine=`echo $line | awk 'BEGIN {FS="actual uiSize:"} {print $2}'`
    fi
    echo ${templine} >>${OutFile}

  done < ${LogFile}

}

runCheckLeakWithAllBuffer()
{
    let "AllocateSize = 0"
    let "FreeSize     = 0"
    let "AllocatedNum = 0"
    let "FreeNum      = 0"

    MemLeakStatus="True"
    while read line
    do
        if [[ "$line" =~ "WelsMalloc()" ]]
        then
            TempAllocatedSize=`echo $line | awk 'BEGIN {FS="actual uiSize:"} {print $2}' | awk '{print $1}'`
            let "AllocatedNum ++"
            let "AllocateSize += ${TempAllocatedSize}"

        elif [[ "$line" =~ "WelsFree()" ]]
        then
            TempFreeSize=`echo $line | awk 'BEGIN {FS=":"} {print $2}' | awk '{print $1}'`
            let "FreeNum ++"
            let "FreeSize += ${TempFreeSize}"
        fi
    done <${LogFile}

    [ ${AllocateSize} -eq ${FreeSize} ] && [ ${AllocatedNum} -eq ${FreeNum} ] && MemLeakStatus="False"
    if [ "$MemLeakStatus" = "True" ]
    then
        echo "${BufferName}" >>${LeakBufferNameList}
    fi

    let "OverallLeakSize  = ${AllocateSize} - ${FreeSize}"

    OverAllSummary="MemLeakStatus $MemLeakStatus: AllocatedNum--FreeNum ($AllocatedNum--$FreeNum) : AllocateSize==FreeSize==LeakSize ($AllocateSize==$FreeSize==$OverallLeakSize) "
    echo ${OverAllSummary}>>${OutFile}

}


runCheckLeak()
{
  MemCheckLogFile=$1
  let "AllocateSize = 0"
  let "FreeSize     = 0"
  let "AllocatedNum = 0"
  let "FreeNum      = 0"
  let "LeakSize     = 0"

  MemLeakStatus="True"
  while read line
  do
    if [[ "$line" =~ "WelsMalloc()" ]]
    then
      MatchInfo=`echo ${line} | grep " ${BufferName}"$ `
      if [ "${MatchInfo}X" != "X" ]
      then
        TempAllocatedSize=`echo $line | awk 'BEGIN {FS="actual uiSize:"} {print $2}' | awk '{print $1}'`
        let "AllocatedNum ++"
        let "AllocateSize += ${TempAllocatedSize}"
        #echo "TempAllocatedSize is $TempAllocatedSize"
      fi

    elif [[ "$line" =~ "WelsFree()" ]]
    then
      MatchInfo=`echo ${line} | grep " ${BufferName}:" `
      if [ "${MatchInfo}X" != "X" ]
      then
        TempFreeSize=`echo $line | awk 'BEGIN {FS=":"} {print $2}' | awk '{print $1}'`
        let "FreeNum ++"
        let "FreeSize += ${TempFreeSize}"
        #echo "TempFreeSize is $TempFreeSize"
      fi
    fi
  done <${MemCheckLogFile}

  [ ${AllocateSize} -eq ${FreeSize} ] && [ ${AllocatedNum} -eq ${FreeNum} ] && MemLeakStatus="False"
  if [ "$MemLeakStatus" = "True" ]
  then
    echo "${BufferName}" >>${LeakBufferNameList}
  fi

  let "LeakSize  = ${AllocateSize} - ${FreeSize}"

  Summary="MemLeakStatus $MemLeakStatus: $BufferName AllocatedNum--FreeNum ($AllocatedNum--$FreeNum) : AllocateSize==FreeSize==LeakSize ($AllocateSize==$FreeSize==$LeakSize) "
  echo ${Summary}>>${OutFile}

}

runGetBufferNameList()
{
  while read line
  do
    if [[ "$line" =~ "WelsMalloc()" ]]
    then
      BufferName=`echo $line | awk 'BEGIN {FS=" - "} {print $2}'`
    elif [[ "$line" =~ "WelsFree()" ]]
    then
      BufferName=`echo $line | awk 'BEGIN {FS=" - "} {print $2}' | awk 'BEGIN {FS=":"} {print $1}'`
    fi

    if [ -e ${BufferNameList} ]
    then
      NameInfoPre=`cat ${BufferNameList} | grep ^"${BufferName}" `
      NameInfoSuf=`cat ${BufferNameList} | grep "${BufferName}"$ `

      [ "${NameInfoPre}X" = "X" ] && [ "${NameInfoSuf}X" = "X" ] && echo ${BufferName} >> ${BufferNameList}
    else
      echo ${BufferName} > ${BufferNameList}
    fi
  done < ${LogFile}

  echo -e "\n\n"
  echo "*******************************************"
  echo "          Buffer name list:                "
  echo "*******************************************"
  cat ${BufferNameList}
  echo "*******************************************"
  echo "*******************************************"

}

runCheckAllocateAndFree()
{
  while read line
  do
    BufferName="$line"
    cat ${LogFile} | grep "${BufferName}" > ${MemCheckLog}
    #cat ${LogFile} | grep "${line}"
    runCheckLeak ${MemCheckLog}

  done < ${BufferNameList}

  cat ${OutFile} | grep "MemLeakStatus True" >${LeakBufferInfo}

}

runGetLeakSize()
{
  let "LeakSize     = 0"
  while read line
  do
    TempLeakSize=`echo $line | awk 'BEGIN {FS="=="} {print $NF}' | awk 'BEGIN {FS=")"} {print $1}'`
    let "LeakSize  += ${TempLeakSize}"
  done <${LeakBufferInfo}
}

runOutputMemStatus()
{
  echo -e "\n\n"
  echo "*******************************************"
  echo "           Buffer status:                     "
  echo "*******************************************"
  cat ${OutFile}
  echo "*******************************************"
  echo "            Leak info:                     "
  echo "*******************************************"
  cat ${LeakBufferNameList}
  echo "*******************************************"
  cat ${LeakBufferInfo}
  echo "*******************************************"
  echo "*******************************************"
  echo "over all leak size is ${LeakSize}"
  echo " OverAllSummary is $OverAllSummary"
  echo "*******************************************"
  echo "*******************************************"
}

runMain()
{
  runInit

  if [[ "$Option" =~ "MemCheck" ]]
  then
    runGetBufferNameList
    runCheckAllocateAndFree
    runGetLeakSize

    runCheckLeakWithAllBuffer

    runOutputMemStatus >${Report}
    cat ${Report}
  else
    runParse
  fi


}

LogFile=$1
OutFile=$2
Option=$3

runMain
