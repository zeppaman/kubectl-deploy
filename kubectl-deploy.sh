#!/bin/bash
# echo "---
#     name=list
#     short=l
#     description=list all the applicatin in a given folder
#     flag=true
#     allow_empty=true
#     default=false
#     ---" > bargs_vars

# # curl -s -L bargs.link/bargs.sh --output bargs.sh

# # curl -s  -L https://raw.githubusercontent.com/TekWizely/bash-tpl/main/bash-tpl --output bash-tpl.sh

# # wget https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# # chmod +x *
# pwd 
# echo "$@"
# currentDir="$(pwd)"
# bargspath="$currentDir/bargs.sh"

# source $bargspath "$@"
#  getopts ":s:p:" o;
#  echo ${o};

options=$(getopt -l "list,deploy,help" -o "l,d,h" -a -- "$@")



# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters 
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

COMMAND='help'

 for o in $options; do
    echo "${o}";
    case "${o}" in
        -l|--list)
            COMMAND="list";
        
            ;;
        -h|--help)
           COMMAND="help";
           ;;
         -d|--deploy)
           COMMAND="deploy";
            ;;
        *)
            echo "HELP"
            ;;
    esac
done

shift $((OPTIND-1))

echo "COMMAND $COMMAND";

declare -A apps=( )

# append folder
for i in $(ls -d */); do 
    path="./${i%%/}"
    name=$(basename $path )
    echo "APP FOUND FROM FOLDER $name $path";
    len=${#apps[@]}
    apps[$name]=path
done

#append files
for i in $(find . -maxdepth 1 -type f -regex '.*\.yml'); do 
    trimmed="${i//[^.]}"
    if [ "${#trimmed}" -eq 2 ]; then #./xyx.yml 
        path="${i%%/}"
        name=$(basename $path .yml )
        echo "APP FOUND FROM FILE $name $path";
        len=${#apps[@]}
        apps[$name]=${i%%/}
    fi
done


if [ $COMMAND = "list" ]
    then
    echo "APP LISTING"

    for i in "${!apps[@]}"
    do 
      echo "$i: ${apps[$i]}"
    done
fi;


if [ "${COMMAND}" = 'deploy' ] 
    then
    echo "APP DEPLOY"

  
fi;


# cat ./test/template/service.yml


exit





export NAME="PROVA"
export FILE="./test/main/main.yml"
export TEMPLATE="./test/template/service.yml"
export VALUES="./test/main/main.values.yml"
yq e '.ports[]' $VALUES
VARS=$(yq eval '.. | select((tag == "!!map" or tag == "!!seq") | not) | (path | join("_")) + "=" + .' $VALUES | sed 's/: /=/')

for fn in $VARS; do
  
    export $fn;
done





# templating
./bash-tpl.sh $TEMPLATE > ./step0.yml.sh
sh  ./step0.yml.sh >  ./step1.yml
# merge
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)'  ./step1.yml $FILE  > ./step2.yml
cat ./step2.yml
envsubst < ./step2.yml > ./step3.yml

 
 
