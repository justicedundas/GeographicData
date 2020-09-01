#!/bin/bash

working_dir=$(pwd)
data_dir="$working_dir/data"
save_dir="$working_dir/savedData"

# [BEGIN] CONFIGURATION FOR THE SCRIPT
# -------------------------------------

# Geonames URLs
geonames_general_data_repo="http://download.geonames.org/export/dump"
geonames_postal_code_repo="http://download.geonames.org/export/zip"


# Default value for download folder
download_folder="$working_dir/data/download"
cities_folder="$working_dir/cities"
admin_folder="$working_dir/admins"

# Geoname Table Dumps
geonamedumps="cities15000.zip cities5000.zip cities1000.zip cities500.zip"
admindumps="admin1CodesASCII.txt admin2Codes.txt"
tz_lang="timeZones.txt iso-languagecodes.txt"
postal_codes="allCountries.zip"
hier_dump="hierarchy.zip"
feat_dump="featureCodes_en.txt"
altname_dump="alternateNamesV2.zip"
post_dump='allCountries.zip'
geojson_dump='shapes_simplified_low.json.zip'
# File Names
city_file="allCities.csv"
country_info="countryInfo.csv"
admin_file="admindivs.csv"
tzone_file="timezones.csv"
lang_file="languages.csv"
hier_file="hierarchy.csv"
feat_file="featureCodes.csv"
altname_file="altNames.csv"
post_file="allPostalCodes.csv"
# Column Values
#geocols="id, name, asciiname, altnames, lat, long, featclass, featcode, countrycode, cc2, admin1, admin2, admin3, admin4, population, elev, dem, tzone, moddate"

echo "======================================================================================"
echo "                                                                                      "
echo "                                Downloading Geonames Data                             "
echo "                                                                                      "
echo "======================================================================================"



echo "STARTING DATA DOWNLOAD !!"
# Checks if a download folder has been specified otherwise checks if the default download folder
# exists and if it doesn't then creates it.
if { [ "$3" != "" ]; } then
    if [ ! -d "$3" ]; then
        echo "Temporary download data folder $3 doesn't exists. Creating it."
        mkdir -p "$working_dir/$3"
    fi
    # Changes the default download folder to the one specified by the user.
    download_folder="$working_dir/$3"
    echo "Changed defuault download folder to $download_folder"

    # Creates default download folder
    if [ ! -d "$download_folder" ]; then
        echo "Temporary download data folder '$download_folder' doesn't exists. Creating it."
        mkdir -p "$download_folder"
	fi
else 
	# Creates Save folder
	if [ ! -d "$save_dir" ]; then
		echo "Save folder $save_dir doesn't exist. Creating it."
		mkdir -p "$save_dir"
	fi
fi
echo "                                                                                       "
# Dumps General data.
echo "======================================================================================"
echo "Downloading city files"
echo "                                        "
if [ ! -f $save_dir/allCities.csv ]; then
	if [ ! -d $data_dir ]; then
	    echo "Data folder does not exist. Creating it ..."
	    mkdir -p $data_dir
	fi
	if [ ! -d $cities_folder ]; then
	    echo "Cities folder does not exist. Creating it ..."
	    mkdir -p $cities_folder
	fi
	for dump in $geonamedumps; do
	    echo "Downloading $dump into $download_folder"
	    wget -c -P "$download_folder" "$geonames_general_data_repo/$dump"
	    if [ ${dump: -4} == ".zip" ]; then
		echo "Unzipping $dump into $data_dir"
		unzip "$download_folder/$dump" -d $data_dir
		awk 'BEGIN{ FS="\t"; OFS="," } {
		        rebuilt=0
		        for(i=1; i<=NF; ++i) {
		            if ($i ~ /,/ && $i !~ /^".*"$/) {
		                gsub("\"", "\"\"", $i)
		                $i = "\"" $i "\""
		                rebuilt=1
		            }
		        }
		        if (!rebuilt) { $1=$1 }
		        print
		        }' $data_dir/${dump%.*}.txt > $cities_folder/${dump%.*}.csv 
	    else
		if [ ${dump: -4} == ".txt" ]; then
		    mv "$download_folder/$dump" $data_dir
		fi
	    fi
	done
	touch $save_dir/allCities.csv
	echo "id, name, asciiname, altnames, lat, long, featclass, featcode, countrycode, cc2, admin1, admin2, admin3, admin4, population, elev, dem, tzone, moddate" >> $save_dir/allCities.csv
	cd $cities_folder
	cat *.csv | sort -u >> $save_dir/allCities.csv
	cd ..
	rm -rf $cities_folder
	echo "City File Download Completed!"
else
	echo "City files already downloaded, skipping ..."
fi
echo "                                                                                     "
echo "======================================================================================"
echo "Downloading Country Info"
echo "                                                                                     "
if [ ! -f $save_dir/$country_info ]; then
    echo "Downloading Country Info File ..." 
    wget -c -P "$working_dir" "$geonames_general_data_repo/countryInfo.txt"
	tail -n +50 "countryInfo.txt" > "countryInfo.txt.tmp" && mv "countryInfo.txt.tmp" "countryInfo.txt"

	awk 'BEGIN{ FS="\t"; OFS="," } {
			rebuilt=0
			for(i=1; i<=NF; ++i) {
				if ($i ~ /,/ && $i !~ /^".*"$/) {
					gsub("\"", "\"\"", $i)
					$i = "\"" $i "\""
					rebuilt=1
				}
			}
			if (!rebuilt) { $1=$1 }            
			print
			}'  countryInfo.txt > $save_dir/$country_info  
	echo "Completed Country Info Download!"
	rm countryInfo.txt
else
	echo "Country info already downloaded, skipping ..."
fi 
echo "      "
echo "======================================================================================"
echo "Downloading Admin Division Files"
echo "                                                                                     "
if [ ! -f $save_dir/$admin_file ]; then
	if [ ! -d $admin_folder ]; then
		echo "No Admin Folder, creating now ... "
		mkdir -p $admin_folder
	fi
	for dump in $admindumps; do 
		echo "Downloading $dump into $data_dir"
		wget -c -P "$data_dir" "$geonames_general_data_repo/$dump"
		awk 'BEGIN{ FS="\t"; OFS="," } {
		        rebuilt=0
		        for(i=1; i<=NF; ++i) {
		            if ($i ~ /,/ && $i !~ /^".*"$/) {
		                gsub("\"", "\"\"", $i)
		                $i = "\"" $i "\""
		                rebuilt=1
		            }
		        }
		        if (!rebuilt) { $1=$1 }
		        print
		        }' $data_dir/${dump%.*}.txt > $admin_folder/${dump%.*}.csv
	done
	touch $save_dir/$admin_file 
	echo "code, name, asciiname, id" >> $save_dir/$admin_file
	cd $admin_folder
	cat *.csv | sort -u >> $save_dir/$admin_file
	cd ..
	rm -rf $admin_folder
	echo "Admin Divions files downloaded and formatted !"
else
	echo "Admin Division files already downloaded, skipping ..."
fi

echo "      "
echo "======================================================================================"
echo "Downloading Timezone and Language files !"
echo "                                                                                     "
for dump in $tz_lang; do
	if [ ! -f $save_dir/${dump%.*}.csv ]; then
		echo "Downloading $dump into $data_dir"
		wget -c -P "$data_dir" "$geonames_general_data_repo/$dump"
		awk 'BEGIN{ FS="\t"; OFS="," } {
					rebuilt=0
					for(i=1; i<=NF; ++i) {
						if ($i ~ /,/ && $i !~ /^".*"$/) {
							gsub("\"", "\"\"", $i)
							$i = "\"" $i "\""
							rebuilt=1
						}
					}
					if (!rebuilt) { $1=$1 }
					print
					}' $data_dir/${dump%.*}.txt > $save_dir/${dump%.*}.csv
		echo "Completed $dump download !"
		echo "                          "
	else
		echo "$dump File already downloaded, skipping ..."
	fi
done
echo "           "
echo "Completed Timezone and Language file Donloads"

echo "      "
echo "======================================================================================"
echo "Downloading Hiearchy File !"
echo "                                                                                     "
if [ ! -f $save_dir/$hier_file ]; then 
	echo "Downloading $hier_dump into $download_folder"
	wget -c -P "$download_folder" "$geonames_general_data_repo/$hier_dump"
	echo "Unzipping $hier_dump into $data_dir"
	unzip "$download_folder/$hier_dump" -d $data_dir
	rm -f $download_folder/$hier_dump
	awk 'BEGIN{ FS="\t"; OFS="," } {
			rebuilt=0
			for(i=1; i<=NF; ++i) {
				if ($i ~ /,/ && $i !~ /^".*"$/) {
					gsub("\"", "\"\"", $i)
					$i = "\"" $i "\""
					rebuilt=1
				}
			}
			if (!rebuilt) { $1=$1 }
			print
			}' $data_dir/${hier_dump%.*}.txt > $save_dir/${hier_file%.*}.txt
	touch $save_dir/$hier_file
	echo "parentID,childID,type" >> $save_dir/$hier_file
	cat $save_dir/${hier_file%.*}.txt >> $save_dir/$hier_file
	rm -f $save_dir/${hier_file%.*}.txt
	

	echo "Downloaded Hierarchy File !"
else
	echo "Hierarchy file already downloaded, skipping ..."
fi

echo "                                                                                     "
echo "======================================================================================"
echo "Downloading Feature Code File !"
echo "                                                                                     "

if [ ! -f $save_dir/$feat_file ]; then
	echo "Downloading $feat_dump into $data_dir"
	wget -c -P "$data_dir" "$geonames_general_data_repo/$feat_dump"
	awk 'BEGIN{ FS="\t"; OFS="," } {
					rebuilt=0
					for(i=1; i<=NF; ++i) {
						if ($i ~ /,/ && $i !~ /^".*"$/) {
							gsub("\"", "\"\"", $i)
							$i = "\"" $i "\""
							rebuilt=1
						}
					}
					if (!rebuilt) { $1=$1 }
					print
					}' $data_dir/${feat_dump%.*}.txt > $save_dir/${feat_dump%.*}.txt
	touch $save_dir/$feat_file
	echo "featCode,featName,featDescription" >> $save_dir/$feat_file
	cat $save_dir/${feat_dump%.*}.txt >> $save_dir/$feat_file
	rm -f $save_dir/${feat_dump%.*}.txt
	echo "Feature download to $feat_file completed !"
else
	echo "Feature codes already downloaded, skipping ..."
fi


echo "                                                                                     "
echo "====================================================================================="
echo "Downloading Alternate Names File !"
echo "                                                                                     "

if [ ! -f $save_dir/$altname_file ]; then
	echo "Downloading $altname into $download_folder"
	wget -c -P "$download_folder" "$geonames_general_data_repo/$altname_dump"
	echo "Unzipping $altname into $data_dir"
	unzip -j "$download_folder/$altname_dump" "${altname_dump%.*}.txt" -d $data_dir
	rm -f $download_folder/$altname_dump
	awk 'BEGIN{ FS="\t"; OFS="," } {
					rebuilt=0
					for(i=1; i<=NF; ++i) {
						if ($i ~ /,/ && $i !~ /^".*"$/) {
							gsub("\"", "\"\"", $i)
							$i = "\"" $i "\""
							rebuilt=1
						}
					}
					if (!rebuilt) { $1=$1 }
					print
					}' $data_dir/${altname_dump%.*}.txt > $save_dir/${altname_dump%.*}.txt
	touch $save_dir/$altname_file
	echo "altnameId,id,isoLang,altname,isPreferredName,isShortName,isColloquial,isHistoric,fromDate,toDate" >> $save_dir/$altname_file
	cat $save_dir/${altname_dump%.*}.txt >> $save_dir/$altname_file
	rm -f $save_dir/${altname_dump%.*}.txt
	echo "Alternate names downloaded to $altname_file !"
else
	echo "Alternate names already downloaded, skipping ..."
fi

echo "                                                                                     "
echo "====================================================================================="
echo "Downloading All Country Postal Codes File !"
echo "                                                                                     "
if [ ! -f $save_dir/$post_file ]; then 
	echo "Downloading $post_dump into $download_folder"
	wget -c -P "$download_folder" "$geonames_general_data_repo/$post_dump"
	echo "Unzipping $post_dump into $data_dir"
	unzip "$download_folder/$post_dump" -d $data_dir
	rm -f $download_folder/$post_dump
	awk 'BEGIN{ FS="\t"; OFS="," } {
			rebuilt=0
			for(i=1; i<=NF; ++i) {
				if ($i ~ /,/ && $i !~ /^".*"$/) {
					gsub("\"", "\"\"", $i)
					$i = "\"" $i "\""
					rebuilt=1
				}
			}
			if (!rebuilt) { $1=$1 }
			print
			}' $data_dir/${post_dump%.*}.txt > $save_dir/${post_file%.*}.txt
	touch $save_dir/$post_file
	echo "id, name, asciiname, altnames, lat, long, featclass, featcode, countrycode, cc2, admin1, admin2, admin3, admin4, population, elev, dem, tzone, moddate" >> $save_dir/$post_file
	cat $save_dir/${post_file%.*}.txt >> $save_dir/$post_file
	rm -f $save_dir/${post_file%.*}.txt
	echo "Downloaded Postal Codes File !"
else
	echo "Postal Codes already downloaded, skipping ..."
fi
echo "                                                                                     "
echo "====================================================================================="
echo "Downloading Boundaries Json File !"
echo "                                                                                     "
if [ ! -f $save_dir/${geojson_dump%.*} ]; then
	echo ${geojson_dump%.*}
	echo "Downloading $geojson_dump into $download_folder"
	wget -c -P "$download_folder" "$geonames_general_data_repo/$geojson_dump"
	echo "Unzipping $geojson_dump into $data_dir"
	unzip "$download_folder/$geojson_dump" -d $save_dir
	rm -f $download_folder/$geojson_dump
	echo "Downloaded Boundary Data File Complete !"
else
	echo "Boundary Data File Already Exists, Skipping ... "
fi
echo "                                                                                     "
echo "====================================================================================="
echo "                                                                                     "
echo "                      Completed Download, Removing Extra Files !                     "
echo "                                                                                     "
echo "====================================================================================="
rm -rf $admin_folder
rm -rf $data_dir
echo "                                                                                     "
echo "Script Completed, Enjoy !"
echo "                                                                                     "