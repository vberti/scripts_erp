#!/bin/bash
##################################################################
# VARIAVEIS                                                      #
##################################################################
HOME='/home/oracle/import_oracle'
FILES="$HOME/SQL-FILES"
DATA_BACKUP=`date +%Y%m%d --date="yesterday"`
HOJE=`date +%Y%m%d`
DATAINICIAL=`date +%s`
HOST=`hostname -s`
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'` #ALTERADO PARA M520
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'` #ALTERADO PARA M520
##########################
#MUDE AQUI!!!
INSTANCE='INSTANCE'
USR_RM='USER_rm/PASS_rm'
USR_SYS='USER_sys/PASS_oracle'
##########################
LOG="drop_logs_$HOJE.log"
EMAIL='teste@gmail.com'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH

cd $HOME

#######################################################################################
# Remove todos os registros da GJOBX e relacionados                                   #
#######################################################################################
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                      LOG - DROP LOGS - ORACLE $IP(RM)                       ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo " Hostname: $HOST" >> $LOG
echo " IP: $IP_FULL" >> $LOG
echo " ORACLE SID: $INSTANCE" >> $LOG
echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
#QUANTIDADE DE REGISTROS A SEREM EXCLUIDOS
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-DROPLOGS2.txt >> tmp_drop_logs.txt

#REMOVE OS LOGS
echo "Inicio da remocao dos logs no CORPORE em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-DROPLOGS.txt
echo "Limpeza dos logs / tabelas no CORPORE em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "Registros excluidos durante o processo:" >> $LOG
echo "Tabela            Registros" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==14')
echo "GRELBATCH       $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==19')
echo "GJOBSERVER      $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==24')
echo "GJOBQUEUE       $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==29')
echo "GJOBLOG         $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==34')
echo "GJOBXLOG        $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==39')
echo "GJOBXEXECUCAO   $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==44')
echo "GJOBX           $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==49')
echo "GMAILSENDATTACH $REGISTRO" >> $LOG
REGISTRO=$(cat tmp_drop_logs.txt | awk 'NR ==54')
echo "GMAILSEND       $REGISTRO" >> $LOG

##################################################################
# Tempo decorrido                                                #
##################################################################
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULTADO=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULTADO +%H:%M:%S`
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
echo "Tempo utilizado para a limpeza: $TEMPO" >> $LOG
echo "" >> $LOG
echo "As tabelas seguir foram limpas:" >> $LOG
echo "Todas referente as de JOBS (GRELBATCH,GJOBSERVER,GJOBQUEUE,GJOBLOG,GJOBXLOG,GJOBX,"  >> $LOG
echo "GJOBXEXECUCAO), emails (GMAILSENDATTACH,GMAILSEND) e conteudo de CUBOS (QCUBODATA)." >> $LOG
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail de LOGS                                                  #
##################################################################
cat $LOG | mail -s "Remocao LOGS - Oracle $IP" $EMAIL
rm $LOG > /dev/null
rm tmp_drop_logs.txt