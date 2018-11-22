#!/bin/bash
##################################################################
# VARS                                                           #
##################################################################
HOME='/home/oracle/import_oracle'
FILES="$HOME/SQL-FILES"
DATA_BACKUP=`date +%Y%m%d --date="yesterday"`
HOJE=`date +%Y%m%d`
DATAINICIAL=`date +%s`
HOST=`hostname -s`
IP_FULL=`/sbin/ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
IP=`/sbin/ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'`
MD5_1='1'
MD5_2='2'
##########################
#Change here!!!
INSTANCE='INSTANCE'
USR_RM='USER_rm/PASS_rm'
USR_SYS='USER_sys/PASS_sys'
PASSRAR='PASS_rar'
##########################
LOG="update_rm_$HOJE.log"
EMAIL='email@gmail.com'
#RSYNC
SSHKEY="/home/oracle/.ssh/$IP-rsync-key"
SERVER='oracle@192.168.1.10'
REMOTEPATH='/home/oracle/export_oracle'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH

#######################################################################################
# Remove os arquivos, para o banco e sobe novamente                                   #
#######################################################################################
cd $HOME
rm $LOG > /dev/null
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                   LOG - UPDATE da base de Teste $IP(RM)                     ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo " Hostname: $HOST" >> $LOG
echo " IP: $IP_FULL" >> $LOG
echo " ORACLE SID: $INSTANCE" >> $LOG
echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
echo "Removendo arquivos antigos em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

#Disconecta os usuarios e remove tudo da RM
rm -fr RM_*.* > /dev/null
dbshut ORACLE_HOME #para o banco
echo 'Waiting 20 seconds to start the database'
sleep 20
dbstart ORACLE_HOME #sobe o banco
sqlplus $USR_SYS@$INSTANCE as SYSDBA @$FILES/SQL-SYS1.txt

echo "Antigos arquivos removidos em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
echo "" >> $LOG

##################################################################
# Transferindo dump do server para o servidor de teste           #
##################################################################
echo "Iniciando o transfer do DUMP em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
clear
echo "Iniciando transfer de arquivos ORACLE entre servidores"
echo $IP
echo $IP_FULL
#Funcao transfer
transfer (){
rsync -avh -e "ssh -i $SSHKEY" $SERVER:$REMOTEPATH/RM_$DATA_BACKUP.rar $HOME
MD5_1=`cat RM_$DATA_BACKUP.rar.md5 | cut -d " " -f1`
echo $MD5_1
MD5_2=`md5sum RM_$DATA_BACKUP.rar | cut -d " " -f1`
echo $MD5_2
}

# Check the MD5. If <> again.
while [ $MD5_1 != $MD5_2 ]
do
transfer
done

echo "Transferido entre servidores em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Unrar                                                          #
##################################################################
echo "" >> $LOG
echo "Extraindo o dump em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

rar x RM_$DATA_BACKUP.rar -hp$PASSRAR
rm RM_$DATA_BACKUP.rar
rm *.md5
mv RM*.dmp RM_DUMP.dmp

echo "RM_DUMP extraido em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Drop ORACLE                                                    #
##################################################################
echo "" >> $LOG
echo "Drop users/base em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

#2X - PRA TER CERTEZA
sqlplus $USR_SYS@$INSTANCE as SYSDBA @$FILES/SQL-SYS2.txt
sqlplus $USR_SYS@$INSTANCE as SYSDBA @$FILES/SQL-SYS2.txt

echo "Drop finalizado em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Create ORACLE                                                  #
##################################################################
echo "" >> $LOG
echo "Criando users/parameters RM em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM1.txt

echo "Usuarios/parametros criados em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Processo de IMPORT ORACLE                                      #
##################################################################
echo "" >> $LOG
echo "Inicio de IMPORT/RM em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

impdp $USR_RM@$INSTANCE schemas=RM directory=IMP_DIR dumpfile=RM_DUMP.dmp logfile=RM_impdp_$HOJE.log

echo "IMPORT/RM realizado em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
rm RM*.dmp
##################################################################
# Acessos e rebuild                                              #
##################################################################
echo "" >> $LOG
echo "Acessos e rebuilds em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM1.txt
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM2.txt

echo "Acessos realizados em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Validação do update                                            #
##################################################################
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
rm nf.txt
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM3.txt >> nf.txt
VALIDA=$(cat nf.txt | awk 'NR ==14')
rm nf.txt
echo " Data de emissao da ultima NF: " $VALIDA >> $LOG
echo "" >> $LOG

##################################################################
# Tempo decorrido                                                #
##################################################################
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULTADO=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULTADO +%H:%M:%S`
echo " Tempo utilizado para o update: $TEMPO" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail e logs                                                  #
##################################################################
cat $LOG | mail -s "Update $INSTANCE (TS) - $IP" $EMAIL