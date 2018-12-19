library(ggplot2)
library(ggcorrplot)
library(showtext)

showtext_auto()

args <- commandArgs(trailingOnly = TRUE)
t <- read.csv(args[1], na.strings="", stringsAsFactors=FALSE)

process <- function(x) {
    # 唯一名称
    uname <- paste(x$name, x$subname)
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
    g <- ggplot(x[1:100,], aes(x=name, y=endurance_z))
    g <- g + geom_bar(stat='identity', aes(fill=endurance_type), width=.5)
    g <- g + scale_fill_manual(name="Endurance(km)",
                    labels = c("Above Average", "Below Average"),
                    values = c("above"="#00ba38", "below"="#f8766d"))
    g <- g + labs(subtitle="Normalised endurance for electro cars", title= "Diverging Bars") 
    g <- g + coord_flip()
    ggsave("tmp.png", width=16, height=9, dpi=640)
}

v <- process(t)
#st <- c("battary", "fast", "fastperc", "slow", "endurance", "maxpower", "minpower", "maxprice", "minprice")
#plotcorr(v, st)
plotdiverging(v)
