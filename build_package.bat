echo ----------------------------------------------------------------------------------------------
echo  Package the dkshooter plugin 
echo ----------------------------------------------------------------------------------------------
copy readme.md dkshooter\ /Y

echo **** package into a release ZIP getting the version from version.txt
set /p version=<VERSION
set zip_path="C:\Program Files\7-Zip\7z"
del releases\dkshooter_plugin_%version%.zip
%zip_path% a releases\dkshooter_plugin_%version%.zip dkshooter