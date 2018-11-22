#!/bin/bash
##################################################################
# VARIAVEIS                                                      #
##################################################################
HOME='/home/oracle/import_oracle'
FILES="$HOME/SQL-FILES"
DATAINICIAL=`date +%s`
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'` #ALTERADO PARA M520
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'` #ALTERADO PARA M520
##########################
#MUDE AQUI!!!
INSTANCE='INSTANCE'
USR_RM='USER_rm/PASS_rm'
##########################
LOG="stats_rm_$HOJE.log"
EMAIL='teste@gmail.com'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH
cd $HOME

##################################################################
# Geração de Estatisticas do Banco                               #
##################################################################
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                            STATS - ORACLE $IP(RM)                           ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo "" >> $LOG
echo "" >> $LOG
echo "Inicio do calculo de stats no CORPORE em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-STATS.txt
echo "Terminado calculo de stats no CORPORE em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
echo "" >> $LOG
echo "" >> $LOG

##################################################################
# Tempo decorrido                                                #
##################################################################
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULTADO=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULTADO +%H:%M:%S`
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo " Tempo utilizado: $TEMPO" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail de $LOG                                                  #
##################################################################
cat $LOG | mail -s "Calculos STATS - Oracle $IP" $EMAIL
rm $LOG > /dev/null