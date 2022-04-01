#!/bin/bash

Help()
{
   # Display Help
   echo "Este script vai te ajudar a calcular o horário exato pra cair fora."
   echo
   echo "sintaxe: tofreedom.sh [-c|h|e]"
   echo "opções:"
   echo "c     Calcula o horário de saída."
   echo "h     Imprime este diálogo de ajuda."
   echo "e     Muda as variáveis de configuração."
   echo
}

# sets config file name
config_file=.tofreedom.config

# reads values from config file
# $1 is variable name in .env
read_var_config()
{
    sed -nr 's/^'$1'=(.*)$/\1/p' $config_file
}

# removes trailing and leading whitespace from $1
trim() {
  sed -e 's/^[[:space:]]*//' <<< $1
}

# checks whether config file exists and is readable
# if not, attempts to create
if [ ! -r $config_file ]; then
    touch $config_file && chmod u+x $config_file
fi

# checks whether the system is running gnu or bsd utils
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

# $1 is date in seconds elapsed since January 1, 1970 (midnight UTC/GMT), not counting leap seconds
# $2 is the desired output format ex. "%Y%m%d %H:%M"
epoch_to_date() {
  if has_gnu_date; then
    output_date=$(date -d @"$1" "$2")
  else
    output_date=$(date -j -f "%s" "$1" "$2")
  fi
  echo $output_date
}

# uses awk to perform floating point arithmetics
# source https://unix.stackexchange.com/a/40897
calc(){ awk "BEGIN { print $*}"; }

# verifies whether user input is in HH:MM format
# $1 is user input
check_input_format() {
  if ! [[ "$1" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
    echo "Digite os horários no formato HH:MM!"
    exit 1
  fi
}

# edit defined config vars
edit() {
  echo "Este comando irá expor suas variáveis de configuração. Prosseguir? [s/n]"
  read should_proceed
  [[ $should_proceed != 's' ]] && echo "Finalizando programa..." && exit 0

  counter=1
  while read -r line; do
    printf '%s. %s\n' "$counter" "$line"
    let counter=counter+1
  done < "$config_file"
  let counter=counter-1

  var_options=$(seq -s ', ' 1 1 $counter)

  # remove trailing ','
  var_options=${var_options%,*}
  echo "Digite o número da variável que deseja editar: [ $var_options ]"
  read edit_var_number
  if [ $edit_var_number -lt 1 ] || [ $edit_var_number -gt $counter ]; then
    echo "Você precisa escolher um número no intervalo [ $var_options ]"
    exit 1
  fi
  # prints line by number ($edit_var_number), then prints value before equal sign 
  chosen_var=$(sed -n $edit_var_number'p' $config_file | sed -nr 's/^(.*)=.*$/\1/p')
  echo "Digite o novo valor de <$chosen_var>: "
  read new_var_value
  trimmed_new_var_value=$(trim $new_var_value)
  [[ -z $trimmed_new_var_value ]] && echo "O novo valor não pode ser vazio!" && exit 1
  # substitutes new value inline, creates a backup file
  sed -i.bu "s/^$chosen_var=.*/$chosen_var=$trimmed_new_var_value/" $config_file 
  # deletes backup file only if sed exits successfully
  [[ $? == 0 ]] && rm $config_file.bu || (echo "Erro ao substituir valor no arquivo de configuração!" && exit 1)
  echo "-------------"
  echo "Novos valores"
  echo "-------------"
  cat $config_file
  exit
}

main() {
  current_day=$(date +'%Y%m%d')

  total_hours=$(read_var_config TOTAL_HOURS)
  if [ -z $total_hours ]; then
      echo "Quantas horas você trabalha por dia?"
      read total_hours
      check_input_format $total_hours
      echo TOTAL_HOURS=$total_hours >> $config_file
  fi

  echo "Que horas você começou a trabalhar?"
  read start_time
  check_input_format $start_time
  start_time_formatted=$(date_from_string "$current_day $start_time" +'%H:%M %d/%m/%Y')
  echo " - Inicio do turno às "$start_time_formatted

  echo "Que horas você parou para o intervalo do almoço?"
  read lunch_start
  check_input_format $lunch_start
  lunch_start_formatted=$(date_from_string "$current_day $lunch_start" +'%H:%M %d/%m/%Y')
  echo " - Saída para o almoço às "$lunch_start_formatted

  echo "Que horas você voltou do intervalo do almoço?"
  read lunch_end
  check_input_format $lunch_end
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

  # convert total hours to decimal value
  total_hours_dec_fmt=$(calc ${total_hours%:*} + $(calc ${total_hours#*:} / 60))

  # calculate time remaining to end of second shift
  remaining_second_shift_hours=$(calc "$total_hours_dec_fmt-$morning_worked_hours")

  # check if remaining hours in the second shift has decimal values and formats it
  grep "\." <<< "$remaining_second_shift_hours" &> /dev/null
  if [ $? == 0 ]; then
      remaining_hours_int=${remaining_second_shift_hours%.*}
      remaining_hours_dec=${remaining_second_shift_hours#*.}
      remaining_minutes=$((remaining_hours_dec*60))
      echo "Você precisa trabalhar "$remaining_hours_int":"${remaining_minutes:0:2}" horas no turno da tarde!"
  else
      echo "você precisa trabalhar $remaining_second_shift_hours:00 horas no turno da tarde!"
  fi
  remaining_seconds=$(calc $remaining_second_shift_hours*60*60)

  logoff_time_epoch=$((lunch_end_epoch+remaining_seconds))
  logoff_date=$(epoch_to_date $logoff_time_epoch +'%H:%M %d/%m/%Y')
  echo "Seu turno termina às $logoff_date"
}

# handle script options
while getopts ":hce" option; do
   case $option in
      e) # edit config vars
        edit
        exit;;
      c) # calculate time to log off
        main
        exit;;
      h) # display Help
         Help
         exit;;
      \?) # invalid option
        echo "Opção inválida!"
        Help
        exit;;
   esac
done

# shows help when script is called without params
if [ -z $1 ]; then
    Help
    exit
fi
