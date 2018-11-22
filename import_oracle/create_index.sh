#!/bin/bash

##################################################################
# VARIAVEIS                                                      #
##################################################################
HOME='/home/oracle/import_oracle'
FILES="$HOME/SQL-FILES"
DATAINICIAL=`date +%s`
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'` 
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'` 
##########################
#MUDE AQUI!!!
INSTANCE='NOMEDAINSTANCIA'
USR_RM='user/user'
##########################
LOG="index_rm_$HOJE.log"
EMAIL='email@gmail.com'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH

cd $HOME

##################################################################
# Geração de INDEX do Banco                                      #
##################################################################
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                            INDEX - ORACLE $IP(RM)                           ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo "" >> $LOG
echo "Inicio do rebuild INDEX  em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
sqlplus $USR_RM@$INSTANCE @$FILES/SQL-INDEX.txt
echo "Rebuild INDEX realizado  em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
echo "" >> $LOG

##################################################################
# Tempo decorrido                                                #
##################################################################
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULTADO=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULTADO +%H:%M:%S`
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "Tempo utilizado: $TEMPO" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail de LOGS                                                  #
##################################################################
cat $LOG | mail -s "Rebuild INDEX - Oracle $IP" $EMAIL
rm $LOG > /dev/null