#!/bin/bash

# Функция для сравнения больше или меньше версий, которые подаются на вход.
# Возвращает true если первое число БОЛЬШЕ второго
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Функция нужна для verlt
verlte() { [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]; }

# Функция для сравнения больше или меньше версий, которые подаются на вход.
# Возвращает true если первое число МЕНЬШЕ второго
function verlt() { [ "$1" = "$2" ] && return 1 || verlte $1 $2; }

cd /usr/share/puppet/modules

# Обход по всем ссылка в текущей директории, которые имеют в конце __latest
for i in `find . -maxdepth 1 -type l -name "*__latest"`
do
    echo "i:"
    echo "$i"
    # Из названия каждого элемента удаляем __latest и получаем название модуля
    module_name=$(echo "$i" | sed s/__latest//g | cut -d "/" -f 2 | perl -pe 's/__v\d+(\_\d+)*$//g' )
    echo "module_name:"
    echo "$module_name"
    # Пусть начальная версия последней версии модуля будет 0.0.0
    last_module="0.0.0"
    # Пусть начальная версия предпоследней версии модуля будет 0.0.0
    previous_last_module="0.0.0"
    # Обход по мультиверсионным папкам модуля
    for dir in `find . -maxdepth 1 -name "$module_name"__v\*`
      do
        echo "dir:"
        echo "$dir"
        dir_name=$( echo "$dir" | sed s/__latest//g | cut -d "/" -f 2 | perl -pe 's/__v\d+(\_\d+)*$//g' )
        echo "dir_name:"
        echo "$dir_name"
        if [[ "${dir_name}" != "${module_name}" ]];
          then
          break
        fi
        # Если в названии папки модуля содержится __latest, то переходим далее
        if [[ "${dir}" =~ .*__latest ]];
          then
          continue
        fi
        # Если в названии папки модуля содержится __v и версия последнего модуля равна 0.0.0, то:
        if [[ "${dir}" =~ .*__v*. ]] && [[ ${last_module} == "0.0.0" ]];
          then
          # То версия последнего модуля будет версией текущего модуля.
          # Здесь из текущей папки получаем версию текущего модуля и назначаем эту версию последнему модулю
          last_module=$(echo "$dir" | sed s/"$module_name"__v//g | cut -d "/" -f 2 | sed -e 's/\///g' | sed -e 's/_/\./g' )
          # И версия предпоследнего модуля пусть будет равна версии последнего модуля
          previous_last_module=$last_module
          echo "last_module: $last_module"
        fi
        # Если в названии папки модуля содержится __v, то:
        if [[ "${dir}" =~ .*__v*. ]];
          then
          # Получаем версию текущего модуля
          current_module=$(echo "$dir" | sed s/"$module_name"__v//g | cut -d "/" -f 2 | sed -e 's/\///g' | sed -e 's/_/\./g')
          # Если версия последнего модуля больше версии текущего модуля, то
          if version_gt $last_module $current_module; then
            echo "1-1"
            echo "last_module:"
            echo "$last_module"
            echo "current_module:"
            echo "$current_module"
            echo "previous_last_module:"
            echo "$previous_last_module"
            # То переходим к следующему сравнению:
            # Если версия предпоследнего модуля равна последней версии модуля, то
            if [[ $previous_last_module == ${last_module} ]]; then
                # То версия предпоследнего модуля равна версии текущего модуля
                previous_last_module=$current_module
        	echo "1-1-1"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
                # И переходим на следующую итерацию цикла
                continue
            fi
            # Если версия предпоследнего модуля меньше чем версия текущего модуля, то
            if verlt $previous_last_module $current_module; then
                # То версия предпоследнего модуля будет равна версии текущего модуля
                previous_last_module=$current_module
        	echo "1-1-2"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
            fi
            # Если версия предпоследнего модуля больше версии текущего модуля, то
            if version_gt $previous_last_module $current_module; then
        	echo "1-1-3"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
                # Получаем полное название папки текущего модуля
                current_folder="$module_name"__v`echo $current_module | sed "s/\./_/g"`
                # Переходим в папку текущего модуля
                cd "$current_folder"
                # Получаем название+версия rpm пакета текущего модуля
                rpm_version=$(rpm -qf manifests)
                # Переходим на уровень выше по файловой системе
                cd ..
                echo " Удаляем пакет текущего модуля"
                yum -y remove $rpm_version
                # Проверяем если папка текущего модуля пуста, то
                if [ -d "$current_folder" ] && [ "$(ls -A "$current_folder")" ] ; then
                    echo ""$current_folder" is exist and not Empty"
                else
                    # Выводим сообщение что папка текущего модуля пуста и она будет удалена
                    echo "$current_folder is Empty. Will be delete"
                    # Удаляем папку текущего модуля
                    rm -rf $current_folder
                fi
            fi
          else
            # Если версия последнего модуля больше версии текущего модуля, то
            # версия последнего модуля будет равна версии текущего модуля
            last_module=$current_module
            echo "1-2"
            echo "last_module:"
            echo "$last_module"
            echo "current_module:"
            echo "$current_module"
          fi
        fi
      done

printf "\n\n"
echo "----------------------------------"
printf "\n\n"

    # Обход по мультиверсионным папкам модуля
    for dir in `find . -maxdepth 1 -name "$module_name"__v\*`
      do
        echo "dir:"
        echo "$dir"
        dir_name=$( echo "$dir" | sed s/__latest//g | cut -d "/" -f 2 | perl -pe 's/__v\d+(\_\d+)*$//g' )
        echo "dir_name:"
        echo "$dir_name"
        if [[ "${dir_name}" != "${module_name}" ]];
          then
          break
        fi
        # Если в названии папки модуля содержится __latest, то переходим далее
        if [[ "${dir}" =~ .*__latest ]];
          then
          continue
        fi
        # Если в названии папки модуля содержится __v и версия последнего модуля равна 0.0.0, то:
        if [[ "${dir}" =~ .*__v*. ]] && [[ ${last_module} == "0.0.0" ]];
          then
          # То версия последнего модуля будет версией текущего модуля.
          # Здесь из текущей папки получаем версию текущего модуля и назначаем эту версию последнему модулю
          last_module=$(echo "$dir" | sed s/"$module_name"__v//g | cut -d "/" -f 2 | sed -e 's/\///g' | sed -e 's/_/\./g' )
          # И версия предпоследнего модуля пусть будет равна версии последнего модуля
          previous_last_module=$last_module
          echo "last_module: $last_module"
        fi
        # Если в названии папки модуля содержится __v, то:
        if [[ "${dir}" =~ .*__v*. ]];
          then
          # Получаем версию текущего модуля
          current_module=$(echo "$dir" | sed s/"$module_name"__v//g | cut -d "/" -f 2 | sed -e 's/\///g' | sed -e 's/_/\./g')
          # Если версия последнего модуля больше версии текущего модуля, то
          if version_gt $last_module $current_module; then
            echo "2-1"
            echo "last_module:"
            echo "$last_module"
            echo "current_module:"
            echo "$current_module"
            echo "previous_last_module:"
            echo "$previous_last_module"
            # То переходим к следующему сравнению:
            # Если версия предпоследнего модуля равна последней версии модуля, то
            if [[ $previous_last_module == ${last_module} ]]; then
                # То версия предпоследнего модуля равна версии текущего модуля
                previous_last_module=$current_module
        	echo "2-1-1"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
                # И переходим на следующую итерацию цикла
                continue
            fi
            # Если версия предпоследнего модуля меньше чем версия текущего модуля, то
            if verlt $previous_last_module $current_module; then
                # То версия предпоследнего модуля будет равна версии текущего модуля
                previous_last_module=$current_module
        	echo "2-1-2"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
            fi
            # Если версия предпоследнего модуля больше версии текущего модуля, то
            if version_gt $previous_last_module $current_module; then
        	echo "2-1-3"
        	echo "last_module:"
        	echo "$last_module"
        	echo "current_module:"
        	echo "$current_module"
        	echo "previous_last_module:"
        	echo "$previous_last_module"
                # Получаем полное название папки текущего модуля
                current_folder="$module_name"__v`echo $current_module | sed "s/\./_/g"`
                # Переходим в папку текущего модуля
                cd "$current_folder"
                # Получаем название+версия rpm пакета текущего модуля
                rpm_version=$(rpm -qf manifests)
                # Переходим на уровень выше по файловой системе
                cd ..
                echo " Удаляем пакет текущего модуля"
                yum -y remove $rpm_version
                # Проверяем если папка текущего модуля пуста, то
                if [ -d "$current_folder" ] && [ "$(ls -A "$current_folder")" ] ; then
                    echo ""$current_folder" is exist and not Empty"
                else
                    # Выводим сообщение что папка текущего модуля пуста и она будет удалена
                    echo "$current_folder is Empty. Will be delete"
                    # Удаляем папку текущего модуля
                    rm -rf $current_folder
                fi
            fi
          else
            # Если версия последнего модуля больше версии текущего модуля, то
            # версия последнего модуля будет равна версии текущего модуля
            last_module=$current_module
            echo "2-2"
            echo "last_module:"
            echo "$last_module"
            echo "current_module:"
            echo "$current_module"
          fi
        fi
      done

      # Для отладки и тестирования при exit 0 делается только 1 проход
      # exit 0

printf "\n\n"
echo "**********************************"
printf "\n\n"


done
