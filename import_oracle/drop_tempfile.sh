#!/bin/bash
#Remove the tempfile of database.
#This is necessary because sometime the file is huge and the support of ERP dont know why.
##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=CORPORE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'` 
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'`

##################################################################
# VAR                                                            #
##################################################################
HOME='/home/oracle'
TEMP_RM='/oracle/oradata/CORPORE/RMTMP1.DAT'

cd /home/oracle/import_oracle

##################################################################
# Stop the database and remove the file                          #
##################################################################
clear
echo -e "Para o listener e Banco de Dados.\n"
dbshut ORACLE_HOME

date +%d/%m/%Y-%H:%M:%S >>drop_tempfile_history.log
echo -e "Verifica o tamanho do arquivo e adiciona no LOG.\n" 
du -a -h $TEMP_RM  >>drop_tempfile_history.log
echo -e >>drop_tempfile_history.log

echo -e "Removendo o arquivo do Sistema.\n" 
rm  $TEMP_RM

echo -e "Apos a remocao,inicia o banco e o listener.\n" 
dbstart ORACLE_HOME