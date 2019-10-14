#!/bin/bash

if [ -z "$1" ]
  then
    echo "usage is 'enum.sh domain.com'"
    exit 1
fi

echo 'Creating project '$1
mkdir ~/$1
cd ~/$1
mkdir ~/$1/screenshots
mkdir ~/$1/html
mkdir ~/$1/gobuster

echo 'Enumerating first level domain'
amass enum --passive -d $1 -o ~/$1/$1.amass.txt

echo 'Generating more domain names and checking what resolves with massdns'
cat ~/$1/$1.amass.txt | dnsgen - | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -o S -w ~/$1/$1.mdns.txt

echo 'Sort, uniq, extract first column (domain names) and remove dot from the end of a file name'
awk '{print $1}' ~/$1/$1.mdns.txt |sort|uniq|sed 's/\.$//' > ~/$1/$1.resolved.txt

echo 'Scanning all resolvable addresses with nmap'
nmap -iL ~/$1/$1.resolved.txt -F -T4 -oA ~/$1/$1.nmap

echo 'Converting nmap results with https://github.com/lkorba/nparser.git'
nparser.py -i ~/$1/$1.nmap.xml > ~/$1/$1.http.txt

echo 'Making httpscreenshot on the nmap results:'
~/tools/httpscreenshot/httpscreenshot.py -i ~/$1/$1.nmap.gnmap -p -w 10 -a -vH -r 2

echo 'Moving screenshots and html files to their respective dirs:'
mv ~/$1/*.png ~/$1/screenshots 
mv ~/$1/*.html ~/$1/html

echo 'Enumerating directories in all found website addresses'
while read line  ; do out=$(echo $line| awk -F[/:] '{print $4"_"$5}'); gobuster dir -e -u $line -w /usr/share/dirb/wordlists/common.txt -s 200 --wildcard -o ~/$1/gobuster/$out.txt ; done < ~/$1/$1.http.txt
