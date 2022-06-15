set version=v1.1

set zip_path="C:\Program Files\7-Zip\7z"
del releases\galakong_plugin_%version%.zip

copy readme.md galakong\ /Y
%zip_path% a releases\galakong_plugin_%version%.zip galakong
del galakong\readme.md /Q