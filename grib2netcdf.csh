#! /bin/csh

# This script can be used to transform grib file to netcdf file using 'ncl_convert2nc' command
# Ex) /data2/dynamo/D1D10010000100100001.grb1 -> /data2/dynamo/20111001-20120331/2011100100.nc

set prefix = "D1D"
set fn1 = "00"
set fn2 = "001"
foreach year (2011)
foreach mon (10 11 12)
foreach day (01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)

cd /data2/dynamo/$year$mon$day
foreach hr (00 06 12 18)
ncl_convert2nc $prefix$mon$day$hr$fn1$mon$day$hr$fn2.grb1
mv $prefix$mon$day$hr$fn1$mon$day$hr$fn2.nc /data2/dynamo/20111001-20120331/$year$mon$day$hr.nc
rm $prefix$mon$day$hr$fn1$mon$day$hr$fn2.grb1

end

end
end
end

