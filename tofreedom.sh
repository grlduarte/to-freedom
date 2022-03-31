#!/bin/bash

# current_day=$(date +'%Y%m%d')
# debian version (GNU)
# current_day=$(date -d '20220330 17:00:00' +'%Y%m%d')
# osx version
current_day=$(date -j -f "%Y%m%d %T" "20220330 17:00:00" +'%Y%m%d')

has_gnu_date() {
  date -d '20220330 17:00:00' +'%Y%m%d' >/dev/null 2>&1
  return $?
}

# $1 is date in format YYYYMMDD HH:MM:SS
# $2 is output format
date_from_string() {
  if has_gnu_date; then
    seconds_from_epoch=$(date -d "$1" "$2")
  else
    seconds_from_epoch=$(date -j -f "%Y%m%d %H:%M" "$1" "$2")
  fi
  echo $seconds_from_epoch
}

# source https://unix.stackexchange.com/a/40897
calc(){ awk "BEGIN { print $*}"; }

echo "Que horas você começou a trabalhar?"
#read start_time
start_time="08:00"
start_time_formatted=$(date_from_string "$current_day $start_time" +'%H:%M %d/%m/%Y')
echo " - Inicio do turno às "$start_time_formatted
echo "Que horas você parou para o intervalo do almoço?"
#read lunch_start
lunch_start="12:00"
lunch_start_formatted=$(date_from_string "$current_day $lunch_start" +'%H:%M %d/%m/%Y')
echo " - Saída para o almoço às "$lunch_start_formatted
echo "Que horas você voltou do intervalo do almoço?"
#read lunch_end
lunch_end="13:00"
lunch_end_formatted=$(date_from_string "$current_day $lunch_end" +'%H:%M %d/%m/%Y')
echo " - Retorno do almoço às "$lunch_end_formatted

start_time_epoch=$(date_from_string "$current_day $start_time" "+%s")
lunch_start_epoch=$(date_from_string "$current_day $lunch_start" "+%s")
lunch_end_epoch=$(date_from_string "$current_day $lunch_end" "+%s")

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

# calculate time remaining to end of second shift
total_hours=8
remaining_second_shift_hours=$(calc "$total_hours-$morning_worked_hours")


grep "\." <<< "$remaining_afternoon_hours" &> /dev/null
if [ $? == 0 ]; then
    remaining_hours_int=${remaining_hours%.*}
    remaining_hours_dec=${remaining_hours#*.}
    remaining_minutes=$((remaining_hours_dec*60))
    echo "você está a "$remaining_hours_int":"${remaining_minutes:0:2}" horas da liberdade!"
else
    echo "você está a $remaining_hours:00 horas da liberdade!"
fi
remaining_seconds=$(calc $remaining_hours*60*60)

if has_gnu_date; then
  echo "Seu turno termina às "$(date -d '+'$remaining_seconds' seconds' +'%d %m %Y %H:%M')
else
  echo "Seu turno termino às "$(date -v+"$remaining_seconds"S -j +'%H:%M %d/%m/%Y')
fi

# TODO: levar em conta o lunch_end na hora do cálculo