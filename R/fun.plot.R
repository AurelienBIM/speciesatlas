#!/usr/bin/Rscript

# ==============================================================================
# authors         :Ghislain Vieilledent, Aurelien Colas
# email           :ghislain.vieilledent@cirad.fr, aurelien.colas@insa-lyon.fr
# license         :GPLv3
# ==============================================================================

# ==================
# Plotting
# ==================

fun.plot <- function(path,name,spname,spdir,wcomp,p,zoom,enough,r.mar,e.map,BiomodData,BiomodModel,fut.var,npix,environ,s,out.type){

  ##=====================
  ## Current distribution

  ## Presence points and altitude
  # Legend specifications
  a.arg <- list(at=seq(0,3000,length.out=4),labels=seq(0,3000,length.out=4),cex.axis=1.5)
  l.arg <- list(text="Elevation (m)",side=2, line=0.5, cex=2.5)
  # Plot
  if((out.type=="html")||(out.type=="both")){
    png(paste0(path,"/presence_alt.png"),width=650,height=1000)
    par(mar=c(0,0,0,1),cex=1.4)
    plot(environ$alt,col=terrain.colors(255)[255:1],
         legend.width=1.5,legend.shrink=0.6,legend.mar=7,
         axis.args=a.arg,legend.arg=l.arg,
         axes=FALSE,box=FALSE,zlim=c(0,3000))
    if (length(wcomp)>=1){plot(p,pch=1,add=TRUE,cex=3)}
    if (zoom) {rect(e.map[1],e.map[3],e.map[2],e.map[4],border="black",lwd=1.5)}
    dev.off()
  }
  if((out.type=="pdf")||(out.type=="both")){
    pdf(paste0(path,"/presence_alt.pdf"),width=6.5,height=10)
    par(mar=c(0,0,0,1),cex=1.4)
    plot(environ$alt,col=terrain.colors(255)[255:1],
         legend.width=1.5,legend.shrink=0.6,legend.mar=7,
         axis.args=a.arg,legend.arg=l.arg,
         axes=FALSE,box=FALSE,zlim=c(0,3000))
    if (length(wcomp)>=1){plot(p,pch=1,add=TRUE,cex=3)}
    if (zoom) {rect(e.map[1],e.map[3],e.map[2],e.map[4],border="black",lwd=1.5)}
    dev.off()
  }


  if(enough){
    ## Committee averaging
    # Legend specifications
    nbCategory <- length(grep("_Full_", BiomodModel@models.computed))+1 ##Adding +1 for zeros
    breakpoints <- seq(-100, 1100, 1200/nbCategory)
    # colors <- c(grey(c(0.95,0.75,0.55)),"#568203","#2B5911","#013220")
    colors <- c(grey(seq(0.95,0.55, length.out=floor(nbCategory/2))),colorRampPalette(c("#568203", "#013220"))(ceiling(nbCategory/2)))
    # a.arg <- list(at=seq(0,1000,length.out=6), labels=c("0","1","2","3","4","5"),cex.axis=1.5)
    a.arg <- list(at=seq(0,1000,length.out=nbCategory), labels=seq(0, nbCategory-1, 1),cex.axis=1.5)
    l.arg <- list(text="Vote",side=2, line=0.5, cex=2.5)
    # Load data
    pred <- stack(paste0(spdir,"/proj_current/proj_current_",spdir,"_ensemble.grd"))
    ca <- pred[[1]]

    #Not used in the atlas, adding presence over current niche to assess model quality
    # if((out.type=="html")||(out.type=="both")){
    #   png(paste0(path,"/ca_current&points.png"),width=650,height=1000)
    #   par(mar=c(0,0,0,r.mar),cex=1.4)
    #   plot(ca,col=colors,breaks=breakpoints,ext=e.map,
    #        legend.width=1.5,legend.shrink=0.6,legend.mar=7,
    #        axis.args=a.arg,legend.arg=l.arg,
    #        axes=FALSE, box=FALSE, zlim=c(0,1000))
    #   if (!is.null(iucn_range)){plot(iucn_range, add=T, lwd=2)}
    #   if (length(wcomp)>=1){plot(p,pch=1,add=TRUE,cex=3, col="red")}
    #   dev.off()
    # }

    # Plot
    if((out.type=="html")||(out.type=="both")){
      png(paste0(path,"/ca_current.png"),width=650,height=1000)
      par(mar=c(0,0,0,r.mar),cex=1.4)
      plot(ca,col=colors,breaks=breakpoints,ext=e.map,
           legend.width=1.5,legend.shrink=0.6,legend.mar=7,
           axis.args=a.arg,legend.arg=l.arg,
           axes=FALSE, box=FALSE, zlim=c(0,1000))
      if (length(wcomp)>=1&zoom){plot(p,pch=1,add=TRUE,cex=3, col="brown")}
      dev.off()
    }
    if((out.type=="pdf")||(out.type=="both")){
      pdf(paste0(path,"/ca_current.pdf"),width=6.5,height=10)
      par(mar=c(0,0,0,r.mar),cex=1.4)
      plot(ca,col=colors,breaks=breakpoints,ext=e.map,
           legend.width=1.5,legend.shrink=0.6,legend.mar=7,
           axis.args=a.arg,legend.arg=l.arg,
           axes=FALSE, box=FALSE, zlim=c(0,1000))
      if (length(wcomp)>=1&zoom){plot(p,pch=1,add=TRUE,cex=3, col="brown")}
      dev.off()
    }

    ## Value used to consider a cell as favorable for the species
    treshold <- seq(0,1000,length.out=nbCategory)[floor(nbCategory/2)+1]

    ## Present species distribution area (km2)
    SDA.pres <- sum(values(ca)>=treshold,na.rm=TRUE) # Just the sum because one pixel is 1km2.

    ## Colors definition
    gcolors <- colorRampPalette(c("#568203","#013220"))

    ##=================
    ## Ecological niche

    ## 95% quantiles for alt, temp, prec, tseas, cwd
    wC <- which(values(ca)>=treshold)
    niche.df <- as.data.frame(values(s))[wC,]
    niche.df$alt <- environ$alt[wC]
    Mean <- round(apply(niche.df,2,mean,na.rm=TRUE))
    q <- round(apply(niche.df,2,quantile,c(0.025,0.975),na.rm=TRUE))
    niche <- as.data.frame(rbind(Mean,q))

    ## Draw points in the SDA and extract environmental variables
    # In SDA
    nC <- length(wC)
    Samp <- if (nC>1000) {sample(wC,1000,replace=FALSE)} else {wC}
    mapmat.df <- as.data.frame(values(s))[Samp,]
    # Pseudo-absences
    wAbs <- BiomodData@coord[-c(1:length(p)),] #first lines are for presence points
    Abs.df <- as.data.frame(extract(s,wAbs))
    # Plot MAP-MAT
    # plotExtent<-ggplot_build(ggplot(Abs.df, aes(x=prec, y=temp)) + xlim(0,5000)+ylim(0,1000)+ stat_density2d())$data[[1]]
    # map.mat <- ggplot(mapmat.df, aes(x=prec, y=temp)) + xlim(min(plotExtent$x),max(plotExtent$x))+ ylim(min(plotExtent$y), max(plotExtent$y))+
    #   geom_density2d(data=Abs.df,col=grey(0.5)) +
    #   geom_point(data=mapmat.df,col="darkgreen",alpha=1/3) +
    #   labs(x="Annual precipitation (mm.y-1)",y=expression(paste("Mean annual temp. (",degree,"C x 10)")),size=4) +
    #   theme(plot.margin=unit(c(0.5,1,1,0.5), "lines"),
    #         axis.title.x=element_text(size=rel(3.6),margin=margin(t=15)),
    #         axis.title.y=element_text(size=rel(3.6),margin=margin(r=15)),
    #         axis.text.x=element_text(size=rel(3.6)),
    #         axis.text.y=element_text(size=rel(3.6)))
    # if((out.type=="html")||(out.type=="both")){
    #   ggsave(file=paste0(path,"/map-mat.png"),plot=map.mat,width=10,height=10)
    # }
    # if((out.type=="pdf")||(out.type=="both")){
    #   ggsave(file=paste0(path,"/map-mat.pdf"),plot=map.mat,width=10,height=10)
    # }

    ##=================
    ## Table of results

    ## Model performance of committee averaging
    # Individual models
    Perf.mods <- as.data.frame(as.table(get_evaluations(BiomodModel)))
    names(Perf.mods) <- c("wIndex","Index","Model","Run","PA","Value")
    # Observations and committee averaging predictions
    ObsData <- BiomodData@data.species
    ObsData[is.na(ObsData)] <- 0
    caData <- values(ca)[cellFromXY(ca,xy=BiomodData@coord)]
    PredData <- rep(0,length(caData))
    PredData[caData>=treshold] <- 1
    # Committee averaging performance
    Index <- c("ROC","ACCURACY","TSS")# Remove "Kappa"
    Perf.ca <- data.frame(ROC=NA,OA=NA,TSS=NA)
    for (ind in 1:length(Index)) {
        v <- Find.Optim.Stat(Stat=Index[ind],Fit=caData,Obs=ObsData,Fixed.thresh=treshold-1) # ! here vote ca > 499: three models at least
      Perf.ca[,ind] <- v[1]
    }
    # Perf.ca$Sen <- v[3]
    # Perf.ca$Spe <- v[4]

    ## Variable importance
    VarImp <- as.data.frame(get_variables_importance(BiomodModel)[,,"Full","PA1"])
    Rank <- as.data.frame(apply(-VarImp,2,rank))
    VarImp$mean.rank <- apply(Rank,1,mean)
    VarImp$rank <- rank(VarImp$mean.rank,ties.method="max")

    ##====================
    ## Future distribution

    ## Table for changes in area
    SDA.fut <- data.frame(area.pres=SDA.pres,rcp=rep(fut.var[[2]],each=(2*length(fut.var[[3]]))),yr=rep(rep(fut.var[[3]],each=length(fut.var[[2]])),2),
                          disp=rep(c("full","zero"),(length(fut.var[[2]])*length(fut.var[[3]]))),area.fut=NA)
    ## Change in altitude
    Alt.fut <- data.frame(mean.pres=niche$alt[1],q1.pres=niche$alt[2],q2.pres=niche$alt[3],
                          rcp=rep(fut.var[[2]],each=2*length(fut.var[[3]])),yr=rep(rep(fut.var[[3]],each=length(fut.var[[2]])),2),
                          disp=rep(c("full","zero"),length(fut.var[[2]])*length(fut.var[[3]])),mean.fut=NA,q1.fut=NA,q2.fut=NA)

    ## Committee averaging for the three GCMs (sum)
    for (j in 1:length(fut.var[[2]])) {
      for (l in 1:length(fut.var[[3]])) {
        # Create stack of model predictions
        caS <- stack()
        for (mc in 1:length(fut.var[[1]])) {
          name.f <- paste0("/proj_",fut.var[[1]][mc],"_",fut.var[[2]][j],"_",fut.var[[3]][l])
          pred.f <- stack(paste0(spdir,name.f,name.f,"_",spdir,"_ensemble.grd"))
          caS <- addLayer(caS,pred.f[[1]])
        }

        # Compute number of possible outcome
        nbCategoryFuture <- (nbCategory-1)*length(fut.var[[1]])+1
        # Compute sum
        caFut <- sum(caS)
        # Legend
        # breakpoints <- seq(-100,3100,by=200)
        breakpoints <- seq(-100,3100,3200/nbCategoryFuture)
        colors <-  c(grey(seq(0.95,0.55, length.out=floor(nbCategoryFuture/2))),colorRampPalette(c("#568203", "#013220"))(ceiling(nbCategoryFuture/2)))
        a.arg <- list(at=seq(0,3000,length.out=nbCategoryFuture), labels=seq(0, nbCategoryFuture-1, 1), cex.axis=1.5)
        l.arg <- list(text="Vote",side=2, line=0.5, cex=2.5)
        # Plot (Committee Averaging Full Dispersal)
        if((out.type=="html")||(out.type=="both")){
          png(paste0(path,"/cafd_",fut.var[[2]][j],"_",fut.var[[3]][l],".png"),width=650,height=1000)
          par(mar=c(0,0,0,r.mar),cex=1.4)
          plot(caFut,col=colors,breaks=breakpoints,ext=e.map,
               legend.width=1.5,legend.shrink=0.75,legend.mar=7,
               axis.args=a.arg,legend.arg=l.arg,
               axes=FALSE,box=FALSE,zlim=c(0,3000))
          dev.off()
        }
        if((out.type=="pdf")||(out.type=="both")){
          pdf(paste0(path,"/cafd_",fut.var[[2]][j],"_",fut.var[[3]][l],".pdf"),width=6.5,height=10)
          par(mar=c(0,0,0,r.mar),cex=1.4)
          plot(caFut,col=colors,breaks=breakpoints,ext=e.map,
               legend.width=1.5,legend.shrink=0.75,legend.mar=7,
               axis.args=a.arg,legend.arg=l.arg,
               axes=FALSE,box=FALSE,zlim=c(0,3000))
          dev.off()
        }

        # Zero-dispersal
        caZD <- caFut
        values(caZD)[values(ca)<treshold] <- 0 # !! Here <treshold: three models at least for a presence
        if((out.type=="html")||(out.type=="both")){
          png(paste0(path,"/cazd_",fut.var[[2]][j],"_",fut.var[[3]][l],".png"),width=650,height=1000)
          par(mar=c(0,0,0,r.mar),cex=1.4)
          plot(caZD,col=colors,breaks=breakpoints,ext=e.map,
               legend.width=1.5,legend.shrink=0.75,legend.mar=7,
               axis.args=a.arg,legend.arg=l.arg,
               axes=FALSE,box=FALSE,zlim=c(0,3000))
          dev.off()
        }
        if((out.type=="pdf")||(out.type=="both")){
          pdf(paste0(path,"/cazd_",fut.var[[2]][j],"_",fut.var[[3]][l],".pdf"),width=6.5,height=10)
          par(mar=c(0,0,0,r.mar),cex=1.4)
          plot(caZD,col=colors,breaks=breakpoints,ext=e.map,
               legend.width=1.5,legend.shrink=0.75,legend.mar=7,
               axis.args=a.arg,legend.arg=l.arg,
               axes=FALSE,box=FALSE,zlim=c(0,3000))
          dev.off()
        }
        #Value used to consider a cell as favorable for the species in the future
        tresholdFuture <- seq(0,1000*length(fut.var[[1]]),length.out=nbCategoryFuture)[floor(nbCategoryFuture/2)+1]
        # SDA (in km2)
        SDA.fut$area.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="full"] <- sum(values(caFut)>=tresholdFuture,na.rm=TRUE) # !! Here >1500
        SDA.fut$area.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="zero"] <- sum(values(caZD)>=tresholdFuture,na.rm=TRUE) # !! Same here
        # Altitude
        # fd
        if (SDA.fut$area.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="full"] !=0) {
          Alt.fut$mean.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="full"] <- mean(values(environ$alt)[values(caFut)>=tresholdFuture],na.rm=TRUE)
          Alt.fut$q1.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="full"] <- quantile(values(environ$alt)[values(caFut)>=tresholdFuture],0.025,na.rm=TRUE)
          Alt.fut$q2.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="full"] <- quantile(values(environ$alt)[values(caFut)>=tresholdFuture],0.975,na.rm=TRUE)
          # round
          Alt.fut[,7:9] <- round(Alt.fut[,7:9])
        }
        # zd
        if (SDA.fut$area.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="zero"] !=0) {
          Alt.fut$mean.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="zero"] <- mean(values(environ$alt)[values(caZD)>=tresholdFuture],na.rm=TRUE)
          Alt.fut$q1.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="zero"] <- quantile(values(environ$alt)[values(caZD)>=tresholdFuture],0.025,na.rm=TRUE)
          Alt.fut$q2.fut[SDA.fut$rcp==fut.var[[2]][j] & SDA.fut$yr==fut.var[[3]][l] & SDA.fut$disp=="zero"] <- quantile(values(environ$alt)[values(caZD)>=tresholdFuture],0.975,na.rm=TRUE)
          # round
          Alt.fut[,7:9] <- round(Alt.fut[,7:9])
        }
      }
    }
    # SDA
    SDA.fut$perc.change <- round(100*((SDA.fut$area.fut-SDA.fut$area.pres)/SDA.fut$area.pres))
    SDA.fut <- SDA.fut[with(SDA.fut, order(rcp, disp, yr)),]
    # Alt
    Alt.fut$change <- Alt.fut$mean.fut-Alt.fut$mean.pres
    Alt.fut <- Alt.fut[with(Alt.fut, order(rcp, disp, yr)),]
    ##========================================
    ## Save objects to be loaded by knitr
    save(list=c("SDA.fut","Alt.fut","niche","Perf.ca","Perf.mods","VarImp","npix"),file=paste0(path,"/plotting.rda"))
    ##========================================
    ## Load objet for whole taxon
    ## Load objet for whole taxon
    load(paste0("../figures/",name,"/plotting.rda"))

    # SDA
    SDA.whole.fut <- rbind(SDA.whole.fut, cbind(spname,SDA.fut[6,c(1,5,6)]))
    SDA.whole.fut <- rbind(SDA.whole.fut, cbind(spname,SDA.fut[8,c(1,5,6)]))

    # STats on variables importance
    variable.perf.taxon$sumPos <- variable.perf.taxon$sumPos + VarImp$rank
    variable.perf.taxon$N.1[which(VarImp$rank==1)]<-variable.perf.taxon$N.1[which(VarImp$rank==1)]+1
    variable.perf.taxon$N.2[which(VarImp$rank==2)]<-variable.perf.taxon$N.2[which(VarImp$rank==2)]+1
    variable.perf.taxon$N.1.N[which(VarImp$rank==length(VarImp$rank)-1)]<-variable.perf.taxon$N.1.N[which(VarImp$rank==length(VarImp$rank)-1)]+1
    variable.perf.taxon$N.N[which(VarImp$rank==length(VarImp$rank))]<-variable.perf.taxon$N.N[which(VarImp$rank==length(VarImp$rank))]+1

    #STats perf
    Perf.mods <- get.Model.Perf(Perf.mods)
    Perf.mods.TSS.Tot <- rbind(Perf.mods.TSS.Tot,Perf.mods[[1]])
    Perf.mods.ROC.Tot <- rbind(Perf.mods.ROC.Tot,Perf.mods[[2]])

    save(list=c("SDA.whole.fut","variable.perf.taxon","Perf.mods.TSS.Tot","Perf.mods.ROC.Tot"),file=paste0("../figures/",name,"/plotting.rda"))
  }
}

get.Model.Perf <- function(Perf.mods){
  names(Perf.mods) <- c("wIndex","Index","Model","Run","PA","Value")
  Perf.mods.test <- Perf.mods[Perf.mods$Index=="Testing.data"&Perf.mods$wIndex!="KAPPA",c(1,3,4,6)]
  Perf.mods.TSS <- reshape(Perf.mods.test[Perf.mods.test$wIndex=="TSS",-1],
                           timevar="Run", idvar="Model", direction="wide")
  Perf.mods.ROC <- reshape(Perf.mods.test[Perf.mods.test$wIndex=="ROC",-1],
                           timevar="Run", idvar="Model", direction="wide")
  return(list(Perf.mods.TSS,Perf.mods.ROC))
}
