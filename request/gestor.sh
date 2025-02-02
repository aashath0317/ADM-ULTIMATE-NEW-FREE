#!/bin/bash
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
barra="\033[0m\e[34m======================================================\033[1;37m"
SCPdir="/etc/newadm" && [[ ! -d ${SCPdir} ]] && exit 1
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit
SCPidioma="${SCPdir}/idioma" && [[ ! -e ${SCPidioma} ]] && touch ${SCPidioma}

fun_ip () {
if [[ -e /etc/MEUIPADM ]]; then
IP="$(cat /etc/MEUIPADM)"
else
MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MEU_IP" != "$MEU_IP2" ]] && IP="$MEU_IP2" || IP="$MEU_IP"
echo "$MEU_IP2" > /etc/MEUIPADM
fi
}

fun_bar () {
comando="$1"
 _=$(
$comando > /dev/null 2>&1
) & > /dev/null
pid=$!
while [[ -d /proc/$pid ]]; do
echo -ne " \033[1;33m["
   for((i=0; i<10; i++)); do
   echo -ne "\033[1;31m##"
   sleep 0.2
   done
echo -ne "\033[1;33m]"
sleep 1s
echo
tput cuu1
tput dl1
done
echo -e " \033[1;33m[\033[1;31m####################\033[1;33m] - \033[1;32m100%\033[0m"
sleep 1s
}

update_pak () {
echo -ne " \033[1;31m[ ! ] apt-get update"
apt-get update -y > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
echo -ne " \033[1;31m[ ! ] apt-get upgrade"
apt-get upgrade -y > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
return
}

reiniciar_ser () {
# SERVICE SSH
echo -ne " \033[1;31m[ ! ] Services ssh restart"
service ssh restart > /dev/null 2>&1
[[ -e /etc/init.d/ssh ]] && /etc/init.d/ssh restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE DROPBEAR
echo -ne " \033[1;31m[ ! ] Services dropbear restart"
service dropbear restart > /dev/null 2>&1
[[ -e /etc/init.d/dropbear ]] && /etc/init.d/dropbear restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE SQUID
echo -ne " \033[1;31m[ ! ] Services squid restart"
service squid restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE SQUID3
echo -ne " \033[1;31m[ ! ] Services squid3 restart"
service squid3 restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE OPENVPN
echo -ne " \033[1;31m[ ! ] Services openvpn restart"
service openvpn restart > /dev/null 2>&1
[[ -e /etc/init.d/openvpn ]] && /etc/init.d/openvpn restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE STUNNEL4
echo -ne " \033[1;31m[ ! ] Services stunnel4 restart"
service stunnel4 restart > /dev/null 2>&1
[[ -e /etc/init.d/stunnel4 ]] && /etc/init.d/stunnel4 restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE APACHE2
echo -ne " \033[1;31m[ ! ] Services apache2 restart"
service apache2 restart > /dev/null 2>&1
[[ -e /etc/init.d/apache2 ]] && /etc/init.d/apache2 restart > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
# SERVICE FAIL2BAN
echo -ne " \033[1;31m[ ! ] Services fail2ban restart"
( 
[[ -e /etc/init.d/ssh ]] && /etc/init.d/ssh restart
fail2ban-client -x stop && fail2ban-client -x start
) > /dev/null 2>&1 && echo -e "\033[1;32m [OK]" || echo -e "\033[1;31m [FAIL]"
return
}

reiniciar_vps () {
echo -ne " \033[1;31m[ ! ] Reboot"
sleep 3s
echo -e "\033[1;32m [OK]"
# shutdown -r now
(
reboot
) > /dev/null 2>&1
return
}

host_name () {
unset name
while [[ ${name} = "" ]]; do
echo -e "\033[1;33m $(fun_trans "O nome sera alterado internamente no servodor")"
echo -ne "\033[1;37m $(fun_trans "Digite o novo nome do seu servidor"): " && read name
tput cuu1 && tput dl1
tput cuu1 && tput dl1
done
hostnamectl set-hostname $name 
if [ $(hostnamectl status | head -1  | awk '{print $3}') = "${name}" ]; then 
echo -e "\033[1;33m $(fun_trans "Nome Alterado Com Sucesso")!"
echo -e "\033[1;31m $(fun_trans "Novo Nome"): \033[1;32m$name"
else
echo -e "\033[1;31m $(fun_trans "Falhou")!"
fi
return
}

senharoot () {
msg -ama " $(fun_trans "Essa senha sera usada para entrar no seu servidor")"
msg -bar
echo -e "$(fun_trans "Deseja Prosseguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
#Inicia Procedimentos
msg -bar
echo -e "\033[1;37m $(fun_trans "DIGITE A NOVA SENHA")"
msg -bar
read  -p " Nuevo passwd: " pass
(echo $pass; echo $pass)|passwd 2>/dev/null
sleep 1s
msg -bar
msg -ama " $(fun_trans "SENHA ALTERADA COM SUCESSO")!"
echo -e "\033[1;31m $(fun_trans "NOVA SENHA"): \033[1;32m$pass"
return
}

fun_nload () {
msg -azu " $(fun_trans "PARA SALIR DEL PANEL PRESIONE") \033[1;33mCTLR + C"
msg -bar
echo -e "$(fun_trans "Deseja Prosseguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
#Inicia Procedimentos
msg -bar
[[ $(dpkg --get-selections|grep -w "nload"|head -1) ]] || apt-get install nload -y &>/dev/null
nload
msg -ama " $(fun_trans "Procedimento concluido")"
}

fun_htop () {
msg -azu " $(fun_trans "PARA SALIR DEL PANEL PRESIONE") \033[1;33mCTLR + C"
msg -bar
echo -e "$(fun_trans "Deseja Prosseguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
#Inicia Procedimentos
msg -bar
[[ $(dpkg --get-selections|grep -w "htop"|head -1) ]] || apt-get install htop -y &>/dev/null
htop
msg -ama " $(fun_trans "Procedimento concluido")"
}

pamcrack () {
#-----------------------------------------------------------------------------------------------------------------
# sudo apt-get install libpam-cracklib -y > /dev/null 2>&1
# wget https://raw.githubusercontent.com/AAAAAEXQOSyIpN2JZ0ehUQ/VPS-MX/main/VPS-MX_Oficial/ArchivosUtilitarios/common-password -O /etc/pam.d/common-password > /dev/null 2>&1 
# chmod +x /etc/pam.d/common-password
#-----------------------------------------------------------------------------------------------------------------
msg -ama " $(fun_trans "Desativar senhas alfanumericas em VULTR")"
msg -azu " $(fun_trans "Qualquer senha de 6 digitos pode ser usada ")"
msg -bar
echo -e "$(fun_trans "Deseja Prosseguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
msg -bar
#Inicia Procedimentos
msg -ama " $(fun_trans "Aplicando o Configuracoes VURLT ")"
msg -bar
fun_cracklib () {
sed -i 's/.*pam_cracklib.so.*/password sufficient pam_unix.so sha512 shadow nullok try_first_pass #use_authtok/' /etc/pam.d/common-password
service ssh restart
service sshd restart
}
fun_bar "fun_cracklib"
sleep 3s
msg -bar
msg -ama " $(fun_trans "Passwd Alphanumeric Disabled Com Sucesso")"
return
}

aplica_root () {
msg -ama " $(fun_trans "Aplica permissoes ao usuario root")"
msg -azu " $(fun_trans "Sistemas Google Cloud e Amazon ")"
msg -bar
echo -e "$(fun_trans "Deseja Prosseguir?")"
read -p " [S/N]: " -e -i n PROS
[[ $PROS = @(s|S|y|Y) ]] || return 1
msg -bar
#Inicia Procedimentos
msg -ama " $(fun_trans "Aplicando o Root ao Google Cloud e Amazon ")"
msg -bar
fun_aplicaroot () {
apt-get update -y
apt-get upgrade -y
sed -i "s;PermitRootLogin prohibit-password;PermitRootLogin yes;g" /etc/ssh/sshd_config
sed -i "s;PermitRootLogin without-password;PermitRootLogin yes;g" /etc/ssh/sshd_config
sed -i "s;PasswordAuthentication no;PasswordAuthentication yes;g" /etc/ssh/sshd_config
}
fun_bar "fun_aplicaroot"
msg -bar
echo -e "\033[1;37m $(fun_trans "Digite Sua Senha aAtual ou Uma Nova Senha")"
msg -bar
read  -p " Nuevo passwd: " pass
(echo $pass; echo $pass)|passwd 2>/dev/null
msg -bar
msg -ne "\033[1;31m [ ! ] \033[1;33m$(fun_trans "REINICIANDO SERVICOS*")"
service ssh restart > /dev/null 2>&1
service sshd restart > /dev/null 2>&1
echo -e " \033[1;32m[OK]"
sleep 3s
msg -bar
echo -e "\033[1;31m $(fun_trans "Senha Atual") Root: \033[1;32m$pass"
echo -e " \033[1;31mRuta sshd > \033[1;31m[ \033[1;32m/etc/ssh/sshd_config \033[1;31m]"
return
}

fun_scriptsexterno () {
/etc/ger-frm/scriptsalternos.sh
exit
}

# SISTEMA DE SELECAO
selection_fun () {
local selection="null"
local range
for((i=0; i<=$1; i++)); do range[$i]="$i "; done
while [[ ! $(echo ${range[*]}|grep -w "$selection") ]]; do
echo -ne "\033[1;37m$(fun_trans "Selecione a Opcao"): " >&2
read selection
tput cuu1 >&2 && tput dl1 >&2
done
echo $selection
}

clear
clear
msg -bar
msg -ama "$(fun_trans "GERENCIAMENTO DE SISTEMA")"
msg -bar
echo -ne "$(msg -verd "[0]") $(msg -verm2 ">") " && msg -bra "$(fun_trans "VOLTAR")"
echo -ne "$(msg -verd "[1]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "ATUALIZAR SISTEMA")"
echo -ne "$(msg -verd "[2]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "REINICIAR SERVICOS")"
echo -ne "$(msg -verd "[3]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "REINICIAR SISTEMA")"
echo -ne "$(msg -verd "[4]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "MUDAR O NOME DO SISTEMA")"
echo -ne "$(msg -verd "[5]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "ALTERAR SENHA ROOT")"
echo -ne "$(msg -verd "[6]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "TRAFICO DE RED NLOAD")"
echo -ne "$(msg -verd "[7]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "PROCESOS DE SISTEMA HTOP")"
echo -ne "$(msg -verd "[8]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "DESATIVAR SENHAS ALPANUMERICAS EN VURTL ")"
echo -ne "$(msg -verd "[9]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "ROOT AO GOOGLE CLOUD E AMAZON")"
msg -bar
echo -ne "$(msg -verd "[10]") $(msg -verm2 ">") " && msg -azu "$(fun_trans "TESTE SCRIPTS EXTERNO") \033[0;32m(#BET)"
msg -bar
# FIM
selection=$(selection_fun 10)
case ${selection} in
1)update_pak;;
2)reiniciar_ser;;
3)reiniciar_vps;;
4)host_name;;
5)senharoot;;
6)fun_nload;;
7)fun_htop;;
8)pamcrack;;
9)aplica_root;;
10)fun_scriptsexterno;;
0)exit;;
esac
msg -bar