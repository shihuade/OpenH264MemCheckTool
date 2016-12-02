#!/bin/bash

runInit()
{
  CurDir=`pwd`
  OutputDir="${CurDir}/TestData"
  EncoderLog="EncoderLog.txt"

  Encoder="encConsole"
  EncCfg="welsenc.cfg"
  LayerCfg="layer2.cfg"
  BitStream="test.264"
  TestReport="${OutputDir}/TestReport.csv"
  MemCheckFile="enc_mem_check_point.txt"

  [ -d ${OutputDir} ] && rm -rf ${OutputDir}
  mkdir ${OutputDir}
  BackupDir="${OutputDir}/EncCfg"
  mkdir ${OutputDir}/EncCfg

  ReportHeadLine="Slc_0_Thr,Slc_1_Thr,Slc_2_Thr,SHA1,LayerSize,SlcSize_0,SlcSize_1,SlcSize_2"
  echo ${ReportHeadLine}
  echo ${ReportHeadLine} >${TestReport}
}

runParseInfo()
{
  ParseIdx=$1
#echo "  *********encode parse ParseIdx $ParseIdx***************"

  LayerSize=`cat ${EncoderLog} | grep "iLayerSize is" | awk '{print $3}'`
  SliceThread_0=`cat ${EncoderLog} | grep "Slc, 0, 0," | awk 'BEGIN {FS=","} {print $4}'`
  SliceThread_1=`cat ${EncoderLog} | grep "Slc, 0, 1," | awk 'BEGIN {FS=","} {print $4}'`
  SliceThread_2=`cat ${EncoderLog} | grep "Slc, 0, 2," | awk 'BEGIN {FS=","} {print $4}'`

  SliceSize_0=`cat ${EncoderLog} | grep "Slc, 0, 0," | awk 'BEGIN {FS=","} {print $5}'`
  SliceSize_1=`cat ${EncoderLog} | grep "Slc, 0, 1," | awk 'BEGIN {FS=","} {print $5}'`
  SliceSize_2=`cat ${EncoderLog} | grep "Slc, 0, 2," | awk 'BEGIN {FS=","} {print $5}'`

  SHA1String=`openssl sha1 ${BitStream} | awk 'BEGIN {FS="="}{print $2}'`


  Info="${SliceThread_0}, ${SliceThread_1}, ${SliceThread_2}, ${SHA1String}, ${LayerSize} ${SliceSize_0}, ${SliceSize_1}, ${SliceSize_2}"
  echo ${Info} >> ${TestReport}
  echo ${Info}

  #check leak size
  LeakSize=`cat ${EncoderLog} | grep "Leak size is" | awk '{print $4}'`
  MemCheckFileBackFile="${OutputDir}/${MemCheckFile}_${LeakSize}_Loop_$ParseIdx.txt"

  echo "Leak size is ${LeakSize}, BackFile is ${MemCheckFileBackFile}"

  mv ${MemCheckFile} ${MemCheckFileBackFile}
  mv ${BitStream}    ${OutputDir}/${ParseIdx}_${BitStream}
  mv ${EncoderLog}   ${OutputDir}/${ParseIdx}_${EncoderLog}
}

runLoop()
{
  for((i=0; i<500; i++))
  do
    echo "*********encode loop idx $i***************"
    ./${Encoder} ${EncCfg} >${EncoderLog}
    runParseInfo $i
  done
}

runBackupTestCfg()
{
  cp ${Encoder}   ${BackupDir}
  cp ${EncCfg}    ${BackupDir}
  cp ${LayerCfg}  ${BackupDir}
}

runMain()
{
  runInit
  runLoop

  runBackupTestCfg
}

runMain

