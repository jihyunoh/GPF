   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
    begin
       in = addfile("../20111001-20120331/2011100200.nc","r") 

      lat = in->g0_lat_0
      lon = in->g0_lon_1
      lev = in->lv_ISBL2

     all_files = systemfunc ("ls ../20111001-20120331/20111001*.nc")
     nfile = dimsizes(all_files)
     fall      = addfiles (all_files, "r")   ; note the "s" of addfile
     ListSetType (fall, "join")       ; join

     gz  = fall[:]->Z_GDS0_ISBL
     gz!0 = "time"
     printVarSummary (gz)

;------------------------------------------------------------
;    input array must be on a global grid
;    input grid must be in ascending latitude order (S==>N) 
;------------------------------------------------------------
  gz = gz(:,:,::-1,:)     ; reorder the gridded data and coordinate variables 

;-----------------------------------------------------------
; create arrays to hold output, same size and type as input
; this procedure will overwrite values in u_grad_lon and u_grad_lat
;-----------------------------------------------------------
      gz_grad_lon = gz                
      gz_grad_lat = gz                

  gradsf (gz, gz_grad_lon, gz_grad_lat)   

  gz_grad_lon@long_name = "longitudinal gradient"
  gz_grad_lat@long_name = "latitudinal gradient"
  gz_grad_lat@units     = "m/s/m"
  gz_grad_lon@units     = "m/s/m"

 gz = gz(:,:,::-1,:)     ; reorder the gridded data and coordinate variables 
   printVarSummary(gz_grad_lon)
 gz_grad_lon = gz_grad_lon(:,:,::-1,:)  
 gz_grad_lat = gz_grad_lat(:,:,::-1,:)  


;---Open workstation and change color map
      wks = gsn_open_wks("x11","contour_map")
     res                   = True
  res@tiMainString         = "Default Color"    ; main title
  res@cnFillOn             = True               ; turn on color fill
  res@mpCenterLonF    = 180                 ; Centers the plot at 180
;  res@gsnDraw         = False               ; Do not draw plot
;  res@gsnFrame        = False               ; Do not advance frame
  res@mpMaxLatF            = 15.               ; zoom in over australia
  res@mpMinLatF            = -15.
  res@mpMaxLonF            =  80
  res@mpMinLonF            =  40.
  res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res@cnMinLevelValF  = -0.001			; set the minimum contour level
  res@cnMaxLevelValF  = 0.001			; set the maximum contour level
  res@cnLevelSpacingF = 0.0002			; set the interval between contours

;  res@gsnCenterString      = lev({850})          ; level nearest 850
  plot = gsn_csm_contour_map_ce(wks,gz_grad_lon(0,{850},:,:),res)
;
;
;



    end
