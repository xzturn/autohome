library(showtext)

showtext_auto()

args <- commandArgs(trailingOnly = TRUE)
t <- read.csv(args[1])
print(t)
