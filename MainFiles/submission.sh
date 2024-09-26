#!/bin/bash


# Check if the flag file exists
if [ ! -f .first_run ]; then
    echo "Welcome! This is the first time you are running the script."
    echo "To see the functionalities that are available; run <bash $0 command_help> "
    echo "Happy grading!"
    # Create a flag file to indicate that the script has run before
    touch .first_run
fi

command_help(){
    echo "combine : combines all the csv files in the drectory into a main.csv file"
    echo "upload : uploads a file from the adress provided by user to the current repo"
    echo "total : calculate the total of all the exams in main.csv"
    echo "git_init : to initialize a remote repository"
    echo "git_log : see all your commits with their hash"
    echo "git_commit : save the present version of your current repo into the remote repository"
    echo "git_checkout : go back to a previous version of the repository"
    echo "git_branch : creates a branch(hidden directory) at the commit_id provided in the remote repository"
    echo "git_checkout_branch : reverts to the version of the directory saved in the branch"
    echo "stats : prints the statistics after analysing the main.csv file"
    echo "update : updates the marks of a particular student in main.csv as well as in other related csv files"
}

git_log(){
    remote_dir=$(cat .git_remote)
    cat "$remote_dir/.git_log"
}

#Function to ucombine the csv in the present directory
combine(){
    total_present=0
    if [[ -f main.csv ]]; then
        line=$(grep ".*,total$" main.csv|wc -l)
        if [[ $line -ne 0 ]]; then
        total_present=1
        fi
    fi
    # Creating a main.csv file
    touch main.csv
    echo "Roll_Number,Name" > main.csv

    # Updating the header of main.csv
    for file in *.csv ;
        do 
            # Skip processing main.csv
            if [ "$file" == "main.csv" ] ; then
                continue
            fi

            # Extract filename to update header
            name=$( echo "$file" | cut -d '.' -f 1 )
            old_head=$( head -n +1 main.csv )
            new_head="${old_head},${name}"
            echo $new_head > main.csv

        done

    # Initialize arrays to store roll numbers and names
    declare -a mainroll
    declare -a mainname

    # Loop through each CSV file to collect all the roll no's and names
    for file in *.csv ;
        do
            # Skip processing main.csv
            if [ "$file" == "main.csv" ] ; then
                continue
            fi

            while read line;
                do
                    # Extract roll number and name
                    rollno=$(echo $line | cut -d ',' -f 1)
                    name=$(echo $line | cut -d ',' -f 2 )

                    # Check if roll number already exists in array or if it is the header line that we have read from the file; either case we skip and move onto next line
                    # we are not checking for names as two students can have the same name!
                    if [[ " ${mainroll[@]} " =~ " $rollno " ]] || [[ "$rollno" =~ \s*Roll_Number ]];then
                    continue
                    
                    else
                    # Add roll number and name to arrays
                    mainroll+=("$rollno")
                    mainname+=("$name")

                    fi
                done < $file
        done

    i=${#mainroll[@]}
    val=$((i-1))
    k=0
    
    # Append roll numbers and names to main.csv
    while [ $k -le $val ] ;
    do 
        echo "${mainroll[$k]},${mainname[$k]}" >> main.csv
        k=$((k+1))
    done
    #Iterate through each CSV file again to update marks
    for file in *.csv ;
    do 
            # Skip processing main.csv
            if [ "$file" == "main.csv" ] ; then
                continue
            fi

            # Declare associative array to store roll numbers and marks
            declare -A roll
            
            # Read roll numbers and marks from each CSV file
            while IFS=',' read -r rollno _ marks; do
                roll["$rollno"]=$marks
            done < <(tail -n +2 "$file")
           

            #Loop through each roll number in mainroll array
            for key in "${mainroll[@]}"; 
            do

            # Loop through each roll number and marks in roll array
            
            for no in "${!roll[*]}";
                do 
                    
                    #Check if roll number matches in mainroll array and roll array
                    if [[ "$no" =~ "$key" ]]; then
                        mark=${roll[$key]}
                        # append the marks of the exam in main.csv
                        sed -i "s/^\(${key}[^,]*.*\)/\1,${mark}/" main.csv
                        # sed -i "s/\(^${key},[^,].*\)/\1,${mark}/" main.csv
                        # sed -i "s/^\(${key},[^,]*\)\(.*\)/\1\2,${mark}/" main.csv
                        # sed -i "s/\(^${key}[,a-zA-Z0-9\s]*\)/\1,${mark}/" main.csv



                    else 
                        # If roll number does not exist, mark as absent with 'a' in main.csv
                        sed -i "s/^\(${key}[^,]*.*\)/\1,a/" main.csv
                        #  sed -i "s/\(^${key},[^,].*\)/\1,a/" main.csv
                        # sed -i "s/^\(${key},[^,]*\)\(.*\)/\1\2,a/" main.csv
                        # sed -i "s/^\(${key}[,a-zA-Z0-9\s]*\)/\1,a/" main.csv
    


                    fi
                done

            done

            unset roll

    done


    #if total was already present in the main.csv file updates the total
    if [[ $total_present == 1 ]]; then
        total
    fi 
}


#Function to calculate the total marks of the exams in main.csv
total() {

        awk 'BEGIN{
        FS=","
        OFS=","
        found=0
    }
    {
        if(NR == 1) {
            for (i=1; i<=NF; i++) {
                if ($i == "total") {
                    found=1
                    break
                }
            }
            if (found == 0) {
                print $0,"total"
            } else {
                print $0
            }
        }
        if(NR > 1){
            if (found == 0) {
                val=NF
                sum=0
                for(i=3;i<=NF;i++) {
                    if($i != "a") sum+=$i
                }
                $(NF+1)=sum
                print $0
            } else {
                val=NF
                sum=0
                for(i=3;i<NF;i++) {
                    if($i != "a") sum+=$i
                }
                $NF=sum
                print $0
            }
        }
    }' main.csv > newmain.csv

    cp newmain.csv main.csv
    rm newmain.csv

}

#Function to upload files to the present directory
if [[ $1 == "upload" ]]; then
    if [ -z "$2" ]; then
        echo "Error: File or directory path not provided."
        return 1
    fi
    
    cp $2 ./
fi



# Function to initialize remote directory
git_init() {
    if [ $# -ne 1 ]; then
        echo "Usage: bash $0 git_init <remote_directory>"
        return 1
    fi
    
    remote_dir="$1"
    
    # Check if the remote directory exists , if it does not it creates one!
    if [ ! -d "$remote_dir" ]; then
        echo "Creating a remote directory"
        mkdir $remote_dir
    fi
    
    # Store remote directory path in .git_remote file
    echo "$remote_dir" > .git_remote
    echo "Remote directory initialized: $remote_dir"
}

#Function to commit current version of files to remote directory
git_commit() {
    # Check if .git_remote file exists
    if [ ! -f .git_remote ]; then
        echo "Error: Remote directory not initialized. Please run 'git_init' first."
        return 1
    fi
    
    # Check if the correct number of arguments is provided
    if [ $# -lt 2 ]; then
        echo "Usage: bash $0 git_commit -m <commit_message>"
        return 1
    fi
    
    # Initialize commit_message variable
    commit_message=""
    
    # Parse command-line arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -m) shift; commit_message="$1"; shift;;  # Extract the commit_message
            *) shift;;  # Skip other arguments
        esac
    done
    
    remote_dir=$(cat .git_remote)
    
    # Generate a commit hash / commit id
    commit_id=$(openssl rand -hex 8)
    
    # Copy files to the remote directory with the commit id
    cp -r . "$remote_dir/$commit_id"
    
    # Append commit id and message to .git_log file
    echo "$commit_id: $commit_message" >> "$remote_dir/.git_log"
    
    # Print names of modified files since last commit
    if [ -f "$remote_dir/.last_commit_id" ]; then
        last_commit_id=$(cat "$remote_dir/.last_commit_id")
        
        words=$(diff -rq "$remote_dir/$commit_id" "$remote_dir/$last_commit_id")

        if [[ $words =~ ^Files ]]; then
            
            echo "The modified files are:"
            diff -rq "$remote_dir/$commit_id" "$remote_dir/$last_commit_id" | grep "differ" | cut -d ' ' -f 4 
        else
            # If no files were modified, print a message
            echo "No files were modified"
        fi 
    fi
    
    # Update last commit ID
    echo "$commit_id" > "$remote_dir/.last_commit_id"
}


# Function to checkout to a specific commit
git_checkout() {
    # Check if .git_remote file exists
    if [ ! -f .git_remote ]; then
        echo "Error: Remote directory not initialized. Please run 'git_init' first."
        return 1
    fi
    
    # Read command-line arguments into an array
    args="$@"
    IFS=' ' read -r -a array <<< $args
    num=${#array[@]}  # Get the number of arguments
    
    # Read remote directory from .git_remote file
    remote_dir=$(cat .git_remote)
    
    # When one argument is provided, if it is a commit hash proceed else return
    if [[ $num == 1 ]]; then
        commit_ref="${array[0]}"
        
        # Check if the commit reference is a prefix of any commit hash
        matching_commits=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | wc -l)
        if [ "$matching_commits" -ne 1 ]; then
            echo "Error: Ambiguous commit reference. Please provide a unique commit message or hash."
            return 1
        fi
        
        # Find the full commit hash
        commit_id=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | cut -d ':' -f 1)
        
        # return the current directory to the version of the commit_id
        rm ./*
        cp -r "$remote_dir/$commit_id"/* .
        
        echo "Checked out to commit: $commit_id"
    fi
    
    # If two arguments are provided, if the second argument is a commit msg proceed
    if [[ $num -ge 2 ]]; then
        # Check if the first argument is '-m'
        if [[ ${array[0]} == -m ]]; then
            # Extract commit message from the arguments
            commit_msg=$(echo "$args" | sed 's/-m \(.*\)/\1/')
            
            # Check if any commit has the provided commit message
            matching_commitmsg=$(grep -oE ".*$commit_msg$" "$remote_dir/.git_log" | wc -l)
            num=$((matching_commitmsg))
            if [ "$num" == 0 ]; then
                echo "Error: No matching commit message."
                return 1
            fi
            if [[ $num -gt 1 ]]; then
                echo "More than one commit has the same commit message. Please proceed through git_checkout commit_id."
                return 1
            fi
            
            # Find the commit ID corresponding to the commit message
            commitid=$(grep -oE ".*$commit_msg$" "$remote_dir/.git_log" | cut -d ':' -f 1)
            
            # return the current directory to the version of the commit_id
            rm ./*
            cp -r "$remote_dir/$commitid"/* .
    
            echo "Checked out to commit: $commitid"
        else
            echo "Incorrect usage! Use bash $0 commit_id or bash $0 -m commit_msg"
            return 1
        fi
    fi
}

git_branch(){
    if [ ! -f .git_remote ]; then
        echo "Error: Remote directory not initialized. Please run 'git_init' first."
        return 1
    fi

    if [ ! -f .git_branches ]; then
        touch .git_branches
    fi


    args="$@"
    IFS=' ' read -r -a array <<< $args
    num=${#array[@]}  # Get the number of arguments
    
    
    # Read remote directory from .git_remote file
    remote_dir=$(cat .git_remote)
    
    # When one argument is provided, if it is a commit hash proceed else return
    if [[ $num -ne 2 ]]; then
        echo "Usage: bash $0 git_branch commit_id <branch_name>"
        echo "Please ensure branch name does not have whitespaces or special characters and is unique"
        return 1
    fi

    commit_ref=${array[0]}
    matching_commits=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | wc -l)
        if [ "$matching_commits" -ne 1 ]; then
            echo "Error: Ambiguous commit reference. Please provide a unique commit message or hash."
            return 1
        fi
        
        # Find the full commit hash
    idcommit=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | cut -d ':' -f 1)
    

    branchname=${array[1]}
    

    mkdir $remote_dir/$idcommit/.$branchname
    cp -r . $remote_dir/$idcommit/.$branchname

    echo "created branch succesfully"

    echo "branch $branchname at commit $idcommit" >> $remote_dir/.git_branches
    
    echo "The remote repository has the following branches:"
    cat $remote_dir/.git_branches

}

git_checkout_branch() {
    if [ ! -f .git_remote ]; then
        echo "Error: Remote directory not initialized. Please run 'git_init' first."
        return 1
    fi

    if [ ! -f .git_branches ]; then
        echo "No branches present"
        return 1
    fi
    remote_dir=$(cat .git_remote)

    args="$@"
    IFS=' ' read -r -a array <<< $args
    num=${#array[@]}  # Get the number of arguments
    
    
    # Read remote directory from .git_remote file
    remote_dir=$(cat .git_remote)
    
    # When one argument is provided, if it is a commit hash proceed else return
    if [[ $num -ne 2 ]]; then
        echo "Usage: bash $0 git_checkout_branch commit_id <branch_name>"
        return 1
    fi

    commit_ref=${array[0]}
    matching_commits=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | wc -l)
        if [ "$matching_commits" -ne 1 ]; then
            echo "Error: Ambiguous commit reference. Please provide a unique commit message or hash."
            return 1
        fi
        
        # Find the full commit hash
    idcommit=$(grep -oE "^$commit_ref.*" "$remote_dir/.git_log" | cut -d ':' -f 1)
   

    branch_name=${array[1]}
     matching_names=$(grep -oE "$branch_name" "$remote_dir/.git_branches" | wc -l)
     if [ "$matching_names" -ne 1 ]; then
            echo "Branch not found. Please check branch name"
            return 1
        fi

    

    rm ./*
    cp -r "$remote_dir/$idcommit/.$branch_name"/*  .

    echo "Checked out to branch $branch_name"


}




# Function to update marks in main.csv and individual files
update_marks() {
    # Ask the user for students roll no
    read -p "Enter students roll number: " roll_number
    
    # Find the student in main.csv
    student=$(grep "$roll_number" main.csv)
    
    # Check if student exists
    if [ -z "$student" ]; then
        echo "Error: Student with roll number $roll_number not found."
        return
    fi
    
    # Extract student's name and marks from main.csv
    IFS=',' read -r -a fields <<< "$student"
    name=${fields[1]}
    exams=$(head -n 1 main.csv | cut -d ',' -f 3-)
    marks=$(echo $student | cut -d ',' -f 3- )
    
    # Display current marks
    echo "Current marks for $name ($roll_number):"
    IFS=',' read -r -a exam_names <<< "$exams"
    IFS=',' read -r -a exam_marks <<< "$marks"
    for (( i=0; i < ${#exam_names[@]}; i++ )); do
        echo "${exam_names[i]}: ${exam_marks[i]}"
    done
    
    #Prompt user to update marks
    read -p "Do you want to update marks? (y/n): " choice
    if [ "$choice" = "y" ]; then
        # Prompt user for updated marks
        echo "Enter the updated marks for each exam"
        for (( i=0; i < ${#exam_names[@]}; i++ )); do
            if [[ ${exam_names[i]} =~ "total" ]]; then
                continue
            else
                read -p "Enter marks for ${exam_names[i]}: " updated_mark
                exam_marks[i]=$updated_mark
            fi
        done

        # Update main.csv with new marks
        updated_marks=$(IFS=','; echo "${exam_marks[*]}")
        sed -i "/^$roll_number/c\\$roll_number,$name,$updated_marks" main.csv
        
        # Update individual files
        for (( i=0; i < ${#exam_names[@]}; i++ )); do
            if [[ ${exam_names[i]} =~ "total" ]]; then
                continue
            else
                if [[ ${exam_marks[$i]} -ne "a" ]]; then
                    line=$( grep "$roll_number" ${exam_names[$i]}.csv )
                    if [[ $line == "" ]]; then
                        echo "$roll_number,$name,${exam_marks[$i]}" >> "${exam_names[$i]}.csv"
                    else
                        sed -i "/^$roll_number/c\\$roll_number,$name,${exam_marks[$i]}" "${exam_names[$i]}.csv"
                    fi
                fi
            fi
        done
        
        echo "Marks updated successfully!"
        total
    else
        echo "No updates made."
    fi
}


stats(){
    if [[ ! -f main.csv ]]; then
        echo "main.csv not found.Please do combine and total first."
        return 1
    fi

    echo "The statistics of the exams are:"
    python3 statistics.py

    read -p "show the graphical represenation of student's performance in each exam? (y/n): " choice
    if [ "$choice" = "y" ]; then
        exams=$(head -n 1 main.csv | cut -d ',' -f 3-)
        IFS=',' read -r -a exam_names <<< "$exams"
        read -p "enter <exam_name> or <total>" name
        array_string="${exam_names[*]}"

        # Check if the target element exists in the array string
        if [[ " $array_string " == *" $name "* ]]; then
            python3 examgraph.py $name
        else
            echo "Invalid Exam name."
        fi
    else
        return 1
    fi

    
}


# Main script


case "$1" in
    total)
        echo "$1 command being executed"
        total ;;
    update)
        echo "$1 command being executed"
        update_marks ;;
    git_checkout)
        echo "$1 command being executed"
        git_checkout "${@:2}";;
    git_commit)
        echo "$1 command being executed"
        git_commit "${@:2}" ;;
    git_init)
        echo "$1 command being executed"
        git_init "${@:2}" ;;
    upload)
         ;;
    command_help)
            command_help ;;
    git_log)
            git_log ;;
    git_branch)
            echo "$1 command being executed"
            git_branch "${@:2}";;
    git_checkout_branch)
            echo "$1 command being executed"
            git_checkout_branch "${@:2}";;
    combine)
        echo "$1 command being executed"
        combine ;;
    stats)
        echo "$1 command being executed"
        stats ;;
    *)
        echo "Unknown command: $1"
        exit ;;
esac


