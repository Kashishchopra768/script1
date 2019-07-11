#!/bin/bash

SNAPSHOT_BEFORE_FAILED=()
SNAPSHOT_AFTER_FAILED=()

create_build(){
        local version1=$1
        local CURRENT_DIR=$2
        cd $CURRENT_DIR
        mkdir -p cos/releases/domain_Cos$version1/release_"$version1".0.0_dummy
        ls -la cos/releases/domain_Cos$version1 | grep "current_release"
        if (( $? == 0 )) ;then
                echo "Link:current_release already exist"
        else
                echo "No link, creating a new one for current_release"
                cd cos/releases/domain_Cos$version1
                ln -s release_"$version1".0.0_dummy current_release
        fi
        echo "build release successfull"
        cd $CURRENT_DIR
        mkdir -p cos/config
        ls -la cos/config/ | grep "Cos${version1}"
        if (( $? == 0 ))
        then
                echo "Link:Cos${version1} already exist"
        else
                cd cos/config
                ln -s ../releases/domain_Cos${version1}/current_release Cos${version1}
                cd ..
                cd ..
        fi
        echo "mapped release successful"
        return 1
}


array_diff(){

                 awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")

}

restore_state(){
        local res=1
        echo "restoring state"
        working_tree_diff=($(array_diff SNAPSHOT_AFTER_FAILED[@] SNAPSHOT_BEFORE_FAILED[@]))

		for (( c1=0; c1<${#bad_working_tree[@]}; c1++ ))
		do
    			echo ${bad_working_tree[$c1]}
		done

                for REF_DEL in ${working_tree_diff[@]}
                do
                        if [ -d "$REF_DEL" ]
                        then
                                rm -rf "$REF_DEL"
                        elif [ -f "$REF_DEL" ]
                then
                        rm -f "$REF_DEL"
                elif [ -e "$REF_DEL" ]
                then
                        echo "new files will be created: $REF_DEL"
                else
                        echo "..."
                        fi
                done
                res=0
                echo "state restored"
        return $res

}

update_symlinks(){
        local res=1
	echo "updating symlink"
	local res=1
	local links=$(find . -type l -ls)
	local temp_release=current_release
	local tempPwd=$2
	local tempReleaseD=cos/releases/domain_Cos${1}
	local tempLink=release_"$1".0.0_dummy
	local tempDirTest=cos/releases/domain_Cos$1/release_"$1".0.0_dummy
	create_symlink $tempReleaseD $tempPwd $tempLink $temp_release $tempDirTest
	temp_release=previous_release
	create_symlink $tempReleaseD $tempPwd $tempLink $temp_release $tempDirTest
	res=$?
	local new_links=$(find . -type l -ls)
	if [ $res==0 ]
	then
		res=0
		echo "previous symlynks are following -"
		echo "$links"
		echo "new symlynks are following -"
		echo "$new_links"
	fi
	return $res
        }
take_snapshot(){

         local TARGET_DIR=$1
        local update_status=$2
         local counter=0;
        local scan_dir=$(find $TARGET_DIR)

        if [ $update_status == 0 ]

                then
                        if [ -d "$TARGET_DIR" ]
                                then
                                        for S in $scan_dir
                                                do
                                                        SNAPSHOT_BEFORE_FAILED[$counter]="$S"
                                                        counter=$((counter+1))
                                                done
                        fi
        else
                        if [ -d "$TARGET_DIR" ]
                                then
                                        for S1 in $scan_dir
                                                do
                                                        SNAPSHOT_AFTER_FAILED[$counter]="$S1"
                                                        counter=$((counter+1))
                                                done
                        fi
        fi
                }





Backup_descriptor(){

        local TARGET_VER=$1
        unset SNAPSHOT_BEFORE_FAILED
        unset SNAPSHOT_AFTER_FAILED

        echo "taking folder and link snapshot"
        #0 and 1(else) is used as update status flag for before and after call of "create_build"
        take_snapshot $PWD 0

		for (( c=0; c<${#SNAPSHOT_BEFORE_FAILED[@]}; c++ ))
                    do
                        echo ${SNAPSHOT_BEFORE_FAILED[$c]}
                    done
        sleep 1
        echo "snapshot created"
        echo "now building the project"
        create_build $TARGET_VER $PWD
        local res=$? #res will contain if build has failed or not

	
                
          
     

        if [ $res -ne 0 ]
        then
                echo "taking folder and link snapshot after build"
                take_snapshot $PWD 1
		for (( c1=0; c1<${#SNAPSHOT_AFTER_FAILED[@]}; c1++ ))
                do
                        echo ${SNAPSHOT_AFTER_FAILED[$c1]}
                done
                sleep 1

                 echo "applying backup of last successfull working state"
                restore_state
                        if [ $?==0 ]
                        then
                        echo "state restored successfully"
                        else
                        echo "oops !! something went wrong"
                        fi
                sleep 1
                #echo "now restoring symlink"
			local TargetReleaseD=cos/releases/domain_Cos${1} 
			local check=$? echo $shouldCallUpdateLink 
			if [ -d "$TargetReleaseD" ] 
			then 
			update_symlinks $TARGET_VER $PWD 
			fi

                #update_symlinks $TARGET_VER $PWD

        sleep 1
               
        else
                echo "create_build did not throw any error !! no need to restore anything"
        fi


}

if [ -z "$1" ]
then
	echo "wrong version"
else
	Backup_descriptor $1
fi
