; Specify the location of your NCL as $NCARG_ROOT in your .cshrc for csh users
; Ex) setenv NCARG_ROOT /usr/local/ncarg

   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

    begin

  ; Select your domain 
  ; Ex)40E-160E, wlat = 360+40 (western longitudinal boundary), elon = 360+160 (eastern longitudinal boundary)
  ; 15S-15N, slat = -15 (southern latitudinal boundary) nlat = 15 (northern latitudinal boundary)
  
   slat = -15.0
   nlat = 15.0
   wlon = 400.0
   elon=520.0
  
  ; Specify the number of grids in longitudinal (nx) & latitudinal (ny) direction for your selected domain 
   ny = 121
   nx = 481

  ; spatial interval (ex: 0.25 degree)
  dx = 0.25
  dy = 0.25
   
  ; Specify the number of vertical levels
   nlev = 25

  ; Give your pressure level (hPa)
   level = (/1,2,3,5,7,10,20,30,50,70,100,150,200,250,300,400,500,600,700,800,850,900,925,950,1000/)  
   level@units = "hPa"

  ; Starting date Oct-01-2011 00 UTC
  syyyy = 2011
  smm = 10
  sdd = 01
  shh = 00
  
  ; Ending date Mar-31-2012 18 UTC
  eyyyy = 2012
  emm = 03
  edd = 31
  ehh = 18

  sdate = syyyy*1000000+smm*10000+sdd*100+shh
  edate = eyyyy*1000000+emm*10000+edd*100+ehh

  ; time interval in hour (ex: 6-hourly data)
  dt = 6

  tt = yyyymmddhh_time(syyyy,eyyyy,dt,"integer")
  tim = tt({sdate:edate})

  timeUnits = "hours since 1800-01-01 00:00:00"

  firstTime = ut_inv_calendar( syyyy, smm, sdd, shh, 0, 0, timeUnits, 0 )
  lastTime = ut_inv_calendar( eyyyy, emm, edd, ehh, 0, 0, timeUnits, 0 )

  duration = lastTime - firstTime
  nTimes = 1 + doubletoint( duration / dt )
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
  lon@grid_resolution    = "0.25_degrees"
  lon@delta_x            =  dx
  lon@actual_range       = (/wlon,elon/)

   lat = fspan(nlat,slat,ny)
  lat@units              = "degrees_north"
  lat@long_name          = "latitude"
  lat@grid_resolution    = "0.25_degrees"
  lat@delta_y            = dy
  lat@actual_range       = (/slat,nlat/)
  

   pg = new((/ntt,nlev,ny,nx/),"float",1e20)

   pg!0 = "time"
   pg!1 = "level"
   pg!2 = "lat"
   pg!3 = "lon"

   pg@units = "m/sec/sec"
   pg@long_name = "zonal wind tendency"
   
; Give the path to the directory that you want to save the output   
   diro = "../momentum/"
   
   filo = "dudt.nc"
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

   varNames = (/"U_ten" /)
   varTypes = (/"float" /)
   filevardef(fout,varNames,varTypes,(/"time","level", "lat", "lon"/))

  filevarattdef(fout,"U_ten" ,pg)
  filevarattdef( fout, "time", time )
  filevarattdef( fout, "level", level )
  filevarattdef( fout, "lat", lat )
  filevarattdef( fout, "lon", lon )

  fout->time = (/time/)
  fout->level = (/level/)
  fout->lat = (/lat/)
  fout->lon = (/lon/)

;===================================================================
;Compute du/dt: use centered difference approximation except for end values.
;One-sided difference scheme is used for the end values.
;===================================================================
    do i=0,ntt-1
    print(i)

    if (i.gt.0 .and. i.lt.ntt-1) then

    fafter = sprinti("%0.10i",tim(i+1))
    fbfore = sprinti("%0.10i",tim(i-1))

; "../20111001-20120331" : is the directory where your input data in netcdf format are saved

    tafter=addfile("../20111001-20120331/"+fafter+".nc","r")
    tbfore=addfile("../20111001-20120331/"+fbfore+".nc","r")
    
    ua = tafter->U_GDS0_ISBL
    ub = tbfore->U_GDS0_ISBL

    delta = ua
    delta = (ua-ub)/(2*dt*60*60)
     
  pg(i,:,:,:) = (/delta(:,{nlat:slat},{wlon:elon})/)

  delete(tafter)
  delete(tbfore)

  else if (i.eq.0) then 
    fafter = sprinti("%0.10i",tim(i+1))
    fbfore = sprinti("%0.10i",tim(i))
    tafter=addfile("../20111001-20120331/"+fafter+".nc","r")
    tbfore=addfile("../20111001-20120331/"+fbfore+".nc","r")
    
    ua = tafter->U_GDS0_ISBL
    ub = tbfore->U_GDS0_ISBL

    delta = ua
    delta = (ua-ub)/(6*60*60)
     
  pg(i,:,:,:) = (/delta(:,{nlat:slat},{wlon:elon})/)

  delete(tafter)
  delete(tbfore)

  else 
    fafter = sprinti("%0.10i",tim(i))
    fbfore = sprinti("%0.10i",tim(i-1))
    tafter=addfile("../20111001-20120331/"+fafter+".nc","r")
    tbfore=addfile("../20111001-20120331/"+fbfore+".nc","r")
    
    ua = tafter->U_GDS0_ISBL
    ub = tbfore->U_GDS0_ISBL

    delta = ua
    delta = (ua-ub)/(dt*60*60)
     
  pg(i,:,:,:) = (/delta(:,{nlat:slat},{wlon:elon})/)

  delete(tafter)
  delete(tbfore)

  end if
  end if

  end do

fout->U_ten  = (/pg/)

    end
