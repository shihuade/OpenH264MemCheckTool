#!/bin/bash



runUsage()
{
  echo "***********************************************"
  echo "usage:  "
  echo "  $0  \$YUVName \$YUVDir"
  echo "***********************************************"
}

runInit()
{
  cd ${YUVDir} && YUVDir=`pwd` && cd -

  #check test YUV file in given YUVDir
  YUVFile=`./run_GetYUVPath.sh ${YUVName} ${YUVDir}`
  if [ ! $? -eq 0 ]
  then
    echo "error:: YUVName $YUVName not found under YUVDir $YUVDir"
    exit 1
  fi

  #get YUV resolution info
  YUVInfo=(`./run_ParseYUVInfo.sh ${YUVName}`)
  PicW=${YUVInfo[0]}
  PicH=${YUVInfo[1]}

  #codec app setting
  Encoder="encConsole"
  #Encoder="h264enc"
  EncCommand=""
  MemLogFile="enc_mem_check_point.txt"

  #Test Space
  TestSpace="TestData"
  [ ! -d ${TestSpace} ] && mkdir ${TestSpace}
  rm -f ${TestSpace}/*

  #Memory analyse option
  MemAnalyseOption="OverallCheck"

  #Test report file
  TestReport="${TestSpace}/MemReport_For_${YUVName}.csv"
  echo "${YUVName}, SlcMd, SlcNum, PicW, PicH, ThrdNum, AllocSize, FreeSize, LeakSize">${TestReport}

}


runInitTestParam()
{
   SlcMd=(0  1  2 3)
   SlcMum=(1 4  4 0 )
   ThreadNum=(1 2 3 4)
   ParamNum=${#SlcMd[@]}
}

runOutputTestInfo()
{
  echo "***********************************************"
  echo "         basic test info for memory analyse    "
  echo "***********************************************"
  echo " YUVName: $YUVName"
  echo " PicW:    $PicW"
  echo " PicH:    $PicH"
  echo " YUVFile: $YUVFile"
  echo "***********************************************"
  echo "         test param for YUV                    "
  echo "***********************************************"
  echo "SlcMd:    ${SlcMd[@]}"
  echo "***********************************************"
}


run_AnalyseMemForAllParamSet()
{

  MemAnalyseLog="Memory_Analyse_Summary.txt"
  let "OverallAllocateSize = 0"
  let "OverallFreeSize = 0"
  let "OverallLeakSize = 0"
  ReportInfo=""

  for((i=0; i<${ParamNum}; i++))
  do
    for iThrdNum in ${ThreadNum[@]}
    do
      TestMemLogFile="${TestSpace}/enc_mem_check_point_${YUVName}_${SlcMd[$i]}_${SlcMum[$i]}_${ThreadNum}.txt"
      TestAnalyseResult="${TestSpace}/MemAnalyseResut_${YUVName}_${SlcMd[$i]}_${SlcMum[$i]}_${ThreadNum}.txt"
      [ -e ${MemLogFile} ] && rm ${MemLogFile}

      EncCommand="./$Encoder  welsenc.cfg  -frms 64 -org ${YUVFile} -thread ${iThrdNum}"
      EncCommand=" ${EncCommand} -slcmd 0 ${SlcMd[$i]}  -slcnum 0 ${SlcMum[$i]} -dw 0 ${PicW} -dh 0  ${PicH}"

      echo ""
      echo "***********************************************"
      echo "EncCommand is:"
      echo "${EncCommand}"
      echo "***********************************************"
      echo ""
      ${EncCommand}

      mv ${MemLogFile} ${TestMemLogFile}

      #memory analyse for one encoding param
      ./run_ParseMemCheckLog.sh ${TestMemLogFile} ${TestAnalyseResult} ${MemAnalyseOption} >${MemAnalyseLog}

      #parse analyse result
      OverallAllocateSize=`cat ${MemAnalyseLog} | grep "Overall_AllocateSize" | awk '{print $2}'`
      OverallFreeSize=`cat ${MemAnalyseLog} | grep "Overall_FreeSize" | awk '{print $2}'`
      OverallLeakSize=`cat ${MemAnalyseLog} | grep "Overall_LeakSize" | awk '{print $2}'`

      ReportInfo="${YUVName}, ${SlcMd[$i]}, ${SlcMum[$i]}, ${PicW}, ${PicH}, ${iThrdNum}"
      ReportInfo="${ReportInfo}, ${OverallAllocateSize}, ${OverallFreeSize}, ${OverallLeakSize}"

      echo " Overall_AllocateSize  $OverallAllocateSize"
      echo " Overall_FreeSize      $OverallFreeSize"
      echo " Overall_LeakSize      $OverallLeakSize"

      echo "ReportInfo is: "
      echo "${ReportInfo}"
      echo "${ReportInfo}" >>${TestReport}

    done
  done

}

runCheck()
{
  if [ ! -d ${YUVDir} ]
  then
    echo "error:: YUVDir $YUVDir not exist!"
    exit 1
  fi
}

runMain()
{
  runCheck

  runInit
  runInitTestParam
  runOutputTestInfo

  run_AnalyseMemForAllParamSet

}


#*********************************************
#*********************************************
if [ ! $# -eq 2 ]
then
  runUsage
  exit 1
fi

YUVName=$1
YUVDir=$2

runMain

#*********************************************
#*********************************************








