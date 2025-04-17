#!/bin/bash

id=$1

cd ../temp/

for file in *.para *.txt; do

    run=$(echo $file | grep -o '[0-9]' | tail -n 1)

    if echo "$file" | grep -q "vis"; then
        exp="vis"
        newfile="kaneff${id}_${run}_vis.para"
    elif echo "$file" | grep -q "aud"; then
        exp="aud"
        newfile="kaneff${id}_${run}_aud.para"
    elif echo "$file" | grep -q "langloc"; then
        exp="langloc"
        newfile="kaneff${id}_${run}_langloc.para"
    elif echo "$file" | grep -q "speechloc"; then
        exp="speechloc"
        newfile="kaneff${id}_${run}_speechloc.para"

    elif echo "$file" | grep -q "foss"; then
        exp="foss"
        newfile="kaneff${id}_${run}_foss.para"

    elif echo "$file" | grep -q "eploc"; then
        exp="eploc"
        newfile="kaneff${id}_${run}_eploc.para"
    else
        exp="spwm"
        newfile="kaneff${id}_${run}_spwm.para"
    fi

    mkdir -p "../paras_$exp/kaneff$id/"
    mv "$file" "../paras_$exp/kaneff$id/$newfile"

done
