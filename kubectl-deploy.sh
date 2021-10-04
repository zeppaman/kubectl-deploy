#!/bin/bash

curl -s  -L https://raw.githubusercontent.com/TekWizely/bash-tpl/main/bash-tpl --output /usr/bin/bash-tpl.sh && chmod +x /usr/bin/bash-tpl.sh

# # wget https://github.com/mikefarah/yq/releases/download/v4.13.2/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

# # chmod +x *
# pwd 
# echo "$@"
# currentDir="$(pwd)"
# bargspath="$currentDir/bargs.sh"

# source $bargspath "$@"
#  getopts ":s:p:" o;
#  echo ${o};

options=$(getopt -l "list,deploy,help,app:,environment:" -o "l,d,h,a:,e:" -a -- "$@")

eval set -- "$options"



COMMAND='help'
while true; do
    echo "$1";
    case "$1" in
        -l|--list)
            COMMAND="list";        
            ;;
        -h|--help)
           COMMAND="help";
           ;;
         -d|--deploy)
           COMMAND="deploy";
            ;;
         -a|--app)
            shift    
            APPNAME=$1;
            ;;
          -e|--env)
            shift    
            ENVIRONMENT=$1;
            ;;
          --) shift ; break ;;
        *) 
            echo "Internal error!" ; exit 1 ;;
    esac
    shift
done

echo $1

shift $((OPTIND-1))

BASEDIR=$(realpath $1)

echo working on $BASEDIR

echo "COMMAND $COMMAND";

declare -A apps=( )

# append folder
# for i in $(ls -d $BASEDIR/*/); do 
#     path="${i%%/}"
#     name=$(basename $path )
#     echo "APP FOUND FROM FOLDER $name $path";
#     len=${#apps[@]}
#     apps[$name]=path
# done

#append files
for i in $(find $BASEDIR -maxdepth 1 -type f -regex '.*\.yml'); do 
    trimmed="${i//[^.]}"
    if [ "${#trimmed}" -eq 1 ]; then #./xyx.yml 
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

    echo "APP DEPLOY $APPNAME"
    templateBase=${apps[$APPNAME]}
    valueBase=${templateBase/yml/values\.yml};

    valuesMerged=$(mktemp)

    
    declare -A values=( )

    
    values[0]=$valueBase;

    if [ ! -z  $ENVIRONMENT  ]
    then
        values[1]=${valueBase/yml/$ENVIRONMENT\.yml};
    fi;

    echo "Values escalation"
    for i in "${!values[@]}"
    do 
      echo "$i: ${values[$i]}"      
      yq eval-all '. as $item ireduce ({}; . * $item )'  $valuesMerged ${values[$i]}  > $valuesMerged
    done;

    echo "VALUES MERGED $valuesMerged"
    cat $valuesMerged
    #replace
    VARS=$(yq eval '.. | select((tag == "!!map" or tag == "!!seq") | not) | (path | join("_")) + "=" + .' $valuesMerged | sed 's/: /=/')
    export VALUES=$valuesMerged



    echo $templateBase

    # create template hierachy
    declare -A templates=( )
    line=$(head -n 1 $templateBase)
    sourceTemplate=$(echo "${line}"  | sed  -E  's/^#(.*)FROM(.*)/\2/'  | xargs); # sed  -E  's+\./+'${BASEDIR}/'+g' 

  

    if [ ! -z  $sourceTemplate  ]
    then
        if [[ ! $sourceTemplate == /* ]]
        then
            sourceTemplate="${BASEDIR}/${sourceTemplate}"
            echo normalized $sourceTemplate
        fi;
        
        temp_file=$(mktemp)
        echo "generating template from source $sourceTemplate, on ${BASEDIR} > $temp_file"
      
        chmod +x $temp_file
        # bind tra valore e origine
        bash-tpl.sh  $sourceTemplate  > ${temp_file}01
        cat  ${temp_file}01     
        sh  ${temp_file}01 >  ${temp_file}02
        templateBase= ${temp_file}02
        cat  ${temp_file}02    
    fi;

    templates[0]=$templateBase;

    if [ ! -z  $ENVIRONMENT  ]
    then
        templates[1]=${templateBase/yml/$ENVIRONMENT\.yml};
    fi;

    echo "Template escalation"
    templateMerged=$(mktemp)
   
    finalOutput=$(mktemp)

    for i in "${!templates[@]}"
    do 
      echo "$i: ${templates[$i]}"      
      yq eval-all '. as $item ireduce ({}; . * $item )'   $templateMerged ${templates[$i]}  > $templateMerged
    done


    echo "VALUES MERGED $templateMerged"
    cat $templateMerged
    #create values hierarchy



    for fn in $VARS; do 
        echo $fn
        export $fn;
    done
    envsubst < $templateMerged > $finalOutput

    cat  $finalOutput
fi;


# cat ./test/template/service.yml


exit



exit;

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

 
 
