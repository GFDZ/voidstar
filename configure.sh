#!/bin/bash


#------------------------------------------------------------------------------
#                               QUALITY
#------------------------------------------------------------------------------
set -o errexit
set -o pipefail
# set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file_path="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__file="$(basename $__file_path)"
__build_dir="build"

#------------------------------------------------------------------------------
#                               SCRIPT LOGIC
#------------------------------------------------------------------------------

# create build dir
mkdir -p "$__dir/$__build_dir"

# parsing option
OPTIND=1
compilers=(clang++ g++)
build_types=(DEBUG RELEASE)
sanitizers=(address thread memory leak undefined)

# default values
compiler_answer=1
for (( i=$(($compiler_answer - 1)); i<=$((${#compilers[@]} - 1)); i++ )); do
    which "${compilers[$i]}" >/dev/null && compiler_answer=$(($i + 1)) && break
done
prefix_answer="/usr/local"
build_type_answer=1
sanitizer_answer=1

#------------------------------------------------------------------------------
#                               USAGE
#------------------------------------------------------------------------------
usage ()
{
    echo "./$__file [-h] [-c] [-p] [-b] [-s]"
    echo
    echo "  -h      Display help"
    echo "  -c      Change compiler (${compilers[$(($compiler_answer - 1))]})"
    echo "  -p      Change install prefix ($prefix_answer)"
    echo "  -b      Change build type (${build_types[$(($build_type_answer - 1))]})"
    echo "  -s      Enable compiler sanitizers flag ()"
    echo
    exit 1
}

# getopt loop
while getopts ":cpbsh" opt ; do
    case $opt in
        "c")
            dialog --backtitle "Compiler configuration" \
                --radiolist "Choose your compiler" 0 0 10 \
                1 "${compilers[0]}" on \
                2 "${compilers[1]}" off \
                2>/tmp/$$_dialog.ans

            compiler_answer=$(cat /tmp/$$_dialog.ans && rm -f /tmp/$$_dialog.ans)
            if [ "$compiler_answer" -eq 0 ]; then
                echo "Project Configuration Cancelled."
                exit 1
            else
                # better to remove the build dir and recreate it
                # when changing the compiler
                rm -rf "$__dir/$__build_dir"
                mkdir -p "$__dir/$__build_dir"
            fi
            ;;
        "p")
            dialog --backtitle "Installation prefix configuration" \
                --inputbox "Set the install prefix" 0 0 \
                "/usr/local" \
                2>/tmp/$$_dialog.ans

            prefix_answer=$(cat /tmp/$$_dialog.ans && rm -f /tmp/$$_dialog.ans)
            if [ "$prefix_answer" -eq 0 ]; then
                echo "Project Configuration Cancelled."
                exit 1
            fi
            ;;
        "b")
            dialog --backtitle "Build type configuration" \
                --radiolist "Set the build type" 0 0 10 \
                1 "${build_types[0]}" on \
                2 "${build_types[1]}" off \
                2>/tmp/$$_dialog.ans

            build_type_answer=$(cat /tmp/$$_dialog.ans && rm -f /tmp/$$_dialog.ans)
            if [ "$build_type_answer" -eq 0 ]; then
                echo "Project Configuration Cancelled."
                exit 1
            fi
            ;;
        "s")
            dialog --backtitle "Compiler sanitizers configuration" \
                --checklist "Choose the sanitizer you want to use:" 0 0 10 \
                1 "${sanitizers[0]}" on \
                2 "${sanitizers[1]}" off \
                3 "${sanitizers[2]}" off \
                4 "${sanitizers[3]}" off \
                5 "${sanitizers[4]}" off \
                2>/tmp/$$_dialog.ans

            sanitizer_answer=$(cat /tmp/$$_dialog.ans && rm -f /tmp/$$_dialog.ans)
            selected_sanitizers=()
            if [ "$sanitizer_answer" = "" ]; then
                echo "Project Configuration Cancelled."
                exit 1
            else
                for i in $sanitizer_answer; do
                    idx=$(( $i - 1 ))
                    # push to array
                    selected_sanitizers+="${sanitizers[$idx]} "
                done
                # make CMake list struct
                selected_sanitizers=$( echo "${selected_sanitizers[@]% }" | sed -e 's/ /;/g')
            fi
            ;;
        "h")
            usage
            ;;
    esac
done

# CMAKE
#################
cd "$__dir/$__build_dir" && \
    cmake .. \
    -DCMAKE_CXX_COMPILER="$(which "${compilers[$(($compiler_answer - 1))]}")" \
    -DCMAKE_BUILD_TYPE="$(echo ${build_types[$(($build_type_answer - 1))]} | tr '[a-z]' '[A-Z]')" \
    -DCMAKE_INSTALL_PREFIX="$prefix_answer" \
    -DCOMPILER_SANITIZER="$selected_sanitizers"
