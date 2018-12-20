library(ggplot2)
library(ggcorrplot)
library(plyr)
library(showtext)

showtext_auto()

args <- commandArgs(trailingOnly = TRUE)
t <- read.csv(args[1], na.strings="", stringsAsFactors=FALSE)

process <- function(x) {
    # 唯一名称
    uname <- paste(x$name, x$subname, sep=" ")
    x$uname <- factor(uname, levels=uname)

    # 电池容量
    x[x$battary=="暂无","battary"] <- NA
    x$battary <- as.integer(sub('kWh', '', x$battary))

    # 续航里程
    x[!is.na(x$endurance) & x$endurance=="暂无","endurance"] <- NA
    x$endurance <- as.integer(sub('km', '', x$endurance))

    # 快充时长(h)/快充百分比(%)/慢充时长(h)
    x[!is.na(x$fast) & x$fast=="暂无","fast"] <- NA
    x$fast <- as.numeric(sub('小时', '', x$fast))
    x[!is.na(x$fastperc) & x$fastperc=="暂无","fastperc"] <- NA
    x$fastperc <- as.numeric(sub('小时', '', x$fastperc))
    x[!is.na(x$slow) & x$slow=="暂无","slow"] <- NA
    x$slow <- as.numeric(sub('小时', '', x$slow))

    # 汽车动力
    x$maxpower <- as.numeric(sub('马力', '', sub('\\d+-', '', x$power)))
    x$minpower <- as.numeric(sub('马力', '', sub('-\\d+', '', x$power)))

    # 汽车指导价
    x$maxprice <- as.numeric(sub('万', '', sub('(\\d|.)+-', '', x$guide)))
    x$minprice <- as.numeric(sub('万', '', sub('-(\\d|.)+', '', x$guide)))

    # 整车质保
    x[x$insurance=="暂无" | x$insurance=="待查","insurance"] <- NA
    x$insurance <- factor(x$insurance)

    # 汽车类型、尺寸
    x$type <- factor(x$type)
    x[x$size=="暂无","size"] <- NA
    x$size <- factor(x$size)

    data.frame(name=x$uname,
               battary=x$battary,
               fast=x$fast,
               fastperc=x$fastperc,
               slow=x$slow,
               maxpower=x$maxpower,
               minpower=x$minpower,
               maxprice=x$maxprice,
               minprice=x$minprice,
               insurance=x$insurance,
               type=x$type,
               size=x$size,
               endurance=x$endurance)
}

plotcorr <- function(x, st) {
    corr <- round(cor(na.omit(subset(x, select=st))), 1)
    ggcorrplot(corr, hc.order = TRUE, 
               type = "lower", 
               lab = TRUE, 
               lab_size = 3, 
               method="circle", 
               colors = c("tomato2", "white", "springgreen3"), 
               title="Correlogram of electro", 
               ggtheme=theme_bw)
    ggsave("corr.electro.png", width=16, height=9, dpi=640)
}

plotdiverging <- function(x) {
    x$endurance_z <- round((x$endurance - mean(x$endurance, na.rm = TRUE))/sd(x$endurance, na.rm = TRUE), 2)
    x$endurance_type <- ifelse(x$endurance_z < 0, "below", "above")
    x <- x[order(x$endurance_z), ]

    theme_set(theme_bw())
    g <- ggplot(x, aes(x=name, y=endurance_z))
    g <- g + geom_bar(stat='identity', aes(fill=endurance_type), width=.5)
    g <- g + scale_fill_manual(name="Endurance(km)",
                    labels = c("Above Average", "Below Average"),
                    values = c("above"="#00ba38", "below"="#f8766d"))
    g <- g + labs(subtitle="Normalised endurance for electro cars", title= "Diverging Bars") 
    g <- g + coord_flip()
    ggsave("deverging.electro.png", width=16, height=9, dpi=640)
}

plotscatter <- function(x) {
    x$est <- ceiling(x$endurance / 100) * 100
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$endurance)+10)
    theme_set(theme_bw())
    g <- ggplot(x, aes(x=maxprice, y=endurance)) +
        geom_point(aes(col=type, size=est)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. Endurance",
             y="Endurance",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("endurance.electro.png", width=16, height=9, dpi=640)
}

plotdensity <- function(x) {
    theme_set(theme_bw())

    g <- ggplot(x, aes(x=maxprice)) +
        geom_density(color='darkblue', fill='lightblue') +
        geom_vline(data=data.frame(mu=mean(x$maxprice)), aes(xintercept=mu), linetype='dashed')
    ggsave("price.density.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=battary)) +
        geom_density(color='darkblue', fill='lightblue') +
        geom_vline(data=data.frame(mu=mean(x$battary)), aes(xintercept=mu), linetype='dashed')
    ggsave("battary.density.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=endurance)) +
        geom_density(color='darkblue', fill='lightblue') +
        geom_vline(data=data.frame(mu=mean(x$endurance)), aes(xintercept=mu), linetype='dashed')
    ggsave("endurance.density.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=maxpower)) +
        geom_density(color='darkblue', fill='lightblue') +
        geom_vline(data=data.frame(mu=mean(x$maxpower)), aes(xintercept=mu), linetype='dashed')
    ggsave("horsepower.density.png", width=16, height=9, dpi=640)
}

v <- process(t)

#plotcorr(v, c("battary", "fast", "fastperc", "slow", "endurance", "maxpower", "minpower", "maxprice", "minprice"))
#plotscatter(v)
plotdensity(v)
