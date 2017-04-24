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

  TestCodecArchList=("x86" "x64")

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
  for Codec in  ${TestCodecList[@]}
  do
    for Arch in ${TestCodecArchList[@]}
    do

      #prepare test codec and clean previous test data
      git clean -fdx
      CodecBinFile="${Codec}/${Arch}/h264enc"
      TestDataFolder="TestData_${Codec}_${Arch}"
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
        echo ""
        echo "*************************************************"
        echo "test YUV is ${TestYUV}"
        echo "*************************************************"
        echo ""

        ./run_MememAnalyseForOneYUV.sh ${TestYUV} ${TestYUVPath}

        echo ""
        echo "*************************************************"
        echo "end test for ${TestDataFolder}  ${TestYUV}"
        echo "*************************************************"
        echo ""
      done

      #rename test data and commit to git repos for special codec/arch
      [ -d ${TestDataFolder} ] && rm -rf ${TestDataFolder}
      mv TestData ${TestDataFolder}
      git add ${TestDataFolder}/*
      git commit -m "update test data for ${TestDataFolder}, date::${TestDate}"

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
