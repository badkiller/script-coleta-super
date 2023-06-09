#!/bin/bash
#
# Script ..: coleta-info-servidores-super.sh
# Descrição: Coletar dados/parametros do sistema operacional e aplicacao SEI/Super
# Autor ...: Eugenio Oliveira/Tadeu Rocha
# Data/hora: 28/04/2023 15:30h

# Definição de variaveis globais
vDEBUG=0
vSERVICO=0

#########################################################################
# Função Ajuda
# Mostra as opções do script de analise de dados
#
Ajuda() {

  echo ""
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
  echo " Script de analise de dados/parametros da instalação do SEI ou Super versão 4.x"
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
  echo ""
  echo " Opções deste script são:"
  echo " ---------------------------------------------------"
  echo " Exemplo: $0 numero [debug]"
  echo ""
  echo " Onde:"
  echo ""
  echo " 1 - Coletar dados - Apache/HTTPD/PHP e SEI/Super"
  echo " 2 - Coletar dados - Memcached"
  echo " 3 - Coletar dados - Solr 8.2"
  echo " 4 - Coletar dados - Nginx (Balanceador de carga)"
  echo ""
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
  echo "                                        Autor: EAO/TR"
}

#########################################################################
# Função debug
# Exibe informações de vDEBUG em stderr
#
debug () {

        if [ "$vDEBUG" -ne "0" ] ; then

        case $1 in
                1) echo -e "[+] $2" >&2
                ;;
                2) echo -e "    [-] $2" >&2
                ;;
                3) echo -e "        [*] $2" >&2
                ;;
                4) echo -e "            [#] $2" >&2
                ;;
                5) echo -e "                [x] $2" >&2
                ;;
                *) echo -e "[+] $*" >&2
                ;;
        esac

        fi
}

#########################################################################
# Função SistemaOperacional
# Coleta as informações do Sistema Operacional
#
SistemaOperacional () {
debug 2 "Coletando informações do Sistema Operacional"

mkdir -p /tmp/analise/so/{selinux,sysconfig}

# Coleta informações do S.O. para analise e melhorias (tuning)
if [ $vSERVICO -ne 4 ] ; then
   cp -a /etc/redhat-release /tmp/analise/so/
   cp -a /etc/selinux/config /tmp/analise/so/selinux/
   vHOSTNAME=$(hostname -i)
else
   vHOSTNAME=$(hostname -I)
fi
cp -a /etc/os-release /tmp/analise/so/
cp -a /etc/fstab /tmp/analise/so/
cp -a /etc/sysctl.conf /tmp/analise/so/
cp -a /etc/sysctl.d /tmp/analise/so/
cp -a /etc/security /tmp/analise/so/
cp -a /etc/hosts /tmp/analise/so/
cp -a /etc/machine-id /tmp/analise/so/
lsblk > /tmp/analise/so/disks.log
fdisk -l > /tmp/analise/so/partitions-list.log
mount > /tmp/analise/so/mounts-list.logg
df -hT > /tmp/analise/so/df.log
free -g > /tmp/analise/so/free.log
uptime > /tmp/analise/so/uptime.log
locale > /tmp/analise/so/locale.log
ls -l /etc/localtime > /tmp/analise/so/localtime.log
cp -a /etc/default /tmp/analise/so/
ps axf > /tmp/analise/so/process-list.log
cp -a /etc/crontab /tmp/analise/so/crontab.log
cat /proc/cpuinfo > /tmp/analise/so/cpuinfo.log
cat /proc/meminfo > /tmp/analise/so/meminfo.log
rpm -qa > /tmp/analise/so/packages.log
sysctl -a > /tmp/analise/so/sysctl-conf.log
systemctl list-unit-files --state=enabled > /tmp/analise/so/systemctl-enabled.log

cd /sys/class/net
for vINTERFACE in $(ls -1|grep -v lo) ; do 
    echo "$vINTERFACE;$vHOSTNAME;$(cat $vINTERFACE/address);$(cat $vINTERFACE/speed);$(cat $vINTERFACE/duplex);$(cat $vINTERFACE/mtu)" >> /tmp/analise/so/interfaces.log
done

vmstat 1 30 > /tmp/analise/so/vmstat.log

}

#########################################################################
# Função Apache
# Coleta as informações do Serviço do Apache e do SEI/SIP
#
Apache () {
debug 2 "Coletando informações do Apache/HTTPD"

mkdir -p /tmp/analise/httpd

# Coleta informações dos principais componentes do Apache e PHP para analise
cp -a /etc/php.ini /tmp/analise/httpd/
cp -a /etc/php.d /tmp/analise/httpd/
cp -a /etc/php-fpm.conf /tmp/analise/httpd/
cp -a /etc/php-fpm.d /tmp/analise/httpd/
cp -a /etc/httpd/conf* /tmp/analise/httpd/
apachectl -V > /tmp/analise/httpd/httpd.log
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+" >> /tmp/analise/httpd.log
apachectl -M >> /tmp/analise/httpd/httpd.log
php -v > /tmp/analise/httpd/php.log
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+" >> /tmp/analise/httpd/php.log
php -m >> /tmp/analise/httpd/php.log
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+" >> /tmp/analise/httpd/php.log
php -i >> /tmp/analise/httpd/php.log

cat /proc/$(ps axu|grep '/usr/sbin/httpd'|grep root|grep -v grep|awk '{print $2}')/limits > /tmp/analise/httpd/limits.log
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+" >> /tmp/analise/httpd/limits.log
cat /proc/$(ps axu|grep '/usr/sbin/httpd'|grep apache|grep -v grep|head -1|awk '{print $2}')/limits >> /tmp/analise/httpd/limits.log

debug 3 "Coletando informações da Aplicacao SEI/SIP"
mkdir -p /tmp/analise/app/

#Coleta a configuração dos arquivos principais da aplicação retirando dados sensiveis (senhas)
grep -v "Senha" /fontes/sei/config/ConfiguracaoSEI.php > /tmp/analise/app/config-sei.log
grep -v "Senha" /fontes/sip/config/ConfiguracaoSip.php > /tmp/analise/app/config-sip.log

# Coleta informações de permissões dos arquivos da aplicação
ls -lR /fontes/s* /fontes/infra* > /tmp/analise/app/list-files-perm-app.log

vDADOS=$(grep RepositorioArquivos /fontes/sei/config/ConfiguracaoSEI.php | awk -F"'" '{print $4}')
if [ "$vDADOS" ] ; then
   ls -lR $vDADOS > /tmp/analise/app/list-files-perm-anexos.log
fi

# Coleta informações do ffmpeg
ffmpeg -version > /tmp/analise/app/ffmpeg.log

# Coleta informações do wkhtmltopdf
wkhtmltopdf --version > /tmp/analise/app/wkhtmltopdf.log

}

#########################################################################
# Função Memcached
# Coleta as informações do Serviço do Memcached
#
Memcached () {
debug 2 "Coletando informações do Memcached"

mkdir -p /tmp/analise/memcached/

# Coleta configurações do Memcached
cp -a /etc/sysconfig/memcached /tmp/analise/memcached/

}

#########################################################################
# Função Java
# Coleta as informações do Java
#
Java () {
debug 2 "Coletando informações do Java"

mkdir -p /tmp/analise/java/

# Coleta informações do Java
java -version 2> /tmp/analise/java/java-version.log

}

#########################################################################
# Função Solr
# Coleta as informações do Serviço do Memcached
#
Solr () {

debug 2 "Coletando informações do Solr"

mkdir -p /tmp/analise/solr/{sei-protocolos,sei-publicacoes,sei-bases-conhecimento}/conf

cp -a /etc/default/solr.in.sh /tmp/analise/solr

cp -a /dados/sei-protocolos/core.properties /tmp/analise/solr/sei-protocolos
cp -a /dados/sei-protocolos/conf/schema.xml /tmp/analise/solr/sei-protocolos/conf
cp -a /dados/sei-protocolos/conf/solrconfig.xml /tmp/analise/solr/sei-protocolos/conf

cp -a /dados/sei-publicacoes/core.properties /tmp/analise/solr/sei-publicacoes
cp -a /dados/sei-publicacoes/conf/schema.xml /tmp/analise/solr/sei-publicacoes/conf
cp -a /dados/sei-publicacoes/conf/solrconfig.xml /tmp/analise/solr/sei-publicacoes/conf

cp -a /dados/sei-bases-conhecimento/core.properties /tmp/analise/solr/sei-bases-conhecimento/
cp -a /dados/sei-bases-conhecimento/conf/schema.xml /tmp/analise/solr/sei-bases-conhecimento/conf
cp -a /dados/sei-bases-conhecimento/conf/solrconfig.xml /tmp/analise/solr/sei-bases-conhecimento/conf

}

#########################################################################
# Função Nginx
# Coleta as informações do Serviço do Nginx
#
Nginx () {

debug 2 "Coletando informações do nginx"

cp -a /etc/nginx /tmp/analise/

}


###############################################################################
# Inicio do processo de analise
#

#clear
vSERVICO=$1
vPWD=$(pwd)

if [ -z "$vSERVICO" ]; then Ajuda ; exit ; fi
if [ "$2" = "debug" ]; then vDEBUG=1 ; fi

################################################################
if [ $vDEBUG -eq 1 ]; then
  echo ""
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
  echo "   Script de analise de dados ambiente SEI/Super"
  echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
  echo ""
fi

debug 1 "Iniciando a execução dos procedimentos"

if [ $vSERVICO -lt 5 ]; then
   SistemaOperacional
   if [ $? -ne 0 ]; then
      alerta "Houve um erro, por favor enviar o resultado."
      exit 1
   fi
fi

case "$vSERVICO" in
   1) Apache ; Java
   ;;
   2) Memcached
   ;;
   3) Solr ; Java
   ;;
   4) Nginx
   ;;
   *) Ajuda
      exit 1
   ;;
esac

cd $vPWD
vARQUIVO="analise-$(hostname)-$(date +'%s').tgz"

debug 2 "Compactando tudo do /tmp/analise"
tar zcf $vARQUIVO /tmp/analise > /dev/null 2>&1

debug 2 "Removendo diretorio temporário utilizado"
rm -rf /tmp/analise

echo ""
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo "   Encaminhar o arquivo abaixo para analise."
echo "   $vARQUIVO"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+"
echo ""

debug 1 "Fim da execução dos procedimentos"
#Fim