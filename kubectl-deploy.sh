#!/bin/bash

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
NC='\033[0m'

ARGS=$@;
BASEDIR="./";
APPNAME="";
options=$(getopt -l "list,deploy,help,app:,environment:,trace" -o "l,d,h,a:,e:,t" -a -- "$@")
trace=false

declare -A values=( )

function read_apps()
{
    echo -e "${Green} available apps ${White}"
    for i in $(ls -d $BASEDIR/*/); do 
    
        path="${i%%/}"
        name=$(basename $path )
        
        if [[ $name == 'template' ]]; then
            continue;
        fi;
        echo "  - APP FOUND FROM FOLDER $name $path";
        len=${#apps[@]}
        apps[$name]=path
    done

    #append files
    for i in $(find $BASEDIR -maxdepth 1 -type f -regex '.*\.yml'); do 
        trimmed="${i//[^.]}"
        if [ "${#trimmed}" -eq 1 ]; then #./xyx.yml 
            path="${i%%/}"
            name=$(basename $path .yml )
            echo "  - APP FOUND FROM FILE $name $path";
            len=${#apps[@]}
            apps[$name]=${i%%/}
        fi
    done
}

function check_install()
{
    echo "checking install";
    if  { [ -x "$(command -v bash-tpl)" ] && ! [  -f ./baseh-tpl.sh ]; };  then
        echo -e "${Yellow}Error: bash-tpl is not installed. installing" 
        curl -s  -L https://raw.githubusercontent.com/TekWizely/bash-tpl/main/bash-tpl --output /usr/bin/bash-tpl.sh && chmod +x /usr/bin/bash-tpl.sh
    fi;
}

function input_parse()
{
    eval set -- "$options"
    COMMAND='help'
    while true; do
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
            -t|--trace)
            trace=true;
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
    shift $((OPTIND-1))
    echo "args: $1"
    BASEDIR=$(realpath $1)
    

   

}

function colEcho( )
{
    message=$1;
    color=$2;
    echo -e "${color}  ${message} ${NC}"
   
}

function condCat( )
{
    file=$1;
    condition=$2;    

    if [ $condition = true ]; then
        colEcho "---" $Blue
        colEcho  "$file"  $Blue
        colEcho "---" $Blue
        cat $file
        colEcho "---" $Blue
    fi;
}


function print_input()
{
    colEcho "working on $BASEDIR" $White
    colEcho "COMMAND $COMMAND" $White;
}

function app_listing()
{
    colEcho "APP LISTING" $Purple

    for i in "${!apps[@]}"
    do 
      echo "$i: ${apps[$i]}"
    done
}

function deploy_app()
{
    tmpFolder=$(mktemp -d);
    echo -e "${Yellow} APP DEPLOY $APPNAME ${White} "
    templateBase=${apps[$APPNAME]}
    valueBase=${templateBase/yml/values\.yml};
    
    valuesMerged=$tmpFolder'/valuesMerged.yml'
    
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

    echo "VALUES MERGED in $valuesMerged"
    condCat $valuesMerged $trace
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
        
        temp_file=$tmpFolder'/tmpTemplate.sh'
        templateBase=$tmpFolder'/templateBuild.yml'
        echo "generating template from source $sourceTemplate, on ${BASEDIR} > $temp_file"
      
        
        # bind tra valore e origine
        bash-tpl.sh  $sourceTemplate  > ${temp_file}
        chmod +x $temp_file

        condCat ${temp_file}    $trace
        sh  ${temp_file} >  ${templateBase}
        condCat ${templateBase}  $trace
    fi;

    templates[0]=$templateBase;

    if [ ! -z  $ENVIRONMENT  ]
    then
        templates[1]=${templateBase/yml/$ENVIRONMENT\.yml};
    fi;

    echo "Template escalation"
    templateMerged=$tmpFolder'/templateMerged.yml'
   
    finalOutput=$tmpFolder'/finalOutput.yml'

    for i in "${!templates[@]}"
    do 
      echo "$i: ${templates[$i]}"      
      yq eval-all '. as $item ireduce ({}; . * $item )'   $templateMerged ${templates[$i]}  > $templateMerged
    done


    echo "VALUES MERGED $templateMerged"
    condCat $templateMerged $trace
    #create values hierarchy



    for fn in $VARS; do 
        echo $fn
        export $fn;
    done
    envsubst < $templateMerged > $finalOutput

    condCat $finalOutput $trace
}

check_install
input_parse
print_input

declare -A apps=( )
read_apps

# command app listing
if [ $COMMAND = "list" ]; then
    app_listing
fi;


if [ "${COMMAND}" = 'deploy' ]; then
  deploy_app
fi;




 
 

