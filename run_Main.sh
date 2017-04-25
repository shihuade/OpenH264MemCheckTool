#!/bin/bash


runUsage()
{
  echo " Usage: $0  \$TestYUVListDir"

}



runInit()
{
  TestYUVList=("CiscoVT2people_320x192_12fps.yuv"  \
               "xuemei_640x360.yuv" \
               "Zhuling_1280x720.yuv" \
               "desktop_dialog_1920x1080_i420.yuv" \
               "SlideShowFast_SCC_2880x1800.yuv")

  TestCodecList=("Codec_NewDesign" \
                 "Codec_NewDesign_Step_1-3" \
                 "Codec_NewDesign_Step_1-4" \
                 "Codec_OriginDesign")

  TestCodecArchList=("x64" "x86")

  [ -d ${TestYUVPath} ] && cd ${TestYUVPath} && TestYUVPath=`pwd` && cd -
}

runOutputInit()
{
  echo "*************************************************"
  echo "TestYUVList is:"
  echo " ${TestYUVList[@]}"
  echo "*************************************************"
  echo "TestCodecList is:"
  echo " ${TestCodecList[@]}"
  echo "*************************************************"
  echo "TestCodecArchList is:"
  echo " ${TestCodecArchList[@]}"
  echo "*************************************************"
}



runTestAllYUVforAllCodec()
{
  TestDate=`date`
  let "TestIdx = 0"
  for Codec in  ${TestCodecList[@]}
  do
    for Arch in ${TestCodecArchList[@]}
    do
      #prepare test codec and clean previous test data
      rm -f h264enc
      CodecBinFile="${Codec}/${Arch}/h264enc"
      TestDataFolder="TestData/${Codec}/${Arch}"
      [ -d ${TestDataFolder} ] && rm -rf ${TestDataFolder}
      mkdir ${TestDataFolder}
      cp ${CodecBinFile}  ./

      echo "*************************************************"
      echo "*************************************************"
      echo "start to test for ${Codec} with arch ${Arch}"
      echo "CodecBinFile   is  ${CodecBinFile}"
      echo "TestDataFolder is  ${TestDataFolder}"
      echo "*************************************************"
      echo "*************************************************"

      for TestYUV in ${TestYUVList[@]}
      do
        TestCommand="./run_MememAnalyseForOneYUV.sh ${TestYUV} ${TestYUVPath} ${TestDataFolder}"
        echo ""
        echo "*************************************************"
        echo "test YUV is ${TestYUV}"
        echo "TestCommand is ${TestCommand}"
        echo "*************************************************"
        echo ""

        git status
        pwd
        [ ! -e h264enc ] && echo "h264enc not found!" && exit 1
        ${TestCommand}
        let "TestIdx += 1"

        echo ""
        echo "*************************************************"
        echo "end test for ${TestDataFolder}  ${TestYUV}"
        echo " TestIdx is ${TestIdx}"
        echo "*************************************************"
        echo ""
      done
    done
  done
}


runMain()
{
  runInit

  runOutputInit

  runTestAllYUVforAllCodec

}

#***********************************************************************
#***********************************************************************
TestYUVPath=$1

if [ ! -d ${TestYUVPath} ]
then
    echo "test YUV path does not exist, please double check!"
    runUsage
    exit 1
fi

runMain
#***********************************************************************
#***********************************************************************
