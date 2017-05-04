#!/usr/bin/env bash

# Process command line args
while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -t|--test)
    test="$2"
    shift # past argument
    ;;
    *)
    echo -e >&2 "ERROR: Invalid option: $1\n"
    exit 1
    ;;
esac
shift # past argument or value
done

if [ "$test" = "" ]; then
    echo -e >&2 "ERROR: Invalid test: $test\n"
    exit 1
fi

echo "INFO: Sourcing hdk_setup.sh"
source $WORKSPACE/hdk_setup.sh;


echo "INFO: Setting CL_DIR=$HDK_DIR/cl/examples/$test"
export CL_DIR=$HDK_DIR/cl/examples/$test

if [ ! -d $CL_DIR ]; then
    echo -e >&2 'ERROR: The test passed in does not exist!'
    exit 1
fi

echo "INFO: Running $HDK_DIR/cl/examples/$test/build/scripts/aws_build_dcp_from_cl.sh -foreground"

cd $HDK_DIR/cl/examples/$test/build/scripts
./aws_build_dcp_from_cl.sh -foreground

if [ $? -ne 0 ]; then
        echo -e >&2 "ERROR: Non zero error code while generating DCP!";
        exit 1
fi

echo "INFO: DCP Generation Finished"

if [ ! -d $HDK_DIR/cl/examples/$test/build/checkpoints/to_aws ]; then
    echo -e >&2 'ERROR: The checkpoints/to_aws directory does not exist! Maybe the checkpoint wasnt created?'
    exit 1
fi

cd $HDK_DIR/cl/examples/$test/build/checkpoints/to_aws

echo "INFO: Checking that a non zero size manifest file exists in the folder"

non_zero_manifest=$(find . -name "*.manifest.txt" -type f ! -size 0)

if [ "$non_zero_manifest" = "" ]; then
    echo -e >&2 "ERROR: Manifest file not found or is of 0 byte size\n"
    exit 1
fi

echo "INFO: Checking that a non zero size dcp file exists in the folder"

non_zero_dcp=$(find . -name "*.dcp" -type f ! -size 0)

if [ "$non_zero_dcp" = "" ]; then
    echo -e >&2 "ERROR: DCP file not found or is of 0 byte size\n"
    exit 1
fi

echo "INFO: Checking that a dcp exists in the tar file"
/usr/bin/tar tvf *.Developer_CL.tar "*.dcp"

if [ $? -ne 0 ]; then
        echo -e >&2 "ERROR: Did not find dcp in the tar file!";
        exit 1
fi

echo "INFO: Checking that a manifest exists in the tar file"
/usr/bin/tar tvf *.Developer_CL.tar "*.manifest.txt"

if [ $? -ne 0 ]; then
        echo -e >&2 "ERROR: Did not find the manifest in the tar file!";
        exit 1
fi

