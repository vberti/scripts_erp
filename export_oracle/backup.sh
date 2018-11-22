#!/bin/bash
#
# 24/02/17 - Anexado o log do DUMP
# 08/05/17 - Senha no arquivo RAR
# 20/06/17 - Alterado user e pass do storage
# 
# Utilize ./backup.sh BANCODEDADOS  
# 
##################################################################
# VARIAVEIS GLOBAIS                                              #
##################################################################
HOME='/home/oracle/export_oracle'
#CONFIG STORAGE
STORAGE='192.168.1.10'
FTP_USER='ftp_user'
FTP_PASSWD='ftp_pass'
#########################
HOST=`hostname -s`
DATAINICIAL=`date +%s`
DATE=`date +%Y%m%d`
YESTERDAY=`date +%Y%m%d --date="yesterday"`
IP_FULL=`/sbin/ip addr | grep '192' | awk '{print $2}' | cut -f1  -d'/'`        
IP=`/sbin/ip addr | grep '192' | awk '{print $2}' | sed -r 's!/.*!!; s!.*\.!!'` 
##########################
EMAIL='email@gmail.com'

##################################################################
# PATH                                                           #
##################################################################
ORACLE_BASE=/home/oracle/app; export ORACLE_BASE
ORACLE_SID=$INSTANCE; export ORACLE_SID
ORACLE_HOME=/home/oracle/app/product/12.1.0/dbhome_1; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH; export PATH

#FUNCOES
chk_online (){  
VAR_ONLINE=`sqlplus -silent $USR@$INSTANCE <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
whenever sqlerror exit 1;
SELECT 1 FROM dual;
EXIT 0;
EOF`
ONLINE=`echo $VAR_ONLINE | cut -c 1`
}
calcula_tempo(){
	DATAFINAL=`date +%s`
	SOMA=`expr $DATAFINAL - $DATALOGINICIAL`
	RESULT=`expr 10800 + $SOMA`
	TEMPO=`date -d @$RESULT +%H:%M:%S`
	}

# VERIFICA SE O PARAMETRO ESTA VAZIO
if [ -z $1 ]
then
    echo ""
	echo "╔═════════════════════════════════════════════════════════════════════════════╗"
	echo "║                       *** SEM INSTANCIA DEFINIDA! ***                       ║"
	echo "║                                                                             ║"
	echo "║                       Utilize: ./backup.sh INSTANCIA                        ║"
	echo "╚═════════════════════════════════════════════════════════════════════════════╝"
	echo ""
	elif [ -n $1 ]
then
  #PEGA O PARAMETRO E CLASSIFICA
  INSTANCE=$1
  # SE DATABASE FOR DO TIPO RM, PARAMETROS RM
  case $INSTANCE in 
	#NOMES CONVENCIONAIS DE DATABASES RM
	CORPORE | CORPORETS | VALIDA )
		##################################################
		FTP_DIR='portaria/BackupCorpore'
		USR='user_RM/pass_RM'
		SCH='schema_rm'
		PASSRAR='pass_rar'
		##################################################
;;
	# SE DATABASE FOR DO TIPO portal, PARAMETROS PORTAL
	PORTAL | PORTALTS | PORTALVALIDA | CORPTS)
		##################################################
		FTP_DIR='portaria/BackupIntra'
		USR='user_INTRA/pass_INTRA'
		SCH='schema_INTRA'
		PASSRAR='pass_rar_portal'
		##################################################
;;
esac  
##################################################################
# LOGS E ARQUIVO DE BACKUP                                       #
##################################################################
LOG="backup_${SCH}_${DATE}.log"
DUMP_FILE="${SCH}_${DATE}"
BKP_FILE="$DUMP_FILE.rar"
##################################################################

#VERIFICA SE A BASE ESTÁ ONLINE - FUNCAO CHK_ONLINE()
chk_online
if [ $ONLINE = 1 ]; then
    ##################################################################
	# SE ESTIVER ONLINE, ROTINA FULL DE BACKUP                       #
	##################################################################
	cd $HOME
	#REMOVE O LOG DO DIA , ALÉM DO DUMP
	[ -e $LOG ] && rm $LOG
	[ -e $DUMP_FILE.dmp ] && rm $DUMP_FILE.dmp
	echo "╔═════════════════════════════════════════════════════════════════════════════╗" >> $LOG
	echo "║                         LOG - Backup ORACLE $IP                             ║" >> $LOG
	echo "╚═════════════════════════════════════════════════════════════════════════════╝" >> $LOG
	echo " Hostname: $HOST" >> $LOG
	echo " IP: $IP_FULL " >> $LOG
	echo " ORACLE SID: $INSTANCE" >> $LOG
	echo " Inicio do processo: `date +%H:%M:%S`" >> $LOG
	echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
	echo "" >> $LOG
	echo "Gerando o dump da base em `date +%H:%M:%S`" >> $LOG
	
	DATALOGINICIAL=`date +%s`
	#EXPDP + MD5 - adicionado EXCLUDE=STATISTICS em 22/06 
	expdp $USR@$INSTANCE schemas=$SCH directory=EXP_DIR dumpfile=$DUMP_FILE.dmp logfile=$DUMP_FILE.expdp.log EXCLUDE=STATISTICS
	md5sum $DUMP_FILE.dmp > $DUMP_FILE.md5
	calcula_tempo
	echo "        Arquivo gerado em `date +%H:%M:%S`" >> $LOG
	echo "                         ($TEMPO)" >> $LOG
	
	##################################################################
	# RAR                                                            #
	##################################################################
	echo "" >> $LOG
	#RAR + MD5
	DATALOGINICIAL=`date +%s`
	echo "Inicio da compactacao em `date +%H:%M:%S`" >> $LOG
	rar a $BKP_FILE $DUMP_FILE.* -m3 -hp$PASSRAR
	md5sum $BKP_FILE > $BKP_FILE.md5
	calcula_tempo
	echo "   Arquivo compactado em `date +%H:%M:%S`" >> $LOG
	echo "                        ($TEMPO)" >> $LOG

	##################################################################
	# STORAGE                                                        #
	##################################################################
	echo "" >> $LOG
	DATALOGINICIAL=`date +%s`
	echo "Enviando para o storage em `date +%H:%M:%S`" >> $LOG
	#Login FTP e envia o arquivo
ftp -n -v $STORAGE << EOT
user $FTP_USER $FTP_PASSWD
prompt
cd $FTP_DIR
put $HOME/$BKP_FILE $BKP_FILE
bye
bye
EOT
	calcula_tempo
	echo "Transferência concluida em `date +%H:%M:%S`" >> $LOG
	echo "                          ($TEMPO)" >> $LOG
		
	##################################################################
	# INFO ADICIONAIS                                                #
	##################################################################
	echo "" >> $LOG
	echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG
	echo "" >> $LOG
	
	#VERIFICA SE O ARQUIVO ESTA NO STORAGE
	wget -O/dev/null -q ftp://$FTP_USER:$FTP_PASSWD@$STORAGE/$FTP_DIR/$BKP_FILE && echo "OBS: Backup validado no Storage $STORAGE."  >> $LOG || echo "OBS: O backup não existe no Storage. Favor verificar."  >> $LOG
	echo "" >> $LOG
	
	FILE=`ls $BKP_FILE`
	DATAFINAL=`date +%s`
	SOMA=`expr $DATAFINAL - $DATAINICIAL`
	RESULT=`expr 10800 + $SOMA`
	TEMPO=`date -d @$RESULT +%H:%M:%S`
	SIZE=`du -h $FILE | cut -f1`
	MD5=`cat $BKP_FILE.md5 | cut -d " " -f1`

	echo "Nome do arquivo: $FILE" >> $LOG
	echo "" >> $LOG
	echo "MD5: $MD5" >> $LOG
	echo "" >> $LOG
	echo "Tamanho: $SIZE" >> $LOG
	echo "" >> $LOG
	echo "Tempo total do processo de backup: $TEMPO" >> $LOG
	echo "" >> $LOG
	echo "─═════════════════════════════════════════════════════════════════════════════─" >> $LOG

	##################################################################
	# E-MAIL DE LOG                                                  #
	##################################################################
	cat $LOG | mail -s "Backup $SCH - $IP" -a /home/oracle/export_oracle/$DUMP_FILE.expdp.log $EMAIL
	#-a /backup/logs/rman_$1_$DATE.log $EMAIL
	
	#Remove backups anteriores e deixa os ultimos 5
	rm -fr ${SCH}_$YESTERDAY.dmp
	rm -fr backup_${SCH}*
	rm -fr *.md5
	find /home/oracle/export_oracle/${SCH}_2* -mtime +5 | xargs -r rm
	find /home/oracle/export_oracle/backup_${SCH}_2* -mtime +5 | xargs -r rm
			
  else
    # SE A INSTANCIA NAO EXISTIR OU OFFLINE , EXIBE MENSAGEM DE ERRO.
	echo ""
	echo "╔═════════════════════════════════════════════════════════════════════════════╗"
	echo "║              Parametros inválidos ou database não existe                    ║"
	echo "╚═════════════════════════════════════════════════════════════════════════════╝"
	echo ""
  fi
fi  