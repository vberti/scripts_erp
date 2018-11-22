#!/bin/bash
#Validated on 31/08
#Import a new DUMP to a =>NEW<= database
#Leave the rar file on the script folder!!!!
##################################################################
# VAR                                                            #
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
INSTANCE='INSTANCE_NAME'
USR_RM='user_rm/pass_rm'
USR_SYS='sys/pass_sys'
PASSRAR='rar_passwd'
#Leave the rar file on the script folder!!!!
##########################
LOG="implant_rm_$HOJE.log"
EMAIL='test@gmail.com'
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
# HEADER											                                  #
#######################################################################################
cd $HOME
rm $LOG > /dev/null
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                     LOG - Implantacao CORPORE - $IP(RM)                     ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo " Hostname: $HOST" >> $LOG
echo " IP: $IP_FULL" >> $LOG
echo " ORACLE SID: $INSTANCE" >> $LOG
echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
#Kick all the users an remove everything of RM
dbshut ORACLE_HOME #stop the database
echo 'Waiting 20 seconds to start the database'
sleep 10
dbstart ORACLE_HOME #start
sqlplus $USR_SYS@$INSTANCE as SYSDBA @$FILES/SQL-SYS1.txt

##################################################################
# Unrar                                                          #
##################################################################
echo "" >> $LOG
echo "Extraindo o dump em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

rar x RM_*.rar -hp$PASSRAR
mv RM*.dmp RM_DUMP.dmp

echo "RM_DUMP extraido em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Drop ORACLE                                                    #
##################################################################
echo "" >> $LOG
echo "Drop users/base em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

#2X - to sure =]
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
# IMPORT ORACLE     			                                 #
##################################################################
echo "" >> $LOG
echo "Inicio de IMPORT/RM em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

impdp $USR_RM@$INSTANCE schemas=RM directory=IMP_DIR dumpfile=RM_DUMP.dmp logfile=RM_impdp_$HOJE.log

echo "IMPORT/RM realizado em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
##################################################################
# Access and rebuild                                             #
##################################################################
echo "" >> $LOG
echo "Acessos e rebuilds em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM1.txt
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM2.txt

echo "Acessos realizados em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# Validation                                                     #
##################################################################
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
rm nf.txt
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-RM3.txt >> nf.txt
VALIDA=$(cat nf.txt | awk 'NR ==14')
rm nf.txt
echo "Data de emissao da ultima NF: " $VALIDA >> $LOG
echo "" >> $LOG

##################################################################
# Time 			                                                 #
##################################################################
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULTADO=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULTADO +%H:%M:%S`
echo "Tempo utilizado para o update: $TEMPO" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# Emails and logs                                                #
##################################################################
cat $LOG | mail -s "Implantacao $INSTANCE (RM) - $IP" $EMAIL