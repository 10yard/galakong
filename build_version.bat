set version=v0.22

set zip_path="C:\Program Files\7-Zip\7z"
del releases\dkshooter_plugin_%version%.zip

copy readme.md dkshooter\ /Y
%zip_path% a releases\dkshooter_plugin_%version%.zip dkshooter
del dkshooter\readme.md /Q