#!/bin/bash -x
# dnanexus_nirvana_2.0.3 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://documentation.dnanexus.com/developer for tutorials on how
# to modify this file.


main() {
    # First we need to install dotnet, which is required to run Nirvana. 
    # This is not available in stock Ubuntu repos so we need to some extra steps to enable this

    # Adapted from:
    # https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1604
    # https://github.com/dnanexus/dx-toolkit/tree/master/doc/examples/dx-apps/external_apt_repo_example


    # Bypass the APT caching proxy that is built into the execution environment.
    # It's configured to only allow access to the stock Ubuntu repos.
    sudo rm -f /etc/apt/apt.conf.d/99dnanexus

    # Set up access to the external APT repository.
    echo "Setting up dotnet"
    wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb

    # Update and install the .NET Core SDK. 
    # install -y avoids y/n prompt
    sudo apt-get update
    sudo apt-get install -y apt-transport-https
    sudo apt-get update
    sudo apt-get install -y dotnet-sdk-2.2

    # Update and install the ASP.NET Core runtime
    sudo apt-get update
    sudo apt-get install apt-transport-https
    sudo apt-get update
    sudo apt-get install aspnetcore-runtime-2.2

    # Update and install the .NET Core runtime
    sudo apt-get update
    sudo apt-get install apt-transport-https
    sudo apt-get update
    sudo apt-get install dotnet-runtime-2.2

    # No, I do not want Microsoft looking over my shoulder
    DOTNET_CLI_TELEMETRY_OPTOUT=1

    # dotnet is now installed!
    echo "dotnet installed!"
    
    # Download Nirvana
    echo "Setting up Nirvana"

    # Unpack Nirvana tarball
    tar xzf /Nirvana/Nirvana-2.0.3.tar.gz
    
    # Build Nirvana
    TOP_DIR=$(pwd)
    NIRVANA_ROOT=$TOP_DIR/Nirvana-2.0.3
    NIRVANA_BIN=$NIRVANA_ROOT/bin/Release/netcoreapp2.0/Nirvana.dll

    cd $NIRVANA_ROOT
    dotnet build -c Release
    cd $TOP_DIR
    echo "Nirvana built!"


    # Add annotation data
    echo "Building annotation data"

    # Data is stored in 001
    REF_PROJECT=project-FjXxBx00P1B2ZJ0Q9KvXX84j
    dx ls $REF_PROJECT

    CACHE_FILE=file-FjZ9BG00P1BKyVb7BZVzG26b
    REFERENCES_FILE=file-FjZ8Kq00P1B2Yp2ZKg4Z2q55
    SUPP_DATABASE_FILE_GRCH37=file-FjZ8Q400P1B9X0yK1qY9JZgx

    # Download data
    NIRVANA_DATA_DIR=$NIRVANA_ROOT/Data
    mkdir $NIRVANA_DATA_DIR

    echo "Downloading data"
    dx download $REF_PROJECT:$CACHE_FILE -o $NIRVANA_DATA_DIR
    dx download $REF_PROJECT:$REFERENCES_FILE -o $NIRVANA_DATA_DIR
    dx download $REF_PROJECT:$SUPP_DATABASE_FILE_GRCH37 -o $NIRVANA_DATA_DIR

    # Unpack it to the expected dirs
    echo "Unpacking data"
    NIRVANA_CACHE_DIR=$NIRVANA_DATA_DIR/Cache/24/GRCh37
    NIRVANA_REF_DIR=$NIRVANA_DATA_DIR/References/5
    NIRVANA_SUPP_DIR=$NIRVANA_DATA_DIR/SupplementaryDatabase/41

    mkdir -p $NIRVANA_CACHE_DIR $NIRVANA_REF_DIR $NIRVANA_SUPP_DIR

    tar xzf $NIRVANA_DATA_DIR/v24.tar.gz -C $NIRVANA_DATA_DIR
    tar xzf $NIRVANA_DATA_DIR/v5.tar.gz -C $NIRVANA_DATA_DIR
    tar xzf $NIRVANA_DATA_DIR/v41_GRCh37.tar.gz -C $NIRVANA_SUPP_DIR  # This tar doesn't contain parent dirs, other two do
    
    echo "Done building annotation data"
    

    echo "Value of input_vcf: '$input_vcf'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$input_vcf"     

    # Running Nirvana

    # Set reference genome and build links to data resources
    REFERENCE_BUILD=GRCh37
    NIRVANA_CACHE=$NIRVANA_DATA_DIR/Cache/24/$REFERENCE_BUILD/Both84  # Numbers here will need to be tweaked if Nirvana version changes
    NIRVANA_SUPP=$NIRVANA_DATA_DIR/SupplementaryDatabase/41/$REFERENCE_BUILD
    NIRVANA_REF=$NIRVANA_DATA_DIR/References/5/Homo_sapiens.$REFERENCE_BUILD.Nirvana.dat

    command="dotnet $NIRVANA_BIN --cache $NIRVANA_CACHE --sd $NIRVANA_SUPP --ref $NIRVANA_REF --in $input_vcf_name --out $input_vcf_prefix"
    echo -e $command
    eval $command

    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    output_json=$(dx upload ${input_vcf_prefix}.json.gz --brief)
    
    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output output_json "$output_json" --class=file
}