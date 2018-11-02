#!/bin/sh
CHKDIR=/var/.chkint
############################################################
###                                                      ###
###              SetUID 무결성 체크 스크립트             ###
###                       ver 1.0                        ###
###                                                      ###
###                    제작자 : 허태무                   ###
###                  burnpota@naver.com                  ###
###                                                      ###
### 본 스크립트는 OS 설치 직후 즉시 실행하는 것을 권장함 ###
###                                                      ###
############################################################


############################################################
####  SECTION 1. 부적절하게 추가된 SetUID 탐지 스크립트 ####
############################################################

### 무결성 인증용으로 초기 SUID의 목록과 해시값을 저장할 디렉터리를 만든다.
if [ ! -d $CHKDIR ] ### 기존 디렉터리가 있으면 생성하지 않는 조건을 추가한다.
then
	mkdir -m 500 $CHKDIR
fi
if [ ! -f $CHKDIR/initint ] ### 기존에 저장된 정보들이 존재하는지 확인한다
then 
	touch $CHKDIR/initint 
	find / -perm -4000 2> /dev/null > $CHKDIR/SUIDLIST
	cat $CHKDIR/SUIDLIST | sha512sum | awk '{print $1}' > $CHKDIR/SUIDINT
	### 해당 파일들이 삭제, 수정이 불가능하도록 i속성을 부여한다.
	chattr +i $CHKDIR/* 
	exit
fi
SUIDINT=`cat $CHKDIR/SUIDINT`
find / -perm -4000 2> /dev/null > /root/TMP_CHKSUID
PRESUIHASH=`cat /root/TMP_CHKSUID | sha512sum | awk '{print$1}'`
if [ $SUIDINT != $PRESUIHASH ]
then
	echo -e "\e[1;31;5m !!!Warning!!!\e[0m
\e[1;33mThere are invalid SetUID existing.
Must check the below list whether you've set up or not \e[0m"
	diff $CHKDIR/SUIDLIST /root/TMP_CHKSUID | sed -n '/>/p'
else
	echo -e "\e[1mSetUID LIST CHECK ....[\e[0;32mOK\e[1;39m]\e[0m"
fi

###########################################################
####  SECTION 2. SetUID가 적용된 파일들의 무결성 체크  ####
###########################################################


LISTLINE=$(cat -n ${CHKDIR}/SUIDLIST | awk '{print$1}')

### 기존에 각각의 SetUID 파일의 hash값이 저장된 파일이 존재하는지 확인한 후
### 없을 시 새로 생성한다
if [ ! -f $CHKDIR/SUIDHASH ]
then
	for i in $LISTLINE
	do
		SUFILE=`sed -n $i'p' $CHKDIR/SUIDLIST`
		sha512sum $SUFILE >> $CHKDIR/SUIDHASH
	done
	chattr +i $CHKDIR/SUIDHASH
	exit
fi


rm -f /root/TMP_SUIDHASH
for i in $LISTLINE 
do
	PREFILE=`sed -n $i'p' $CHKDIR/SUIDLIST`
	sha512sum $PREFILE >> /root/TMP_SUIDHASH
done

diff $CHKDIR/SUIDHASH /root/TMP_SUIDHASH >& /dev/null

if [ $? -eq 1 ]
then
	echo -e "\\e[1;31;5m !!!Warning!!!\e[0m
\e[1;33mThere are illegally modified SetUID files.
Must check the below list \e[0m"
	diff $CHKDIR/SUIDHASH /root/TMP_SUIDHASH
else
	echo -e "\e[1mSetUID FILES INTEGRY CHECK ....[\e[0;32mOK\e[1;39m]\e[0m"
fi
