#!/bin/bash

# date -d '20220330 18:21:56' +'%d %m %Y %H:%M'
#current_day=date +'%Y%m%d'
current_day=$(date -d '20220330 17:00:00' +'%Y%m%d')
# date: o argumento “%d %m %Y %H:%M” não tem um "+" inicial;
# date -d '20220330 09:00:00' +%s

# source https://unix.stackexchange.com/a/40897
calc(){ awk "BEGIN { print $*}"; }

echo "Que horas você começou a trabalhar?"
read start_time
#start_time="09:00"
echo "Que horas você parou para o intervalo do almoço?"
read lunch_start
#lunch_start="12:40"
echo "Que horas você voltou do intervalo do almoço?"
read lunch_end
#lunch_end="13:50"

start_time_epoch=$(date -d $current_day" "$start_time +%s)
lunch_start_epoch=$(date -d $current_day" "$lunch_start +%s)
lunch_end_epoch=$(date -d $current_day" "$lunch_end +%s)


echo $start_time_epoch
echo $lunch_start_epoch
echo $lunch_end_epoch

morning_worked_seconds=$((lunch_start_epoch-start_time_epoch))
morning_worked_hours=$(calc "$morning_worked_seconds/60/60")
# check if $morning_worked_hours has decimal values
grep "\." <<< "$morning_worked_hours" &> /dev/null
if [ $? == 0 ]; then
    morning_worked_hours_int=${morning_worked_hours%.*}
    morning_worked_hours_dec=${morning_worked_hours#*.}
    morning_worked_minutes=$((morning_worked_hours_dec*60))
    echo "Você trabalhou "$morning_worked_hours_int":"${morning_worked_minutes:0:2}" horas no turno da manhã."
else
    echo "Você trabalhou $morning_worked_hours:00 horas no turno da manhã."
fi


start_time_formatted=$(date -d $current_day" "$start_time +'%d %m %Y %H:%M')
lunch_start_formatted=$(date -d $current_day" "$lunch_start +'%d %m %Y %H:%M')
lunch_end_formatted=$(date -d $current_day" "$lunch_end +'%d %m %Y %H:%M')

# calculate time remaining to end of shift
total_hours=8
remaining_hours=$(calc "$total_hours-$morning_worked_hours")
grep "\." <<< "$remaining_hours" &> /dev/null
if [ $? == 0 ]; then
    remaining_hours_int=${remaining_hours%.*}
    remaining_hours_dec=${remaining_hours#*.}
    remaining_minutes=$((remaining_hours_dec*60))
    echo "você está a "$remaining_hours_int":"${remaining_minutes:0:2}" horas da liberdade!"
else
    echo "você está a $remaining_hours:00 horas da liberdade!"
fi
remaining_seconds=$(calc $remaining_hours*60*60)

echo "Seu turno termina às "$(date -d '+'$remaining_seconds' seconds' +'%d %m %Y %H:%M')

# TODO: levar em conta o lunch_end na hora do cálculo
