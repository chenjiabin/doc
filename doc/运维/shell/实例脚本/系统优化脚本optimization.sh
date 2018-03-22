#!/bin/bash
# 半半半球
function ChoiceInterface(){
    clear
    cat <<EOF
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                    欢迎使用服务器上线优化功能                    +
+                          请选择优化操作                          +
+                     1.关闭SELINUX                                +
+                     2.修改默认启动级别为3                        +
+                     3.关闭不必要的开机启动项                     +
+                     4.sshd优化                                   +
+                     5.修改系统时区、软硬件时钟                   +
+                     6.时间同步服务                               +
+                     7.修改系统连接数                             +
+                     8.内核参数优化                               +
+                                                                  +
+                     10.退出                                      +
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
}

#定义数字检测函数 判断是否输入回车或者非数字字符 承担解包作用 
function NumberLegalChecker(){
    num_wait2check=$1
    num_wait2check_unpacked=`echo ${num_wait2check}|sed 's/[0-9]//g'`
    #如果匹配到连续模式连接符号 -
    if [[ ${num_wait2check_unpacked} == "-" ]];then
        start_num=`echo $num_wait2check|awk -F"-" '{print $1}'` 
        end_num=`echo $num_wait2check|awk -F"-" '{print $2}'` 
        #解压连续数字序列
        unpacked_numbers=`eval echo "{$start_num..$end_num}"` 
        #打印数字 返回结果
        echo ${unpacked_numbers}
    elif [[ ! -n ${num_wait2check} || -n ${num_wait2check_unpacked} ]];then
        echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
        return 1
    else
        echo ${num_wait2check}
    fi
}
#定义纯数字检测函数
function PureNumberLegalChecker(){
    num=$1
    num_filtered=`echo ${num}|sed 's/[0-9]//g'`
    if [[ -n $num && ! -n $num_filtered ]];then
        return 0
    else
        echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
        return 1
    fi
}
#定义继续优化 返回主菜单 退出 交互函数
function QuitOrReturn2Mian(){
    while true;do
        read -p "`echo -e '\033[33m请选择返回主菜单/退出 (M/Q): \033[0m'`" input_choice
        if [[ ! -n ${input_choice} ]];then
            echo "输入错误，请重新输入！！！"
        elif [[ ${input_choice} == [Mm] ]]; then
            return
        elif [[ ${input_choice} == [Qq] ]]; then
            echo -e "\033[31;7m再见！！！ \033[0m"
            exit
        fi
    done
}
#定义禁用selinux函数
function DisableSELINUX(){
    selinux_config_file=/etc/selinux/config
    echo "验证SELINUX配置文件。。。"
    if [[ -f ${selinux_config_file} ]] ; then
        echo "配置文件验证成功！"
    else
        echo "配置文件验证失败 "
        return 1
    fi
    #获取目前selinux状态
    se_status1=`awk -F"=" '/^SELINUX=/ {print $2}' /etc/selinux/config`
    se_status2=`getenforce`
    if [[ $se_status1 != 'disabled' ]]; then
        sed -i 's/\(SELINUX=\)enforcing/\1disabled/g' $selinux_config_file
        echo "修改了SELINUX配置文件，已置为Disabled，需要重启服务器"
    fi
    if [[ $se_status2 == 'Enforcing' ]]; then
        setenforce 0 && echo "已设置临时的SELINUX状态为permissive"
    fi
    echo "SELINUX已经成功修改完成"
    cmd=getenforce
    echo "执行命令: $cmd"
    echo "命令结果：`eval $cmd`"
    cmd="grep -e '^SELINUX=' ${selinux_config_file}"
    echo "执行命令: $cmd"
    echo "命令结果：`eval $cmd`"
    QuitOrReturn2Mian
}
#修改默认启动级别函数
function ModifyDefaultRunlevel(){
    inittab_config_file=/etc/inittab
    echo "验证inittab配置文件。。。"
    if [[ -f ${inittab_config_file} ]] ; then
        echo "配置文件验证成功！"
    else
        echo "配置文件验证失败 "
        return 1
    fi
     sed -i 's/\(id:\)[0-9]\(:initdefault:\)/\13\2/g' ${inittab_config_file} 
    echo "默认启动级别已经成功修改完成"
    cmd="grep -e '^id:[0-9]:initdefault:' ${inittab_config_file}"
    echo "执行命令:  $cmd"
    echo "命令结果：`eval $cmd`"
    QuitOrReturn2Mian
}
function AutostartOptimization(){
    #获得目前开机3级别启动项清单
    current_autostart_inventory=(`chkconfig --list | grep 3:on | awk '{print $1}'`)
    #初始化用户输入选择序列号的存放的数组
    user_choice_inventory=()
    #定义打印开机启动项函数
    function InactivePrintAutostartItem(){
    clear
    for order_number in `seq 0 $(( ${#current_autostart_inventory[@]} - 1 ))`; do
        choice_boolen=false
        for choice_number in ${user_choice_inventory[@]}; do
            if [[ ${order_number} -eq ${choice_number} ]]; then
                choice_boolen=true
            fi
        done
        if ${choice_boolen};then 
            printf  "\033[41;36m%-3s-->%-17s\033[0m"  ${order_number} ${current_autostart_inventory[${order_number}]}
        else
            printf "%-3s-->%-17s"  ${order_number} ${current_autostart_inventory[${order_number}]}
        fi
        if [[ $(((${order_number}+1)%4)) -eq 0 ]];then
            printf "\n"
        fi
    done
    echo
    echo -e "已选择开机启动项 \033[41;36m      \033[0m" 
    #打印非法选项
    if [[ ${#illegal_user_choice_inventory[@]} -gt 0 ]];then
        echo -e "\033[35;1m未操作开机启动项   ${illegal_user_choice_inventory[*]} \033[0m"
    fi
    }
    #定义禁止启动项函数
    function disable_startup(){
        #首先禁止所有
        for item in ${current_autostart_inventory[@]};do
            #echo "执行命令: chkconfig --level 3 $item off"
            chkconfig --level 3 $item off
        done
        #开启需要的开机启动项
        for  allow_autostart_number in ${user_choice_inventory[@]};do
            echo "执行命令： chkconfig --level 3 ${current_autostart_inventory[${allow_autostart_number}]} on"
            chkconfig --level 3 ${current_autostart_inventory[${allow_autostart_number}]} on
        done
        echo "查看现在的启动项列表"
        cmd="chkconfig --list | grep 3:on"
        echo "执行命令: $cmd"
        echo -e "命令结果: \n`eval $cmd`"
    }
    #主循环体
    while true; do
        InactivePrintAutostartItem
        #定义验证输入合法性循环体
        while true;do
            echo "请选择需要开机自动启动的项(未选择的将被禁止启动,请输入每个服务所代表的数字)"
            read -p "支持多选，支持连续模式，如3-11，请输入: " allow_autostart_variables
            #检验输入是否为空
            while [[ ! -n ${allow_autostart_variables} ]];do
                echo "请选择需要开机自动启动的项(未选择的将被禁止启动,请输入每个服务所代表的数字)"
                read -p "支持多选，请输入: " allow_autostart_variables
            done

            #先取出输入的数组 判断是否输入回车或者非数字字符 修改为匹配大多数字符 支持-连接符选择连续的数字
            #allow_autostart_unpacked_inventory=(`echo ${allow_autostart_variables} | sed  's/[[:punct:]]/\ /g'`)
            allow_autostart_inventory=(`echo ${allow_autostart_variables} |sed 's/[][!#$%&*+,./:;<=>?@\^_{|}~]/\ /g'`)
            #初始化解压之后的数组
            allow_autostart_unpacked_inventory=()
            #遍历输入的选择数组
            for single_allow_autostart_item in ${allow_autostart_inventory[*]}; do
                #检测数字是否合法 非法报错
                result_after_num_checker=`NumberLegalChecker ${single_allow_autostart_item}` 
                if [[ -n $result_after_num_checker ]];then
                    #如果结果不为空 追加到解压之后的数组
                    allow_autostart_unpacked_inventory=(`echo ${allow_autostart_unpacked_inventory[*]}" "$result_after_num_checker`)
                else
                    continue
                fi
            done
            #定义一个开机启动项的序列号数组
            autostart_number_inventory=(`eval echo {0..$(( ${#current_autostart_inventory[@]} - 1 ))}`)
            #求数组并集 差集
            legal_autostart_num_inventory=(`echo ${allow_autostart_unpacked_inventory[*]} ${autostart_number_inventory[*]} | sed 's/\ /\n/g' | sort |uniq -d |tr "\n" "\ "`)
            illegal_autostart_num_inventory=(`echo ${allow_autostart_unpacked_inventory[*]} ${autostart_number_inventory[*]} ${autostart_number_inventory[*]} | sed 's/\ /\n/g' | sort |uniq -u|tr "\n" "\ "`)
            #把每次的结果叠加
            user_choice_inventory=(`echo ${legal_autostart_num_inventory[*]}" "${user_choice_inventory[*]}`)
            illegal_user_choice_inventory=(${illegal_autostart_num_inventory[@]})
            InactivePrintAutostartItem
            break
        done

        #定义是否终止 或继续选择循环体
        while true;do
            read -p "是否继续选择启用的开机启动项 是/否(应用)/删除（Y/N/D）: " con_or_apply
            if [[ ! -n ${con_or_apply} ]];then
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            elif [[ ${con_or_apply} == [Yy] ]];then
                break
            elif [[ ${con_or_apply} == [Nn] ]];then
                read -p "是否应用 是/否（Y/N）: " yes_no_apply
                #是否应用所选择的启动服务项
                while true;do
                    if [[ ! -n ${yes_no_apply} ]];then
                    echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
                    elif [[ ${yes_no_apply} == [Yy] ]];then
                        echo "开始执行应用所选择的启动项"
                        disable_startup
                        break
                    elif [[ ${yes_no_apply} == [Nn] ]];then
                        break
                    else
                        echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
                    fi
                    read -p "是否应用 是/否（Y/N）: " yes_no_apply
                done
                QuitOrReturn2Mian
                return
            elif [[ ${con_or_apply} == [Dd] ]];then
                read -p "清输入要移除的启动项序列号： " require2remove_num_variables
                #判断输入是否非空
                while [[ ! -n ${require2remove_num_variables} ]];do
                    read -p "清输入要移除的启动项序列号(支持多选 支持连接符-): " require2remove_num_variables
                done
                #读取输入的多选到数组
                removing_num_inventory=(`echo ${require2remove_num_variables} | sed 's/[][!#$%&*+,./:;<=>?@\^_{|}~]/\ /g'`)
                #初始化解包后的清单数组
                removing_num_unpacked_inventory=()
                for single_removing_numt_item in ${removing_num_inventory[*]}; do
                #检测数字是否合法 非法报错
                    result_after_num_checker=`NumberLegalChecker ${single_removing_numt_item}` 
                    if [[ -n $result_after_num_checker ]];then
                        #如果结果不为空 追加到解压之后的数组
                        removing_num_unpacked_inventory=(`echo ${removing_num_unpacked_inventory[*]}" "$result_after_num_checker`)
                    else
                        continue
                    fi
                done
                #求并集差集 需要删除的数组和已经选择的数组
                legal_removing_inventory=(`echo ${removing_num_unpacked_inventory[*]} ${user_choice_inventory[*]} | sed 's/\ /\n/g' | sort |uniq -d |tr "\n" "\ "`)
                illegal_removing_inventory=(`echo ${removing_num_unpacked_inventory[*]} ${user_choice_inventory[*]} ${user_choice_inventory[*]} | sed 's/\ /\n/g' | sort |uniq -u|tr "\n" "\ "`)
                #在一选择数组中移除需要移除的合法序列数
                user_choice_inventory=(`echo  ${legal_removing_inventory[*]} ${user_choice_inventory[*]} | sed 's/\ /\n/g' |sort|uniq -u | tr "\n" "\ "`)
                illegal_user_choice_inventory=(${illegal_removing_inventory[@]})
                InactivePrintAutostartItem
                echo "已成功移除 ${legal_removing_inventory[*]}"
                
            else
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            fi
        done
    done
}

function SshOptimization(){
    ssh_config_file=/etc/ssh/sshd_config
    echo "验证sshd配置文件。。。"
    if [[ -f ${ssh_config_file} ]] ; then
        echo "配置文件验证成功！"
    else
        echo "配置文件验证失败 "
        return 1
    fi
    #定义禁用DNS反查询的函数
    function DisableUseDNS(){ 
    #if [[ `grep -c  -e "#\ *UseDNS\ *yes" ${ssh_config_file}` -eq 1 && `grep -c  -e "[^#]UseDNS" ${ssh_config_file}` -eq 0 ]];then
         sed -i 's/#*\(UseDNS\ \)yes/\1no/g' ${ssh_config_file}
     #fi
         sed -i 's/\(GSSAPIAuthentication\ \)yes/\1no/g' ${ssh_config_file}
         cmd="grep UseDNS ${ssh_config_file}"
         echo "执行命令: $cmd"
         echo "执行结果: `eval $cmd`"
         cmd="grep GSSAPIAuthentication ${ssh_config_file}"
         echo "执行命令: $cmd"
         echo "执行结果: `eval $cmd`"
    }
    #定义更改ssh端口号函数
    function ChangeSshPort(){
        port=$1
        echo "正在更改SSH默认端口号。。。"
        sed -i "s/#*\(Port\ *\)[0-9]*$/\1$port/g" ${ssh_config_file}
        cmd="grep -E ^Port ${ssh_config_file}"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
    }
    #定义更改是否允许root登录函数
    function PermitRootLogin(){
        permit_root_login=$1
        echo "正在修改是否允许root ssh登录。。。"
        sed -i "s/#*\(PermitRootLogin\ *\).*$/\1$permit_root_login/g" ${ssh_config_file}
        cmd="grep -E ^#*PermitRootLogin ${ssh_config_file}"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
    }
    #循环判断是否启用SSH加速
    function InteractiveDisableUseDNS(){
        read -p "是否启用SSH加速 是/否  (Y/N): " speedup_yes_no
        while true;do
            if [[ ! -n ${speedup_yes_no} ]];then
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            elif [[ ${speedup_yes_no} == [Yy] ]];then
                echo "启用SSH加速功能"
                DisableUseDNS
                return
            elif [[ ${speedup_yes_no} == [Nn] ]];then
                return
            else
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            fi
            read -p "是否启用SSH加速 是/否  (Y/N): " speedup_yes_no
        done
    }
    
    #循环判断是否修改SSH端口
    function InteracticeChangeSshPort(){
        read -p "是否修改SSH端口 是/否  (Y/N): " sshport_yes_no
        #循环判断输入合法性
        while true;do
            #如果输入空的字符串
            if [[ ! -n ${sshport_yes_no} ]];then
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            elif [[ ${sshport_yes_no} == [Yy] ]];then
                while true;do
                    read -p "请输入要修改的端口号：" port
                    #判断输入的数字是否合法
                    while ! PureNumberLegalChecker ${port};do
                        read -p "请输入要修改的端口号：" port
                    done
                    #判断输入是否在合法端口范围内
                    if [[ $port -gt 0 && $port -lt 65535 ]];then
                        known_service_filter=`grep -E "[[:space:]]$port/[tcp|udp]" /etc/services`
                        if [[ -n ${known_service_filter} ]];then
                            echo -e "这个端口已经有服务在使用，\n ${known_service_filter}\n"
                            read -p "是否继续使用这个端口? (Y/N)" port_confirm
                            #判断是否继续使用这个端口
                            while true;do
                                if [[ ! -n ${port_confirm} ]];then
                                    echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
                                elif [[ ${port_confirm} == [Yy] ]];then
                                    ChangeSshPort $port
                                    return
                                elif [[ ${port_confirm} == [Nn] ]];then
                                    break
                                else
                                    cho -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
                                    continue
                                fi
                            done
                        else
                            ChangeSshPort $port
                            return
                        fi
                    else
                        echo -e "\033[34;5m输入错误，端口范围需在0~65535 请重新输入！！！\033[0m"
                    fi
                done
            elif [[ ${sshport_yes_no} == [Nn] ]];then
                return
            else
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            fi
        read -p "是否修改SSH端口 是/否  (Y/N): " sshport_yes_no
        done
    }
    #循环判断是否允许Root ssh登录
    function InteractivePermitRootLogin(){
        read -p "是否允许Root通过SSH登录 是/否  (Y/N): " root_login_yes_no
        while true;do
            if [[ ! -n ${root_login_yes_no} ]];then
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            elif [[ ${root_login_yes_no} == [Yy] ]];then
                echo "允许root登录"
                PermitRootLogin "yes"
                return
            elif [[ ${root_login_yes_no} == [Nn] ]];then
                echo "禁止root登录"
                PermitRootLogin "no"
                return
            else
                echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            fi
            read -p "是否允许Root通过SSH登录 是/否  (Y/N): " root_login_yes_no
        done
    }
    #执行定义的函数
    InteractiveDisableUseDNS
    InteracticeChangeSshPort
    InteractivePermitRootLogin
    /etc/init.d/sshd restart > /dev/null
    QuitOrReturn2Mian
}

function ModifyTimeRelation(){
    timezone_config_path=/usr/share/zoneinfo/
    
    function ModifyTimezone(){
        clear
        cat <<EOF
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                            请选择时区                            +
+                            1.UTC                                 +
+                            2.Asia/Shanghai                       +
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
        read -p "请输入要选择的时区: " select_timezone_num
        while true;do
            [[ ${select_timezone_num} == [12] ]] && break
            echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            read -p "请输入要选择的时区: " select_timezone_num
        done
        [[ ${select_timezone_num} == 1 ]] && ln -sf ${timezone_config_path}/UTC /etc/localtime && echo "已将时区成功更改为 UTC"
        [[ ${select_timezone_num} == 2 ]] && ln -sf ${timezone_config_path}/Asia/Shanghai /etc/localtime && echo "已将时区成功更改为 Asia/Shanghai"
    }
    function hwclockAsystemclock(){
        clear
        cat <<EOF
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                            请选择操作                            +
+                    1.系统时间同步到硬件时钟                      +
+                    2.硬件时钟同步到系统时钟                      +
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
EOF
        read -p "请输入要选择的操作: " select_operation_num
        while true;do
            [[ ${select_operation_num} == [12] ]] && break
            echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            read -p "请输入要选择的时区: " select_operation_num
        done
        [[ ${select_operation_num} == 1 ]] && hwclock -s && echo "已将系统时间同步到硬件时钟"
        [[ ${select_operation_num} == 2 ]] && hwclock -w && echo "已将硬件时钟同步到系统时钟"
    }
    #判断是否需要选择时区函数
    function timezone_set(){
        read -p "是否需要修改时区？ 是/否 (Y/N) " timezone_select
        while true;do
            [[ ${timezone_select} == [YyNn] ]] && break
            echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
            read -p "是否需要修改时区？ 是/否 (Y/N) " timezone_select
        done
        [[ ${timezone_select} == [Yy] ]] && ModifyTimezone
        [[ ${timezone_select} == [Nn] ]] && echo "取消修改时区操作" 
        cmd="date"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
        cmd="date -R"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
    }
    #判断是否需要hwclock
    function hwclock_set(){
        read -p "是否需要同步软硬件时钟？ 是/否 (Y/N) " hwAs_select
        while true;do
            [[ ${hwAs_select} == [YyNn] ]] && break
            echo -e "\033[34;5m输入错误，请重新输入！！！\033[0m"
        read -p "是否需要同步软硬件时钟？ 是/否 (Y/N) " hwAs_select
        done
        [[ ${hwAs_select} == [Yy] ]] && hwclockAsystemclock
        [[ ${hwAs_select} == [Nn] ]] && echo "取消软硬件时钟同步操作" 
        cmd="date"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
        cmd="hwclock"
        echo "执行命令: $cmd"
        echo "执行结果: `eval $cmd`"
    }

    timezone_set
    hwclock_set
    QuitOrReturn2Mian
}
function TimeSynchronization(){
    echo "此功能待开发"
    QuitOrReturn2Mian
}
function ModifySystemResourceLimit(){
    echo "此功能待开发"
    QuitOrReturn2Mian
}
function KernelParameterOptimization(){
    echo "此功能待开发"
    QuitOrReturn2Mian
}

#判断是否是root用户运行
if [[ `id -u` -ne 0 ]];then
    echo "必须以root身份运行此脚本！"
    exit 1
fi

while ChoiceInterface;do
    read -p "请输入你的选择:" choice
    #判断是否输入回车或者非数字字符
    NumberLegalChecker ${choice} || continue
    case $choice in 
        1) 
            DisableSELINUX
            continue
            ;;
        2) 
            ModifyDefaultRunlevel
            continue
            ;;
        3)
            AutostartOptimization
            continue
            ;;
        4)
            SshOptimization
            continue
            ;;
        5)
            ModifyTimeRelation
            continue
            ;;
        6)
            TimeSynchronization
            continue
            ;;
        7)
            ModifySystemResourceLimit
            continue
            ;;
        8)
            KernelParameterOptimization
            continue
            ;;
        10)
            exit 0
            ;;
        *)
            echo "选择错误，请重新输入！"
            #continue
            ;;
    esac
done

