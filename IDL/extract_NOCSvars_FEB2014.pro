pro extract_NOCSvars_FEB2014

; UDPATED FEB 2016
; Now reads in new files which contain EVERYTHING!
; One file per year


mdi=-1e30
styr=1970
edyr=2015
clst=1981-styr
cled=2010-styr
nyrs=(edyr+1)-styr
nmons=nyrs*12
int_mons=indgen(nmons)

nlons=360
nlats=180
lons=findgen(nlons)-179.5
lats=(findgen(nlats))-89.5

Nnlons=72
Nnlats=36
NNNlons=(findgen(Nnlons)*5.)-177.5
NNNlats=(findgen(Nnlats)*5)-87.5

marinehi=fltarr(360,180,nmons)
marinehimask=make_array(360,180,nmons,/float,value=mdi)
marinehiQ=make_array(360,180,nmons,/float,value=mdi)
marinelow=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
marinelowmask=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
marinelowQ=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
Amarinehi=fltarr(360,180,nmons)
Amarinehimask=make_array(360,180,nmons,/float,value=mdi)
AmarinehiQ=make_array(360,180,nmons,/float,value=mdi)
Amarinelow=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
Amarinelowmask=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
AmarinelowQ=make_array(Nnlons,Nnlats,nmons,/float,value=mdi)
bluemask=fltarr(360,180)
Qmask=make_array(360,180,nmons,/float,value=mdi)

; read in NOCS high quality mask and regrid to 5by5 from 1by1
indir='/data/local/hadkw/HADCRUH2/UPDATE2015/OTHERDATA/NOCS/'
;lons -179.5 to 179.5
;lats -89.5 to 89.5
inn=NCDF_OPEN(indir+'mask_for_kate.nc')
varid=NCDF_VARID(inn,'BLUE')	;1=good
NCDF_VARGET,inn,varid,bluemask
NCDF_CLOSE,inn

; read in NOCS
;lons -179.5 to 179.5
;lats -89.5 to 89.5
stmn=0
edmn=11
indir='/data/local/hadkw/HADCRUH2/UPDATE2015/OTHERDATA/NOCS/'
nocsfil='.monthly.fluxes.nc'
FOR yy=0,nyrs-1 DO BEGIN
  print,yy
  spawn,'gunzip -c '+indir+strcompress((styr+yy),/remove_all)+nocsfil+'.gz > tmpfil'
  inn=NCDF_OPEN('tmpfil')
  varid=NCDF_VARID(inn,'wspd')	;1=good
  uncvarid=NCDF_VARID(inn,'wspd_err_total')	;1=good
;  varid=NCDF_VARID(inn,'qair')	;1=good
;  uncvarid=NCDF_VARID(inn,'qair_err_total')	;1=good
  NCDF_VARGET,inn,varid,qc1by1
  NCDF_VARGET,inn,uncvarid,uncs
  NCDF_CLOSE,inn
  spawn,'rm tmpfil'
  marinehi(*,*,stmn:edmn)=qc1by1
  Qmask(*,*,stmn:edmn)=uncs
  stmn=stmn+12
  edmn=edmn+12
ENDFOR

bads=WHERE(marinehi LE -9999.,count)
IF (count GT 0) THEN marinehi(bads)=mdi
bads=WHERE(Qmask LE -9999.,count)
IF (count GT 0) THEN Qmask(bads)=mdi

; mask NOCS data by high quality - blue mask
FOR i=0,nlons-1 DO BEGIN
  FOR j=0,nlats-1 DO BEGIN
    IF (bluemask(i,j) EQ 1) THEN marinehimask(i,j,*)=marinehi(i,j,*)
  ENDFOR
ENDFOR

; normalise to 1981-2010
FOR i=0,nlons-1 DO BEGIN
  print,'LON: ',i
  FOR j=0,nlats-1 DO BEGIN
    subarr=marinehi(i,j,*)
    subarrmask=marinehimask(i,j,*)
    gots=WHERE(subarr NE mdi,count)
    gotsM=WHERE(subarrmask NE mdi,countM)

    IF (count GT nmons/2) THEN BEGIN	; no point if there isn't much data
      monarr=REFORM(subarr,12,nyrs)
      FOR mm=0,11 DO BEGIN
        submon=monarr(mm,*)
	gots=WHERE(submon NE mdi,count)
	IF (count GT 20) THEN BEGIN
	  clims=submon(clst:cled)
	  gotclims=WHERE(clims NE mdi,count)
	  IF (count GT 15) THEN submon(gots)=submon(gots)-MEAN(clims(gotclims))
	ENDIF
	monarr(mm,*)=submon
      ENDFOR
      Amarinehi(i,j,*)=REFORM(monarr,nmons)
    ENDIF 

    IF (countM GT nmons/2) THEN BEGIN	; no point if there isn't much data
      monarr=REFORM(subarrmask,12,nyrs)
      FOR mm=0,11 DO BEGIN
        submon=monarr(mm,*)
	gots=WHERE(submon NE mdi,count)
	IF (count GT 20) THEN BEGIN
	  clims=submon(clst:cled)
	  gotclims=WHERE(clims NE mdi,count)
	  IF (count GT 15) THEN submon(gots)=submon(gots)-MEAN(clims(gotclims))
	ENDIF ELSE submon(*)=mdi
	monarr(mm,*)=submon
      ENDFOR
      Amarinehimask(i,j,*)=REFORM(monarr,nmons)
    ENDIF 

    ; mask NOCS data by high quality - anoms>2q mask
    gots=WHERE((Amarinehi(i,j,*) GE 2*Qmask(i,j,*)) AND (Qmask(i,j,*) NE mdi),count)
    IF (count GT 0) THEN BEGIN
      marinehiQ(i,j,gots)=marinehi(i,j,gots)
      AmarinehiQ(i,j,gots)=Amarinehi(i,j,gots)
    ENDIF
  ENDFOR
ENDFOR

;; reverse lats
;lats=REVERSE(lats)
;NNNlats=REVERSE(NNNlats)
;marinehi=REVERSE(marinehi,2)
;marinehiQ=REVERSE(marinehiQ,2)
;marinehimask=REVERSE(marinehimask,2)

; output gridded product
wilma=NCDF_CREATE('/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/NOCSv2.0_oceanW_1by1_FEB2016.nc',/clobber)
;wilma=NCDF_CREATE('/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/NOCSv2.0_oceanq_1by1_FEB2016.nc',/clobber)

tid=NCDF_DIMDEF(wilma,'time',nmons)
clmid=NCDF_DIMDEF(wilma,'month',12)
latid=NCDF_DIMDEF(wilma,'latitude',nlats)
lonid=NCDF_DIMDEF(wilma,'longitude',nlons)
  
timesvar=NCDF_VARDEF(wilma,'times',[tid],/SHORT)
latsvar=NCDF_VARDEF(wilma,'lat',[latid],/FLOAT)
lonsvar=NCDF_VARDEF(wilma,'lon',[lonid],/FLOAT)
absvar=NCDF_VARDEF(wilma,'w_abs',[lonid,latid,tid],/FLOAT)
absvarmask=NCDF_VARDEF(wilma,'mask_w_abs',[lonid,latid,tid],/FLOAT)
absvarQ=NCDF_VARDEF(wilma,'Q_w_abs',[lonid,latid,tid],/FLOAT)
anomvar=NCDF_VARDEF(wilma,'w_anoms',[lonid,latid,tid],/FLOAT)
anomvarmask=NCDF_VARDEF(wilma,'mask_w_anoms',[lonid,latid,tid],/FLOAT)
anomvarQ=NCDF_VARDEF(wilma,'Q_w_anoms',[lonid,latid,tid],/FLOAT)
;absvar=NCDF_VARDEF(wilma,'q_abs',[lonid,latid,tid],/FLOAT)
;absvarmask=NCDF_VARDEF(wilma,'mask_q_abs',[lonid,latid,tid],/FLOAT)
;absvarQ=NCDF_VARDEF(wilma,'Q_q_abs',[lonid,latid,tid],/FLOAT)
;anomvar=NCDF_VARDEF(wilma,'q_anoms',[lonid,latid,tid],/FLOAT)
;anomvarmask=NCDF_VARDEF(wilma,'mask_q_anoms',[lonid,latid,tid],/FLOAT)
;anomvarQ=NCDF_VARDEF(wilma,'Q_q_anoms',[lonid,latid,tid],/FLOAT)

NCDF_ATTPUT,wilma,'times','long_name','time'
NCDF_ATTPUT,wilma,'times','units','months beginning Jan 1970'
NCDF_ATTPUT,wilma,'times','axis','T'
NCDF_ATTPUT,wilma,'times','calendar','gregorian'
NCDF_ATTPUT,wilma,'times','valid_min',0.
NCDF_ATTPUT,wilma,'lat','long_name','Latitude'
NCDF_ATTPUT,wilma,'lat','units','Degrees'
NCDF_ATTPUT,wilma,'lat','valid_min',-90.
NCDF_ATTPUT,wilma,'lat','valid_max',90.
NCDF_ATTPUT,wilma,'lon','long_name','Longitude'
NCDF_ATTPUT,wilma,'lon','units','Degrees'
NCDF_ATTPUT,wilma,'lon','valid_min',-180.
NCDF_ATTPUT,wilma,'lon','valid_max',180.

NCDF_ATTPUT,wilma,anomvar,'long_name','Wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvar,'units','m/s'
;NCDF_ATTPUT,wilma,anomvar,'long_name','Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvar,'units','g/kg'
NCDF_ATTPUT,wilma,anomvar,'axis','T'
valid=WHERE(Amarinehi NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(Amarinehi(valid))
  max_t=MAX(Amarinehi(valid))
  NCDF_ATTPUT,wilma,anomvar,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvar,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvar,'missing_value',mdi

NCDF_ATTPUT,wilma,absvar,'long_name','Wind speed monthly mean (1981-2010)'
NCDF_ATTPUT,wilma,absvar,'units','m/s'
;NCDF_ATTPUT,wilma,absvar,'long_name','Specific humidity monthly mean (1981-2010)'
;NCDF_ATTPUT,wilma,absvar,'units','g/kg'
NCDF_ATTPUT,wilma,absvar,'axis','T'
valid=WHERE(marinehi NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinehi(valid))
  max_t=MAX(marinehi(valid))
  NCDF_ATTPUT,wilma,absvar,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvar,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvar,'missing_value',mdi

NCDF_ATTPUT,wilma,absvarmask,'long_name','Marine High Quality Mask wind speed monthly mean'
NCDF_ATTPUT,wilma,absvarmask,'units','m/s'
;NCDF_ATTPUT,wilma,absvarmask,'long_name','Marine high quality masked Specific humidity monthly mean'
;NCDF_ATTPUT,wilma,absvarmask,'units','g/kg'
NCDF_ATTPUT,wilma,absvarmask,'axis','T'
valid=WHERE(marinehimask NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinehimask(valid))
  max_t=MAX(marinehimask(valid))
  NCDF_ATTPUT,wilma,absvarmask,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvarmask,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvarmask,'missing_value',mdi

NCDF_ATTPUT,wilma,anomvarmask,'long_name','Marine High Quality Mask wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvarmask,'units','m/s'
;NCDF_ATTPUT,wilma,anomvarmask,'long_name','Marine high quality masked Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvarmask,'units','g/kg'
NCDF_ATTPUT,wilma,anomvarmask,'axis','T'
valid=WHERE(Amarinehimask NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(Amarinehimask(valid))
  max_t=MAX(Amarinehimask(valid))
  NCDF_ATTPUT,wilma,anomvarmask,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvarmask,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvarmask,'missing_value',mdi

NCDF_ATTPUT,wilma,absvarQ,'long_name','Marine High Quality Q wind speed monthly mean'
NCDF_ATTPUT,wilma,absvarQ,'units','m/s'
;NCDF_ATTPUT,wilma,absvarQ,'long_name','Marine High Quality Q Specific humidity monthly mean'
;NCDF_ATTPUT,wilma,absvarQ,'units','g/kg'
NCDF_ATTPUT,wilma,absvarQ,'axis','T'
valid=WHERE(marinehiQ NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinehiQ(valid))
  max_t=MAX(marinehiQ(valid))
  NCDF_ATTPUT,wilma,absvarQ,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvarQ,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvarQ,'missing_value',mdi

NCDF_ATTPUT,wilma,anomvarQ,'long_name','Marine High Quality Q wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvarQ,'units','m/s'
;NCDF_ATTPUT,wilma,anomvarQ,'long_name','Marine High Quality Q Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvarQ,'units','g/kg'
NCDF_ATTPUT,wilma,anomvarQ,'axis','T'
valid=WHERE(AmarinehiQ NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(AmarinehiQ(valid))
  max_t=MAX(AmarinehiQ(valid))
  NCDF_ATTPUT,wilma,anomvarQ,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvarQ,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvarQ,'missing_value',mdi

current_time=SYSTIME()
NCDF_ATTPUT,wilma,/GLOBAL,'file_created',STRING(current_time)
NCDF_CONTROL,wilma,/ENDEF

int_mons=indgen(nmons)
NCDF_VARPUT, wilma,timesvar, int_mons
NCDF_VARPUT, wilma,latsvar, lats
NCDF_VARPUT, wilma,lonsvar, lons
NCDF_VARPUT, wilma,absvar,marinehi
NCDF_VARPUT, wilma,absvarmask,marinehimask
NCDF_VARPUT, wilma,absvarQ,marinehiQ
NCDF_VARPUT, wilma,anomvar,Amarinehi
NCDF_VARPUT, wilma,anomvarmask,Amarinehimask
NCDF_VARPUT, wilma,anomvarQ,AmarinehiQ

NCDF_CLOSE,wilma

; regrid to low res
stln=0
edln=4
stlt=0
edlt=4
FOR i=0,Nnlons-1 DO BEGIN
  stlt=0
  edlt=4
  FOR j=0,Nnlats-1 DO BEGIN
    FOR mm=0,nmons-1 DO BEGIN
      subarr=marinehi(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN marinelow(i,j,mm)=MEAN(subarr(gots))
      subarr=marinehiQ(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN marinelowQ(i,j,mm)=MEAN(subarr(gots))
      subarr=marinehimask(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN marinelowmask(i,j,mm)=MEAN(subarr(gots))
      subarr=Amarinehi(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN Amarinelow(i,j,mm)=MEAN(subarr(gots))
      subarr=AmarinehiQ(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN AmarinelowQ(i,j,mm)=MEAN(subarr(gots))
      subarr=Amarinehimask(stln:edln,stlt:edlt,mm)
      gots=WHERE(subarr NE mdi,count)
      IF (count GT 0) THEN Amarinelowmask(i,j,mm)=MEAN(subarr(gots))
    ENDFOR
    stlt=stlt+5
    edlt=edlt+5
  ENDFOR
  stln=stln+5
  edln=edln+5
ENDFOR

marinehi=0
marinehimask=0
marinehiQ=0
Amarinehi=0
Amarinehimask=0
AmarinehiQ=0

; output gridded product

wilma=NCDF_CREATE('/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/NOCSv2.0_oceanW_5by5_FEB2016.nc',/clobber)
;wilma=NCDF_CREATE('/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/NOCSv2.0_oceanq_5by5_FEB2016.nc',/clobber)
  
tid=NCDF_DIMDEF(wilma,'time',nmons)
clmid=NCDF_DIMDEF(wilma,'month',12)
latid=NCDF_DIMDEF(wilma,'latitude',Nnlats)
lonid=NCDF_DIMDEF(wilma,'longitude',Nnlons)
  
timesvar=NCDF_VARDEF(wilma,'times',[tid],/SHORT)
latsvar=NCDF_VARDEF(wilma,'lat',[latid],/FLOAT)
lonsvar=NCDF_VARDEF(wilma,'lon',[lonid],/FLOAT)
absvar=NCDF_VARDEF(wilma,'w_abs',[lonid,latid,tid],/FLOAT)
absvarmask=NCDF_VARDEF(wilma,'mask_w_abs',[lonid,latid,tid],/FLOAT)
absvarQ=NCDF_VARDEF(wilma,'Q_w_abs',[lonid,latid,tid],/FLOAT)
anomvar=NCDF_VARDEF(wilma,'w_anoms',[lonid,latid,tid],/FLOAT)
anomvarmask=NCDF_VARDEF(wilma,'mask_w_anoms',[lonid,latid,tid],/FLOAT)
anomvarQ=NCDF_VARDEF(wilma,'Q_w_anoms',[lonid,latid,tid],/FLOAT)
;absvar=NCDF_VARDEF(wilma,'q_abs',[lonid,latid,tid],/FLOAT)
;absvarmask=NCDF_VARDEF(wilma,'mask_q_abs',[lonid,latid,tid],/FLOAT)
;absvarQ=NCDF_VARDEF(wilma,'Q_q_abs',[lonid,latid,tid],/FLOAT)
;anomvar=NCDF_VARDEF(wilma,'q_anoms',[lonid,latid,tid],/FLOAT)
;anomvarmask=NCDF_VARDEF(wilma,'mask_q_anoms',[lonid,latid,tid],/FLOAT)
;anomvarQ=NCDF_VARDEF(wilma,'Q_q_anoms',[lonid,latid,tid],/FLOAT)

NCDF_ATTPUT,wilma,'times','long_name','time'
NCDF_ATTPUT,wilma,'times','units','months beginning Jan 1971'
NCDF_ATTPUT,wilma,'times','axis','T'
NCDF_ATTPUT,wilma,'times','calendar','gregorian'
NCDF_ATTPUT,wilma,'times','valid_min',0.
NCDF_ATTPUT,wilma,'lat','long_name','Latitude'
NCDF_ATTPUT,wilma,'lat','units','Degrees'
NCDF_ATTPUT,wilma,'lat','valid_min',-90.
NCDF_ATTPUT,wilma,'lat','valid_max',90.
NCDF_ATTPUT,wilma,'lon','long_name','Longitude'
NCDF_ATTPUT,wilma,'lon','units','Degrees'
NCDF_ATTPUT,wilma,'lon','valid_min',-180.
NCDF_ATTPUT,wilma,'lon','valid_max',180.

NCDF_ATTPUT,wilma,anomvar,'long_name','Wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvar,'units','m/s'
;NCDF_ATTPUT,wilma,anomvar,'long_name','Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvar,'units','g/kg'
NCDF_ATTPUT,wilma,anomvar,'axis','T'
valid=WHERE(Amarinelow NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(Amarinelow(valid))
  max_t=MAX(Amarinelow(valid))
  NCDF_ATTPUT,wilma,anomvar,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvar,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvar,'missing_value',mdi

NCDF_ATTPUT,wilma,absvar,'long_name','Wind speed monthly mean (1981-2010)'
NCDF_ATTPUT,wilma,absvar,'units','m/s'
;NCDF_ATTPUT,wilma,absvar,'long_name','Specific humidity monthly mean (1981-2010)'
;NCDF_ATTPUT,wilma,absvar,'units','g/kg'
NCDF_ATTPUT,wilma,absvar,'axis','T'
valid=WHERE(marinelow NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinelow(valid))
  max_t=MAX(marinelow(valid))
  NCDF_ATTPUT,wilma,absvar,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvar,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvar,'missing_value',mdi

NCDF_ATTPUT,wilma,absvarmask,'long_name','Marine High Quality Mask wind speed monthly mean'
NCDF_ATTPUT,wilma,absvarmask,'units','m/s'
;NCDF_ATTPUT,wilma,absvarmask,'long_name','Marine high quality masked Specific humidity monthly mean'
;NCDF_ATTPUT,wilma,absvarmask,'units','g/kg'
NCDF_ATTPUT,wilma,absvarmask,'axis','T'
valid=WHERE(marinelowmask NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinelowmask(valid))
  max_t=MAX(marinelowmask(valid))
  NCDF_ATTPUT,wilma,absvarmask,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvarmask,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvarmask,'missing_value',mdi

NCDF_ATTPUT,wilma,anomvarmask,'long_name','Marine High Quality Mask wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvarmask,'units','m/s'
;NCDF_ATTPUT,wilma,anomvarmask,'long_name','Marine high quality masked Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvarmask,'units','g/kg'
NCDF_ATTPUT,wilma,anomvarmask,'axis','T'
valid=WHERE(Amarinelowmask NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(Amarinelowmask(valid))
  max_t=MAX(Amarinelowmask(valid))
  NCDF_ATTPUT,wilma,anomvarmask,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvarmask,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvarmask,'missing_value',mdi

NCDF_ATTPUT,wilma,absvarQ,'long_name','Marine High Quality Q wind speed monthly mean'
NCDF_ATTPUT,wilma,absvarQ,'units','m/s'
;NCDF_ATTPUT,wilma,absvarQ,'long_name','Marine High Quality Q Specific humidity monthly mean'
;NCDF_ATTPUT,wilma,absvarQ,'units','g/kg'
NCDF_ATTPUT,wilma,absvarQ,'axis','T'
valid=WHERE(marinelowQ NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(marinelowQ(valid))
  max_t=MAX(marinelowQ(valid))
  NCDF_ATTPUT,wilma,absvarQ,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,absvarQ,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,absvarQ,'missing_value',mdi

NCDF_ATTPUT,wilma,anomvarQ,'long_name','Marine High Quality Q wind speed monthly mean anomaly (1981-2010)'
NCDF_ATTPUT,wilma,anomvarQ,'units','m/s'
;NCDF_ATTPUT,wilma,anomvarQ,'long_name','Marine High Quality Q Specific humidity monthly mean anomaly (1981-2010)'
;NCDF_ATTPUT,wilma,anomvarQ,'units','g/kg'
NCDF_ATTPUT,wilma,anomvarQ,'axis','T'
valid=WHERE(AmarinelowQ NE mdi, tc)
IF tc GE 1 THEN BEGIN
  min_t=MIN(AmarinelowQ(valid))
  max_t=MAX(AmarinelowQ(valid))
  NCDF_ATTPUT,wilma,anomvarQ,'valid_min',min_t(0)
  NCDF_ATTPUT,wilma,anomvarQ,'valid_max',max_t(0)
ENDIF
NCDF_ATTPUT,wilma,anomvarQ,'missing_value',mdi

current_time=SYSTIME()
NCDF_ATTPUT,wilma,/GLOBAL,'file_created',STRING(current_time)
NCDF_CONTROL,wilma,/ENDEF

int_mons=indgen(nmons)
NCDF_VARPUT, wilma,timesvar, int_mons
NCDF_VARPUT, wilma,latsvar, NNNlats
NCDF_VARPUT, wilma,lonsvar, NNNlons
NCDF_VARPUT, wilma,absvar,marinelow
NCDF_VARPUT, wilma,absvarmask,marinelowmask
NCDF_VARPUT, wilma,absvarQ,marinelowQ
NCDF_VARPUT, wilma,anomvar,Amarinelow
NCDF_VARPUT, wilma,anomvarmask,Amarinelowmask
NCDF_VARPUT, wilma,anomvarQ,AmarinelowQ

NCDF_CLOSE,wilma


global_mask = Amarinelow(*,*,0)
global_mask(*,*) = 1
nhem_mask=global_mask
shem_mask=global_mask
trop_mask=global_mask

for deg=0,Nnlats-1 DO BEGIN
  if (NNNlats(deg) LT -70.) OR (NNNlats(deg) GT 70.) THEN BEGIN
    global_mask(*,deg) = mdi
  endif
  if (NNNlats(deg) LT 20.) OR (NNNlats(deg) GT 70.) THEN BEGIN
    nhem_mask(*,deg) = mdi
  endif
  if (NNNlats(deg) LT -70.) OR (NNNlats(deg) GT -20.) THEN BEGIN
    shem_mask(*,deg) = mdi
  endif
  if (NNNlats(deg) LT -20.) OR (NNNlats(deg) GT 20.) THEN BEGIN
    trop_mask(*,deg) = mdi
  endif  
endfor

field_values=make_array(Nnlons,Nnlats,nmons,/float)	;all values or a subsection
num_val=n_elements(field_values(0,0,*))

global_mask_3d=fltarr(Nnlons,Nnlats,num_val)
nhem_mask_3d=fltarr(Nnlons,Nnlats,num_val)
shem_mask_3d=fltarr(Nnlons,Nnlats,num_val)
trop_mask_3d=fltarr(Nnlons,Nnlats,num_val)

for add=0,num_val-1 do begin
  global_mask_3d(*,*,add) = global_mask(*,*)
  nhem_mask_3d(*,*,add)=nhem_mask(*,*)
  shem_mask_3d(*,*,add)=shem_mask(*,*)
  trop_mask_3d(*,*,add)=trop_mask(*,*)
endfor

field_values(*,*,*)=Amarinelow(*,*,0:nmons-1)
print,n_elements(field_values(0,0,*))
num_val=n_elements(field_values(0,0,*))
glob_avg_ts=fltarr(num_val)
glob_avg_ts=globalmean(field_values,NNNlats,mdi,mask=global_mask_3d)

print,n_elements(glob_avg_ts)
print,max(glob_avg_ts)
print,min(glob_avg_ts)
print,glob_avg_ts(0:10)

nhem_avg_ts=fltarr(num_val)
nhem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=nhem_mask_3d)

print,n_elements(nhem_avg_ts)
print,max(nhem_avg_ts)
print,min(nhem_avg_ts)
print,nhem_avg_ts(0:10)

shem_avg_ts=fltarr(num_val)
shem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=shem_mask_3d)

print,n_elements(shem_avg_ts)
print,max(shem_avg_ts)
print,min(shem_avg_ts)
print,shem_avg_ts(0:10)

trop_avg_ts=fltarr(num_val)
trop_avg_ts=globalmean(field_values,NNNlats,mdi,mask=trop_mask_3d)

print,n_elements(trop_avg_ts)
print,max(trop_avg_ts)
print,min(trop_avg_ts)
print,trop_avg_ts(0:10)
 
 
field_values(*,*,*)=Amarinelowmask(*,*,0:nmons-1)
print,n_elements(field_values(0,0,*))
num_val=n_elements(field_values(0,0,*))
Mglob_avg_ts=fltarr(num_val)
Mglob_avg_ts=globalmean(field_values,NNNlats,mdi,mask=global_mask_3d)

print,n_elements(Mglob_avg_ts)
print,max(Mglob_avg_ts)
print,min(Mglob_avg_ts)
print,Mglob_avg_ts(0:10)

Mnhem_avg_ts=fltarr(num_val)
Mnhem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=nhem_mask_3d)

print,n_elements(Mnhem_avg_ts)
print,max(Mnhem_avg_ts)
print,min(Mnhem_avg_ts)
print,Mnhem_avg_ts(0:10)

Mshem_avg_ts=fltarr(num_val)
Mshem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=shem_mask_3d)

print,n_elements(Mshem_avg_ts)
print,max(Mshem_avg_ts)
print,min(Mshem_avg_ts)
print,Mshem_avg_ts(0:10)

Mtrop_avg_ts=fltarr(num_val)
Mtrop_avg_ts=globalmean(field_values,NNNlats,mdi,mask=trop_mask_3d)

print,n_elements(Mtrop_avg_ts)
print,max(Mtrop_avg_ts)
print,min(Mtrop_avg_ts)
print,Mtrop_avg_ts(0:10)

field_values(*,*,*)=AmarinelowQ(*,*,0:nmons-1)
print,n_elements(field_values(0,0,*))
num_val=n_elements(field_values(0,0,*))
Qglob_avg_ts=fltarr(num_val)
Qglob_avg_ts=globalmean(field_values,NNNlats,mdi,mask=global_mask_3d)

Qnhem_avg_ts=fltarr(num_val)
Qnhem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=nhem_mask_3d)

Qshem_avg_ts=fltarr(num_val)
Qshem_avg_ts=globalmean(field_values,NNNlats,mdi,mask=shem_mask_3d)

Qtrop_avg_ts=fltarr(num_val)
Qtrop_avg_ts=globalmean(field_values,NNNlats,mdi,mask=trop_mask_3d)

filename='/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/TIMESERIES/NOCSv2.0_oceanW_5by5_8110anoms_areaTS_FEB2016.nc'
unitees='m/s'
;filename='/data/local/hadkw/HADCRUH2/UPDATE2015/STATISTICS/TIMESERIES/NOCSv2.0_oceanq_5by5_8110anoms_areaTS_FEB2016.nc'
;unitees='g/kg'
file_out=NCDF_CREATE(filename,/clobber)
time_id=NCDF_DIMDEF(file_out,'time',nmons)
timvarid=NCDF_VARDEF(file_out,'time',[time_id],/DOUBLE)

glob_varid=NCDF_VARDEF(file_out,'glob_anoms',[time_id],/FLOAT)
trop_varid=NCDF_VARDEF(file_out,'trop_anoms',[time_id],/FLOAT)
nhem_varid=NCDF_VARDEF(file_out,'nhem_anoms',[time_id],/FLOAT)
shem_varid=NCDF_VARDEF(file_out,'shem_anoms',[time_id],/FLOAT)
globM_varid=NCDF_VARDEF(file_out,'glob_anoms_mask',[time_id],/FLOAT)
tropM_varid=NCDF_VARDEF(file_out,'trop_anoms_mask',[time_id],/FLOAT)
nhemM_varid=NCDF_VARDEF(file_out,'nhem_anoms_mask',[time_id],/FLOAT)
shemM_varid=NCDF_VARDEF(file_out,'shem_anoms_mask',[time_id],/FLOAT)
globQ_varid=NCDF_VARDEF(file_out,'glob_anoms_Q',[time_id],/FLOAT)
tropQ_varid=NCDF_VARDEF(file_out,'trop_anoms_Q',[time_id],/FLOAT)
nhemQ_varid=NCDF_VARDEF(file_out,'nhem_anoms_Q',[time_id],/FLOAT)
shemQ_varid=NCDF_VARDEF(file_out,'shem_anoms_Q',[time_id],/FLOAT)

NCDF_ATTPUT,file_out,timvarid,'units','months since 1970'
NCDF_ATTPUT,file_out,timvarid,'long_name','Time'
NCDF_ATTPUT,file_out,glob_varid,'units',unitees
NCDF_ATTPUT,file_out,glob_varid,'long_name','Globally Average 70S-70N'
NCDF_ATTPUT,file_out,glob_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,trop_varid,'units',unitees
NCDF_ATTPUT,file_out,trop_varid,'long_name','Tropics Average 20S-20N'
NCDF_ATTPUT,file_out,trop_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,nhem_varid,'units',unitees
NCDF_ATTPUT,file_out,nhem_varid,'long_name','Northern Hemisphere Average 20N-70N'
NCDF_ATTPUT,file_out,nhem_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,shem_varid,'units',unitees
NCDF_ATTPUT,file_out,shem_varid,'long_name','Southern Hemisphere Average 70S-20S'
NCDF_ATTPUT,file_out,shem_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,globM_varid,'units',unitees
NCDF_ATTPUT,file_out,globM_varid,'long_name','Masked Globally Average 70S-70N'
NCDF_ATTPUT,file_out,globM_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,tropM_varid,'units',unitees
NCDF_ATTPUT,file_out,tropM_varid,'long_name','Masked Tropics Average 20S-20N'
NCDF_ATTPUT,file_out,tropM_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,nhemM_varid,'units',unitees
NCDF_ATTPUT,file_out,nhemM_varid,'long_name','Masked Northern Hemisphere Average 20N-70N'
NCDF_ATTPUT,file_out,nhemM_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,shemM_varid,'units',unitees
NCDF_ATTPUT,file_out,shemM_varid,'long_name','Masked Southern Hemisphere Average 70S-20S'
NCDF_ATTPUT,file_out,shemM_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,globQ_varid,'units',unitees
NCDF_ATTPUT,file_out,globQ_varid,'long_name','Q Globally Average 70S-70N'
NCDF_ATTPUT,file_out,globQ_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,tropQ_varid,'units',unitees
NCDF_ATTPUT,file_out,tropQ_varid,'long_name','Q Tropics Average 20S-20N'
NCDF_ATTPUT,file_out,tropQ_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,nhemQ_varid,'units',unitees
NCDF_ATTPUT,file_out,nhemQ_varid,'long_name','Q Northern Hemisphere Average 20N-70N'
NCDF_ATTPUT,file_out,nhemQ_varid,'missing_value',mdi

NCDF_ATTPUT,file_out,shemQ_varid,'units',unitees
NCDF_ATTPUT,file_out,shemQ_varid,'long_name','Q Southern Hemisphere Average 70S-20S'
NCDF_ATTPUT,file_out,shemQ_varid,'missing_value',mdi
NCDF_CONTROL,file_out,/ENDEF

NCDF_VARPUT,file_out,glob_varid,glob_avg_ts
NCDF_VARPUT,file_out,trop_varid,trop_avg_ts
NCDF_VARPUT,file_out,nhem_varid,nhem_avg_ts
NCDF_VARPUT,file_out,shem_varid,shem_avg_ts
NCDF_VARPUT,file_out,globM_varid,Mglob_avg_ts
NCDF_VARPUT,file_out,tropM_varid,Mtrop_avg_ts
NCDF_VARPUT,file_out,nhemM_varid,Mnhem_avg_ts
NCDF_VARPUT,file_out,shemM_varid,Mshem_avg_ts
NCDF_VARPUT,file_out,globQ_varid,Qglob_avg_ts
NCDF_VARPUT,file_out,tropQ_varid,Qtrop_avg_ts
NCDF_VARPUT,file_out,nhemQ_varid,Qnhem_avg_ts
NCDF_VARPUT,file_out,shemQ_varid,Qshem_avg_ts
NCDF_VARPUT,file_out,time_id,int_mons
NCDF_CLOSE,file_out;

stop
end
