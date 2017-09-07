find.high.cons <- function(data,title_string,criteria1,criteria2,rounds)
{
   x <- logit.transform(data,is.plot=TRUE)
   x <- x + rnorm(length(x),0,0.01) # adding some noise

   ## initialise optimisation algorithm (3 components)
   start.p0 <- c(log(0.3),log(0.3),-1,log(0.5),0,log(0.5),2,log(0.5))
   opt <- optimise(x,start.p0,rounds)

   ## show mixture components
   round(show.pars(opt),3)
   parameters <- plot.mixture.col(x,opt,"magenta")

   answer <- plot.high.conservation(parameters,criteria1,criteria2)

   title(main=title_string,font.main=2,cex.main=1.25,line=3)

   rounded_answer <- round(answer,digits=6)

   rounded_answer
}

logit.transform <- function(p,is.plot=F) {
  ## rescale to 0.01 .. 0.99 for stability
  if (max(p) > 0.99 || min(p) < 0.01)
    p <- p*0.98 + 0.01
  ## logit
  y <-  log(p/(1-p))
  #if (is.plot) 
     #plot(density(y,adjust=0.5)); rug(y)
  y
}

optimise <- function(x,start.p0,rounds=5) {
  start.p <- start.p0
  opt <- list(value=Inf)
  for (round in 1:rounds) {
    start.p <- start.p + rnorm(length(start.p0),0,1)
    opt.t <- try(optim(start.p,neg.loglik,
                   method="BFGS",x=x,control=list(trace=FALSE)))
    if (inherits(opt.t,"try-error")) {
      cat("problem with optim, trying next\n")
      next
    }

    #print(opt.t$value)
    if (opt.t$value < opt$value) {
      opt <- opt.t
    }
  }
  opt
}

logit.single <- function(number){
  if (number > 0.99 || number < 0.01)
    number <- number*0.98 + 0.01
  ## logit
  y <-  log(number/(1-number))
  return(y)
}

expit.single <- function(number){
  if (number > 0.99 || number < 0.01)
    number <- number*0.98 + 0.01
  ## expit
  y <-  exp(number)/(1+exp(number))
  if ( y > 1 )
    y = 1
  return(y)
}


show.pars <- function(opt) {
  pars <- values.mix(opt$par)
  t(rbind(probs=pars$w,pars$pm))
}

plot.mixture.col <- function(x,opt,colour) {
  pars <- values.mix(opt$par)
  t <- seq(min(x)-0.5,max(x)+0.5,len=100)

  # adds the combined distribution
  #plot(t,ddistr.mix(t,opt$par),type="n",ylab="density",xlab="logit conservation score",xlim=c(-5,5))

  # adds the actual datapoints
  #lines(density(x,adjust=0.5)); rug(x)

  heights <- c(0,0,0)

  for (k in 1:length(pars$w)) {
    # adds the individual distributions
    #lines(t,pars$w[k]*ddistr(t,pars$pm["mean",k],pars$pm["sd",k]),col="blue")
    height <- max(pars$w[k]*ddistr(t,pars$pm["mean",k],pars$pm["sd",k]))
    heights[k] <- height
  }

  ylims <- c( 0, max( heights, density(x,adjust=0.5)$y ) )
  xlims <- c(-4.6,4.6)

  #cat( ylims, "\n" )

  other.axis.col <- "gray70"
  axis.size <- 0.65
  logit.points <- seq(0,1,0.1)
  tick.size <- -0.02

  plot(density(x,adjust=0.5), type="l", xlim=xlims, ylim=ylims, cex.axis=axis.size, ann=FALSE, axes=FALSE)
  rug( x );
  axis(1,at=seq(-4,4,1),cex.axis=axis.size,tck=tick.size,padj=-1.5)
  axis(2,cex.axis=axis.size,tck=tick.size,padj=1)
  axis(3,logit.points,at=logit.transform(logit.points),cex.axis=axis.size,col=other.axis.col,col.axis=other.axis.col,tck=tick.size,padj=1)
  box( );
  title(xlab="logit conservation score",cex.lab=0.85,font.lab=2,line=1.5)
  title(ylab="density",cex.lab=0.85,font.lab=2,line=1.75)

  for (k in 1:length(pars$w)) {
    # adds the individual distributions
    lines(t,pars$w[k]*ddistr(t,pars$pm["mean",k],pars$pm["sd",k]),col="blue")
  }

  params <- rbind(pars$pm["mean",],pars$pm["sd",],heights,pars$w)
  rownames(params) <- c("mean","sd","max","prob")

  return(params)

}

plot.high.conservation <- function(params,criteria1,criteria2)
{
   ovector <- order(-params["mean",])

   c1.th <- logit.single(criteria1)

   text_pos <- max(params["max",])*2/3
   offset <- 0.15

   c1.col <- "orange"
   c2.col <- "red"
   bad.col <- "grey"
   data.col <- "black"
   gauss.col <- "blue"

   text.x <- -5
   text.y <- max(params["max",])

   legend( "topleft", c("raw data", "fitted gaussians", "constraint 1 (dashed if violated) ", "constraint 2 (dashed if violated) " ),
           col = c(data.col, gauss.col, c1.col, c2.col),
           text.col = "black", lty = c(1, 1, 1, 1), bty=0, bg=0)

   if ( params["mean",ovector[1]] >= c1.th )
   {
      threshold <- params["mean",ovector[2]]+(criteria2*params["sd",ovector[2]])
      if ( threshold > logit.single( 1.00 ) ) { threshold <- logit.single( 1.00 ) - 0.001 }

      linex <- rep(threshold,2)
      liney <- c(0,max(params["max",]))

      true_threshold <- round(expit.single(threshold),7)

      abline(v=c1.th,col=c1.col)

      if ( params["mean",ovector[1]] >= threshold ) {
        abline(v=threshold,col=c2.col)
        expit.single( threshold )
      } else {
        abline(v=threshold,col=c2.col,lty=2)
        #legend("topleft",paste( paste(formatC(0.8000,digits=4,format="f"),"(! C2)",sep=" "), " " ), adj=c(0,0.5), inset=-0.02, bg="gray95") ; box()
        return( 2 )
      }

      #legend("topleft",paste( paste(formatC(true_threshold,digits=4,format="f"),sep=" / "), " " ), adj=c(0,0.5), inset=-0.02, bg="gray95"); box()
      return( true_threshold )

   } else {
      abline(v=c1.th,col=c1.col,lty=2)
      #legend("topleft", paste("! C1 ",sep=""), adj=c(0,0.5), inset=-0.02, bg="gray95"); box()
      return( 3 )
   }

}

draw.legend <- function(bw=TRUE)
{
    col_part <- 0.1
    ncols <- 11

    cols <- rev(gray.colors(ncols))
    
    if ( ! bw )
    {
        cols <- rainbow(ncols,start=.3, end=0)
        #cols <- rev(heat.colors(ncols))
    }
    
    ###
    ### values for the alignment
    ### 
    ### 
    xl <- 0
    xr <- 10
    yb <- 0
    yt <- 10

    ###
    ### values for the legend
    ###

    j <- seq( 0,10,1 )

    scale_xl <- 0
    scale_xr <- 1
    scale_yb <- j
    scale_yt <- j+1

    ### 'mar' A numerical vector of the form 'c(bottom, left, top, right)'
    ###      which gives the number of lines of margin to be specified on
    ###      the four sides of the plot. The default is 'c(5, 4, 4, 2) +
    ###      0.1'.

    #par( mar=c(5,0,0,1) + 0.5 )
    #par( mar=c(4.1,0,3,1) + 0.5 )
    par( mar=c(3.8,-0.4,-0.2,0.5) + 0.5 )
    plot( c(xl, xr), c(yb, yt+1), type = "n", axes=FALSE, ann=FALSE )

    rect(scale_xl, scale_yb, scale_xr, scale_yt, col=cols, lty=0)

    ann_x <- 2
    ann_y <- scale_yt

    ann_l <- seq( 0, 1, col_part )
    ann_t <- paste( formatC( ann_l, digits = 2, format="f" ) , formatC( ann_l + ( 0.9*col_part ), digits=2 , format="f" ), sep="-")
    ann_t[ length( ann_t ) ] <- "1.00"

    text( ann_x, ann_y - 0.5 , ann_t, cex=0.60, adj=c( 0,0.5 ) )
}

write.threshold <- function(th)
{
   par( mar=c(0,0.5,3.6,1.2) + 0.5 )
   text.string <- paste( "ImPACT", "threshold", "is", th, sep=" " )
   if ( th == 2 ) {
     text.string <- paste( "C2 violated - using default threshold of 0.80" )
   } else if ( th == 3 ) {
     text.string <- paste( "C1 violated - no high conservation" )
   }

   plot( 1:5, rep(1,5), ylim=c(0.5,1.5), type="n", axes=FALSE, ann=FALSE, bg="gray95")
   #plot( 1:5, rep(1,5), ylim=c(0,2), type="n")
   box( )
   text( 3, 1, text.string, adj=c(0.5,0.5), font=2, cex=1.1)
}

draw.alignment <- function(data,width,height,bw=TRUE)
{   
    col_part <- 0.1
    ncols <- ( 1 / col_part ) + 1 
    
    i <- width * ( 0:(length(data)-1) )

    cols <- rev(gray.colors(ncols)) 
    
    if ( ! bw )
    {
        cols <- rainbow(11,start=.3, end=0)
        #cols <- rev(heat.colors(ncols))
    }
    
    #col.vector <- ceiling(data/col_part-0.00001)+1
    col.vector <- ceiling(data/col_part-0.00001 + 1)
   
    ###
    ### values for the alignment
    ### 
    ### 
    xl <- 0
    xr <- xl + width
    yb <- 0
    yt <- yb + height

    ###
    ### values for the legend
    ###

    scale_y <- height/ncols
    scale_x <- 20 * scale_y

    j <- scale_y * ( 0:10 )

    scale_xl <- max( i ) + xl
    scale_xr <- scale_xl + scale_x
    scale_yb <- 0
    scale_yt <- scale_yb + scale_y

    #entire_width <- max ( i ) + xl + ( 5.2 * scale_x )

    ### 'mar' A numerical vector of the form 'c(bottom, left, top, right)'
    ###      which gives the number of lines of margin to be specified on
    ###      the four sides of the plot. The default is 'c(5, 4, 4, 2) +
    ###      0.1'.

    par( mar=c(3.8,-0.4,-0.2,0) + 0.5 )
    plot( c(xl, max(i) + xl), c(yb, height), type = "n", xlab="", ylab="", main="Alignment", axes=FALSE, ann=FALSE )
    #box( lty=1, col=gray(0.4) )

    rect(xl+i, yb, xr+i, yt, col=cols[col.vector], lty=0)
    
    #rect(scale_xl, scale_yb + j, scale_xr, scale_yt + j, col=cols, lty=0)

    #ann_x <- rep( max( i ) + xl + ( 2.5 * scale_x ), 11 )
    #ann_y <- scale_yb + j

    #ann_l <- seq( 0, 1, col_part )
    #ann_t <- paste( formatC( ann_l, digits = 2, format="f" ) , formatC( ann_l + ( 0.9*col_part ), digits=2 , format="f" ), sep="-")
    #ann_t[ length( ann_t ) ] <- "1.00"

    #text( ann_x, ann_y + ( 0.5 * scale_y ), ann_t, cex=0.60, adj=c( 0,0.5 ) )
}

## ---------- normal mixture distribution

values.mix <- function(p) {
  ## p parameters with
  ## p[1:(K-1)]: mixture weights in log space,
  ## weight K is 0 in log
  ## p[K:(2*K-1)] alternatingly means, and log(sd)s
  ## output: list with weights $w and
  ## matrix $pm of means in first and sds in second row

  K <- (length(p) + 1) / 3
  w <- p[1:(K-1)]
  w <- c(exp(w),1)
  w <- w/sum(w)
  pm <- matrix(p[K:length(p)],ncol=2,byrow=T)
  pm[,2] <- exp(pm[,2])
  colnames(pm) <- c("mean","sd")
  list(w=w,pm=t(pm))
}

ddistr.mix <- function(x,p) {
  ## x values
  ## p parameters (see values.mix())
  ## output: log prob of normal mixture for all x values

  ps <- values.mix(p)
  K <- length(ps$w)
  p.total <- 0
  for (k in 1:K)
    p.total <- p.total + ps$w[k]*ddistr(x,ps$pm["mean",k],ps$pm["sd",k])
  p.total
}

pdistr.mix <- function(x,p,...) {
  ## x values
  ## p parameters (see values.mix())
  ## output: log prob of normal mixture for all x values

  ps <- values.mix(p)
  K <- length(ps$w)
  p.total <- 0
  for (k in 1:K)
    p.total <- p.total + ps$w[k]*pdistr(x,ps$pm["mean",k],ps$pm["sd",k],...)
  p.total
}

log.prior <- function(p) {
  ## IMPORTANT, assumes global vars: dir,prior.mean,prior.sd
  ## p parameters (see values.mix())
  ## output log prob of parameter priors

  ps <- values.mix(p)
  lp <- 0
  lp <- (sum(log(ps$w) * prior.dir) +
         sum(ddistr(ps$pm["mean",],prior.mean$m,prior.mean$s,log=TRUE)) +
         sum(ddistr(log(ps$pm["sd",]),prior.sd$m,prior.sd$s,log=TRUE))
         )
  lp
}

neg.loglik <- function(p,x) {
  ll <- sum(log(ddistr.mix(x,p)))
  lp <- log.prior(p)
  -(ll + lp)
}





######################################
## set some values                  ##
######################################

## -- set mixture density ---------------------------------------

ddistr <- dnorm
pdistr <- pnorm
## ddistr <- function(x,mean,sd) dt((x-mean)/sd,df=2)
## pdistr <- function(x,mean,sd) pt((x-mean)/sd,df=2)

## -- set common priors on mixture means and sd -----------------

## fairly uninformative prior on means:
prior.mean <- list(m=0,s=100)

## sd around 1, * or / by factor of 10
prior.sd <- list(m=log(2),s=log(3))

## set dirichlet priors for mixture variable for each mixture ---

## prior.dir <- c(1,1,1)   # uniform Dirichlet prior
## prior.dir <- c(50,50,2) # strong emphasis on 3rd comp small


######################################
## load data                        ##
######################################

#pire.file = commandArgs()[2]    # the conservation numbers
#protein.name = commandArgs()[3] # the protein name (for graph only)
cons.data = scan(pire.file,quiet=TRUE)     # the conservation data

prior.dir <- c(1,1,1) # uniform Dirichlet prior

graph.title <- paste( paste( "ImPACT", "results", "for", protein.name, sep=" " ),
                      paste( "C1", c1, sep=" = "),
                      paste( "C2", c2, sep=" = "),
                      sep = " || " )

#postscript(file=graph.file,onefile=TRUE,horizontal=TRUE,width=8,height=6)
#postscript(file = graph.file, onefile = TRUE, title = "ImPACT results", width=11.7, height=6, horizontal=TRUE)
#postscript(file = graph.file, onefile = TRUE, title = paste( "ImPACT", "results", "for", protein.name, sep=" " ), width=10, height=5, horizontal=TRUE)

pdf(file = graph.file, onefile = TRUE, title = graph.title, height=4, width=10)

nf <- layout(matrix(c(1,2,2,1,3,4),2,3,byrow=TRUE),c(8,5,1),c(1,3))

answer <- find.high.cons(cons.data,graph.title,c1,c2,rounds)
answer
write.threshold(answer)
draw.alignment(sort.int(cons.data),5,25,FALSE)
draw.legend(FALSE)

#dev.off()
