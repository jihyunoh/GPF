   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

    begin

  ; select 40E-160E, 15S-15N
   ny = 121
   nx = 481
   nlev = 25
   slat = -15.0
   nlat = 15.0
   wlon = 400.0
   elon=520.0

  syyyy = 2011
  smm = 10
  sdd = 01
  shh = 00

  eyyyy = 2012
  emm = 03
  edd = 31
  ehh = 18

   tt = yyyymmddhh_time(2011,2012,6,"integer")
   tim = tt({2011100100:2012033118})


  timeUnits = "hours since 1800-01-01 00:00:00"

  firstTime = ut_inv_calendar( syyyy, smm, sdd, shh, 0, 0, timeUnits, 0 )
  lastTime = ut_inv_calendar( eyyyy, emm, edd, ehh, 0, 0, timeUnits, 0 )

  duration = lastTime - firstTime
  nTimes = 1 + doubletoint( duration / 6 )
  time = firstTime + fspan( 0, duration, nTimes )
  ntt = dimsizes(time)
  time@units = timeUnits
  time@long_name = "initial time"
  time@delta_t = "0000-00-00 06:00:00"
  time@first_time = "2011-10-01 00:00:00"
  time@last_time = "2012-03-31 18:00:00"


  lon = fspan(wlon,elon,nx)
  lon@units              = "degrees_east"
  lon@long_name          = "longitude"
  lon@grid_resolution    = "0.5_degrees"
  lon@delta_x            = 0.5
  lon@actual_range       = (/400.,520./)

   lat = fspan(nlat,slat,ny)
  lat@units              = "degrees_north"
  lat@long_name          = "latitude"
  lat@grid_resolution    = "0.5_degrees"
  lat@delta_y            = 0.5
  lat@actual_range       = (/-15.,15./)

   level = (/1,2,3,5,7,10,20,30,50,70,100,150,200,250,300,400,500,600,700,800,850,900,925,950,1000/)   ; pressure (hPa)

   level@units = "hPa"

   pg = new((/ntt,nlev,ny,nx/),"float",1e20)

   pg!0 = "time"
   pg!1 = "level"
   pg!2 = "lat"
   pg!3 = "lon"

   pg@units = "m/sec/sec"
   pg@long_name = "vertical advection of u by w"

   diro = "../momentum/"
   filo = "wdudp.nc"
   system("rm " + diro + filo)
   fout = addfile (diro + filo, "c")
   setfileoption(fout,"DefineMode",True)

;===================================================================
; create global attributes of the file
;===================================================================
  fAtt               = True            ; assign file attributes
  fAtt@title         = "NCL Efficient Approach to netCDF Creation"
  fAtt@source_file   =  "original-file.nc"
  fAtt@Conventions   = "None"
  fAtt@creation_date = systemfunc ("date")
  fileattdef( fout, fAtt )            ; copy file attributes


;===================================================================
; predefine the coordinate variables and their dimensionality
; Note: to get an UNLIMITED record dimension, we set the dimensionality
; to -1 (or the actual size) and set the dimension name to True.
;===================================================================
   dimNames = (/"time","level", "lat", "lon"/)
   dimSizes = (/ ntt   , nlev,  ny,  nx /)
   dimUnlim = (/ False , False, False, False/)
   filedimdef(fout,dimNames,dimSizes,dimUnlim)

   filevardef(fout, "time" ,"double","time")
   filevardef(fout, "level" ,"integer","level")
   filevardef(fout, "lat" ,"float","lat")
   filevardef(fout, "lon" ,"float","lon")

   varNames = (/"wdudp" /)
   varTypes = (/"float" /)
   filevardef(fout,varNames,varTypes,(/"time","level", "lat", "lon"/))

  filevarattdef(fout,"wdudp" ,pg)
  filevarattdef( fout, "time", time )
  filevarattdef( fout, "level", level )
  filevarattdef( fout, "lat", lat )
  filevarattdef( fout, "lon", lon )


  fout->time = (/time/)
  fout->level = (/level/)
  fout->lat = (/lat/)
  fout->lon = (/lon/)



    do i=0,ntt-1
    fnm = sprinti("%0.10i",tim(i))
    taget=addfile("../20111001-20120331/"+fnm+".nc","r")

;    dNames=getvardims(taget)
;    dSizes=getfiledimsizes(taget)
;    print(dNames+"   "+dSizes)
   
    
     u  = taget->U_GDS0_ISBL
     w  = taget->W_GDS0_ISBL
     tlat = taget->g0_lat_0
     tlon = taget->g0_lon_1
     tlev = taget->lv_ISBL2

;     printVarSummary(u)

     ntlat = dimsizes(tlat)
     ntlon = dimsizes(tlon)
     ntlev = dimsizes(tlev)

     dudp = new ((/ntlat,ntlon,ntlev/),"float",1e20)
     wadv = new ((/ntlev,ntlat,ntlon/),"float",1e20)

     dudp!0="tlat"
     dudp!1="tlon"
     dudp!2="tlev"

     wadv!0="tlev"
     wadv!1="tlat"
     wadv!2="tlon"

     wadv&tlev=tlev
     wadv&tlat=tlat
     wadv&tlon=tlon

   p    = (/1,2,3,5,7,10,20,30,50,70,100,150,200,250,300,400,500,600,700,800,850,900,925,950,1000/)   ; pressure (hPa)
      p = p*100 ;convert unit to (Pa)

  dudp = center_finite_diff(u(g0_lat_0|:,g0_lon_1|:,lv_ISBL2|:),p,False,0)
  wadv = w*dudp(tlev|:,tlat|:,tlon|:) 

  pg(i,:,:,:) = (/wadv(:,{nlat:slat},{wlon:elon})/)

  delete(taget)
  
  end do
fout->wdudp  = (/pg/)

    end
