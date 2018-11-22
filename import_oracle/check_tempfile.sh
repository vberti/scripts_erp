#!/bin/bash
##################################################################
# VARIAVEIS                                                      #
##################################################################
HOME='/home/oracle/import_oracle'
FILES="$HOME/SQL-FILES"
LOG='log_check_tempfile.log'
EMAIL='email@email.com'
HOST=`hostname -s`
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'` 
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'` 
##########################
#MUDE AQUI!!!
INSTANCE='INSTANCE'                      
TEMP_RM="/oracle/oradata/$INSTANCE/RMTMP1.DAT"             #LOCAL DO ARQUIVO
##########################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH
cd $HOME

##################################################################
# Check o tamanho do arquivo e envia via e-mail                  #
##################################################################
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                    ARQUIVO RMTMP1.DAT - ORACLE $IP(RM)                      ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo " Hostname: $HOST" >> $LOG
echo " IP: $IP_FULL" >> $LOG
echo " ORACLE SID: $INSTANCE" >> $LOG
echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
echo "Tamanho do arquivo RMTMP1.DAT em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG
echo "" >> $LOG
du -a -h $TEMP_RM  >> $LOG

echo "" >> $LOG
echo "" >> $LOG

echo "─════════════════════════════════PARTICOES═══════════════════════════════════─" >> $LOG
#Utilizado o PYDF para analise
pydf -h --bw >> teste111
#o comnado abaixo tira os escapes do txt, assim, evitando o anexo do email
sed -r 's|\x1B\[[0-9]{1,2};?(;[0-9]{1,2}){,2}m||g' teste111 >> teste112
cat teste112 >> $LOG

echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
echo "Para remover o arquivo, execute /home/oracle/import_oracle/drop_tempfile.sh" >> $LOG
echo "O script mencionado para a database, remove o arquivo e sobe novamente" >> $LOG
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail de LOGS                                                 #
##################################################################
cat $LOG | mail -s "RM Temp - Oracle $IP" $EMAIL
rm teste11* > /dev/null
rm $LOG > /dev/null