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
  #Encoder="encConsole"
  Encoder="h264enc"
  EncCommand=""
  MemLogFile="enc_mem_check_point.txt"

  #Test Space
  TestSpace="TestData"
  [ ! -d ${TestSpace} ] && mkdir ${TestSpace}
  #rm -f ${TestSpace}/*

  #Memory analyse option
  MemAnalyseOption="OverallCheck"

  #Test report file
  TestReport="${TestSpace}/MemReport_For_${YUVName}.csv"
  echo "${YUVName}, SliceMode, SlcNum, PicW, PicH, ThrdNum, AllocSize, FreeSize, LeakSize, FPS">${TestReport}

}


runInitTestParam()
{
   SliceMode=(0  1  2 3)
   SliceNum=(1 4  4 0 )
   ThreadNum=(1 2 3 4)
   ParamNum=${#SliceMode[@]}

   SliceSize=(1500 800 600)
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
  echo "SliceMode:    ${SliceMode[@]}"
  echo "***********************************************"
}

runAnalyseMemForOneParam()
{
    TestMemLogFile="${TestSpace}/enc_mem_check_point_${YUVName}_${SliceMode[$i]}_${SliceNum[$i]}_${iThrdNum}_${iSlcSize}.txt"
    TestAnalyseResult="${TestSpace}/MemAnalyseResut_${YUVName}_${SliceMode[$i]}_${SliceNum[$i]}_${iThrdNum}_${iSlcSize}.txt"
    [ -e ${MemLogFile} ] && rm ${MemLogFile}

    EncCommand="./$Encoder  welsenc.cfg  -frms 1000 -org ${YUVFile} -dw 0 ${PicW} -dh 0  ${PicH} -threadIdc ${iThrdNum}"
    EncCommand="${EncCommand} -SliceMode 0 ${SliceMode[$i]}  -slcnum 0 ${SliceNum[$i]} -SliceSize 0 ${iSlcSize}"

    echo ""
    echo "***********************************************"
    echo "TestMemLogFile    is: ${TestMemLogFile}"
    echo "TestAnalyseResult is: ${TestAnalyseResult}"
    echo "EncCommand is:"
    echo "${EncCommand}"
    echo "***********************************************"
    echo ""
    ${EncCommand} >${EncoderLog}

    mv ${MemLogFile} ${TestMemLogFile}

    #memory analyse for one encoding param
    ./run_ParseMemCheckLog.sh ${TestMemLogFile} ${TestAnalyseResult} ${MemAnalyseOption} >${MemAnalyseLog}

    #parse analyse result
    OverallAllocateSize=`cat ${MemAnalyseLog} | grep "Overall_AllocateSize" | awk '{print $2}'`
    OverallFreeSize=`cat ${MemAnalyseLog} | grep "Overall_FreeSize" | awk '{print $2}'`
    OverallLeakSize=`cat ${MemAnalyseLog} | grep "Overall_LeakSize" | awk '{print $2}'`
    FPS=`cat ${EncoderLog} | grep "FPS" | awk '{print $2}'`

    ReportInfo="${YUVName}, ${SliceMode[$i]}, ${SliceNum[$i]}, ${PicW}, ${PicH}, ${iThrdNum}"
    ReportInfo="${ReportInfo}, ${OverallAllocateSize}, ${OverallFreeSize}, ${OverallLeakSize}, ${FPS}"

    echo " Overall_AllocateSize  $OverallAllocateSize"
    echo " Overall_FreeSize      $OverallFreeSize"
    echo " Overall_LeakSize      $OverallLeakSize"
    echo " FPS                   $FPS"
    echo " ReportInfo is: "
    echo " ${ReportInfo}  "
    echo " ${ReportInfo}  " >>${TestReport}
}

run_AnalyseMemForAllParamSet()
{

  MemAnalyseLog="Memory_Analyse_Summary.txt"
  EncoderLog="EncoderCaseLog.txt"
  let "OverallAllocateSize = 0"
  let "OverallFreeSize = 0"
  let "OverallLeakSize = 0"
  let "FPS = 0"
  ReportInfo=""

  for((i=0; i<${ParamNum}; i++))
  do
    for iThrdNum in ${ThreadNum[@]}
    do
      for iSlcSize in ${SliceSize[@]}
      do
        runAnalyseMemForOneParam

      done
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








