#!/bin/bash
##################################################################
# VARIAVEIS                                                      #
##################################################################
HOME='/home/oracle/export_oracle'
#########################
HOST=`hostname -s`
DATAINICIAL=`date +%s`
DATE=`date +%Y%m%d`
YESTERDAY=`date +%Y%m%d --date="yesterday"`
IP_FULL=`/sbin/ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
IP=`/sbin/ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'`
##########################
#MUDE AQUI!!!
INSTANCE='INSTANCE'
USR_RM='user_rm/pass_rm'
##########################
LOG='backup.log'
EMAIL='teste@gmail.com'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH
export NLS_DATE_FORMAT='dd/mm/yyyy hh24:mi:ss'

##################################################################
# DUMP                                                           #
##################################################################
cd $HOME
echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
echo "║                           LOG - RMAN ORACLE $IP(RM)                         ║" >> $LOG
echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
echo " Hostname: $HOST" >> $LOG
echo " IP: $IP_FULL" >> $LOG
echo " ORACLE SID: $INSTANCE" >> $LOG
echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG

##################################################################
# CASE DO RMAN                                                   #
##################################################################
echo "" >> $LOG
echo "Rotina RMAN ($1) iniciado em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

PAR=$1
case $PAR in
"LVL1")
rman << EOT target / | tee /backup/logs/rman_$1_$DATE.log
set echo on
show all;
alter database backup controlfile to trace as '/backup/controlfile/ct_file_$DATE.txt';
alter system checkpoint;
alter system switch logfile;
alter system switch logfile;
set command id to 'BACKUP DATABASE';
backup as compressed backupset incremental level 1 database tag 'LVL-1-DIARIO'
		format '/backup/rman/BKP_DB_%d_%t_%s.rman'
		;
backup as compressed backupset 	current controlfile 
	tag 'BKP_CF' 
		format '/backup/controlfile/BKP_CF_%d_%t_%s.rman'
		;
backup as compressed backupset spfile 
	tag 'BKP_SP'
        format '/backup/spfile/BKP_SP_%d_%t_%s.rman'
		;
alter system archive log current;
backup as compressed backupset
	archivelog all
	delete all input
	filesperset 10
	maxsetsize=1G
	tag 'BK_ARCHIVE' format '/backup/archivelogs/BKP_ARCH_%d_%t_%s.rman'
		;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUP;
exit;
EOT
	;;
"LVL0")
rman << EOT target / | tee /backup/logs/rman_$1_$DATE.log
set echo on
show all;
alter database backup controlfile to trace as '/backup/controlfile/ct_file_$DATE.txt';
alter system checkpoint;
alter system switch logfile;
alter system switch logfile;
set command id to 'BACKUP DATABASE';
backup as compressed backupset incremental level 0 database tag 'LVL-0-FULL'
		format '/backup/rman/BKP_DB_%d_%t_%s.rman'
		;
backup as compressed backupset 	current controlfile 
	tag 'BKP_CF' 
		format '/backup/controlfile/BKP_CF_%d_%t_%s.rman'
		;
backup as compressed backupset spfile 
	tag 'BKP_SP'
        format '/backup/spfile/BKP_SP_%d_%t_%s.rman'
		;
alter system archive log current;
backup as compressed backupset
	archivelog all
	delete all input
	filesperset 10
	maxsetsize=1G
	tag 'BK_ARCHIVE' format '/backup/archivelogs/BKP_ARCH_%d_%t_%s.rman'
		;
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUP;
exit;
EOT
	;;
	*)
		echo "Backup RMAN"
        echo "Uso: $0 {LVL0|LVL1}"
	;;	
esac
echo "         Processo finalizado em `date +%H:%M:%S=={%d/%m/%y}`" >> $LOG

##################################################################
# INFO ADICIONAIS                                                #
##################################################################
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
echo "" >> $LOG
DATAFINAL=`date +%s`
SOMA=`expr $DATAFINAL - $DATAINICIAL`
RESULT=`expr 10800 + $SOMA`
TEMPO=`date -d @$RESULT +%H:%M:%S`

echo "Tempo total do processo: $TEMPO" >> $LOG
echo "" >> $LOG
echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

##################################################################
# E-mail de log                                                  #
##################################################################
cat $LOG | mail -s "Backup RMAN ($1) - $IP" -a /backup/logs/rman_$1_$DATE.log $EMAIL
rm $LOG > /dev/null