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
   pg@long_name = "zonal advection of u by u"

   diro = "../momentum/"
   filo = "ududx.nc"
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

   varNames = (/"ududx" /)
   varTypes = (/"float" /)
   filevardef(fout,varNames,varTypes,(/"time","level", "lat", "lon"/))

  filevarattdef(fout,"ududx" ,pg)
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
    
     u  = taget->U_GDS0_ISBL
     v  = taget->V_GDS0_ISBL

;------------------------------------------------------------
;    input array must be on a global grid
;    input grid must be in ascending latitude order (S==>N)
;------------------------------------------------------------
  u = u(:,::-1,:)     ; reorder the gridded data and coordinate variables

;-----------------------------------------------------------
; create arrays to hold output, same size and type as input
; this procedure will overwrite values in u_grad_lon and u_grad_lat
;-----------------------------------------------------------
      u_grad_lon = u
      u_grad_lat = u

  gradsf (u, u_grad_lon, u_grad_lat)

  u_grad_lon@long_name = "longitudinal gradient"
  u_grad_lat@long_name = "latitudinal gradient"
  u_grad_lat@units     = "m/s/m"
  u_grad_lon@units     = "m/s/m"

 u = u(:,::-1,:)     ; reorder the gridded data and coordinate variables
 u_grad_lon = u_grad_lon(:,::-1,:)
 u_grad_lat = u_grad_lat(:,::-1,:)

 u_grad_lon=u*u_grad_lon

  pg(i,:,:,:) = (/u_grad_lon(:,{nlat:slat},{wlon:elon})/)

  delete(taget)

  
  end do
 print("done do loop")

fout->ududx  = (/pg/)

    end
