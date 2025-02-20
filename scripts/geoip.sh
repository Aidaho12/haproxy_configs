#!/bin/bash

set -e -o pipefail

country_location="GeoLite2-Country-CSV_*/GeoLite2-Country-Locations-en.csv"
country_ip="GeoLite2-Country-CSV_*/GeoLite2-Country-Blocks-IPv4.csv"
service_dir="/etc/haproxy/"
MAXMIND_LICENSE="zsf3bqLEJjilw2rL"
PROXY=""

if [[ $PROXY != "" ]]
then
	export http_proxy="$PROXY"
	export https_proxy="$PROXY"
fi

cd /tmp

rm -rf geo2lite

if [[ ! -d geo2lite ]]; then 
	mkdir geo2lite && cd geo2lite && mkdir subnets
else
	cd geo2lite
fi

if [[ -f geoip2lite.zip ]]; then
	rm -f geoip2lite.zip
fi

wget "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=${MAXMIND_LICENSE}&suffix=zip" -qO geoip2lite.zip && unzip -oq geoip2lite.zip


function get_ips_by_country {
	rm -f subnets/$2.subnets
	cat $country_ip |grep $1 |awk -F"," '{print $1}' >> subnets/$2.subnets
}

while read line; do
	country_code_dig=$(echo $line |awk -F"," '{print $1}')
	country_code_buk=$(echo $line |awk -F"," '{print $5}')
	if [[ $country_code_dig != '' ]] && [[ $country_code_buk != '' ]] && [[ $country_code_buk != 'country_iso_code' ]] ; then
		get_ips_by_country $country_code_dig $country_code_buk
	fi

done < $country_location

if [[ ! -d "$service_dir"/geoip ]]; then
	mkdir "$service_dir"/geoip
fi

cp subnets/* "$service_dir"/geoip

systemctl reload haproxy