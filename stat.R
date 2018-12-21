library(ggplot2)
library(ggcorrplot)
library(plotly)
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
    theme_set(theme_bw())

    x$est <- ceiling(x$endurance / 100) * 100
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$endurance)+10)
    g <- ggplot(x, aes(x=maxprice, y=endurance)) +
        geom_point(aes(col=type, size=est)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. Endurance",
             y="Endurance(km)",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("scatter.endurance.electro.png", width=16, height=9, dpi=640)

    x$hwest <- ceiling(x$maxpower / 100) * 100
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$maxpower)+10)
    g <- ggplot(x, aes(x=maxprice, y=maxpower)) +
        geom_point(aes(col=type, size=hwest)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. Power",
             y="Power(hp)",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("scatter.power.electro.png", width=16, height=9, dpi=640)

    x$btest <- ceiling(x$battary / 10) * 10
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$battary)+10)
    g <- ggplot(x, aes(x=maxprice, y=battary)) +
        geom_point(aes(col=type, size=btest)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. Battary",
             y="Battary(kWh)",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("scatter.battary.electro.png", width=16, height=9, dpi=640)

    x$fest <- ceiling(x$fast * 10) / 10
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$fast)+1)
    g <- ggplot(x, aes(x=maxprice, y=fast)) +
        geom_point(aes(col=type, size=fest)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. FastCharge",
             y="FastCharge(h)",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("scatter.fast.electro.png", width=16, height=9, dpi=640)

    x$sest <- ceiling(x$slow / 4) * 4
    mx <- ceiling(max(x$maxprice)+5)
    my <- ceiling(max(x$slow)+1)
    g <- ggplot(x, aes(x=maxprice, y=slow)) +
        geom_point(aes(col=type, size=sest)) +
        geom_smooth(method="loess", se=F) +
        xlim(c(0,mx)) +
        ylim(c(0,my)) +
        labs(subtitle="Price v.s. SlowCharge",
             y="SlowCharge(h)",
             x="GuidePrice",
             title="Scatter Plot",
             caption = "Source: autohome diandongche")
    ggsave("scatter.slow.electro.png", width=16, height=9, dpi=640)
}

plot3d <- function(x) {
    p <- plot_ly(x, x = ~maxprice, y = ~endurance, z = ~maxpower, color = ~type) %>%
        add_markers() %>%
        layout(scene = list(xaxis = list(title = 'GuidePrice'),
                            yaxis = list(title = 'Endurance'),
                            zaxis = list(title = 'HorsePower')))
    chart_link = api_create(p, filename="scatter3d-basic")
    chart_link
}

plotdensity <- function(x) {
    theme_set(theme_bw())
    g <- ggplot(x, aes(x=maxprice)) +
        geom_histogram(aes(y=..density..), color='lightblue', fill='white') +
        geom_density(alpha=.2, color='darkblue', fill='cyan') +
        geom_vline(data=data.frame(mu=mean(x$maxprice)), aes(xintercept=mu, color='red'), linetype='dashed')
    ggsave("density.price.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=battary)) +
        geom_histogram(aes(y=..density..), color='lightblue', fill='white') +
        geom_density(alpha=.2, color='darkblue', fill='cyan') +
        geom_vline(data=data.frame(mb=mean(x$battary)), aes(xintercept=mb, color='red'), linetype='dashed')
    ggsave("density.battary.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=endurance)) +
        geom_histogram(aes(y=..density..), color='lightblue', fill='white') +
        geom_density(alpha=.2, color='darkblue', fill='cyan') +
        geom_vline(data=data.frame(me=mean(x$endurance)), aes(xintercept=me, color='red'), linetype='dashed')
    ggsave("density.endurance.png", width=16, height=9, dpi=640)

    g <- ggplot(x, aes(x=maxpower)) +
        geom_histogram(aes(y=..density..), color='lightblue', fill='white') +
        geom_density(alpha=.2, color='darkblue', fill='cyan') +
        geom_vline(data=data.frame(mp=mean(x$maxpower)), aes(xintercept=mp, color='red'), linetype='dashed')
    ggsave("density.power.png", width=16, height=9, dpi=640)
}

v <- process(t)

plotcorr(v, c("battary", "fast", "fastperc", "slow", "endurance", "maxpower", "minpower", "maxprice", "minprice"))
plotscatter(v)
plotdensity(v)
