# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class AutohomeItem(scrapy.Item):
    id = scrapy.Field()
    name = scrapy.Field()
    landing = scrapy.Field()
    type = scrapy.Field()
    miles = scrapy.Field()
    power = scrapy.Field()
    charge = scrapy.Field()
    price = scrapy.Field()
    urate = scrapy.Field()
    pic = scrapy.Field()
    detail = scrapy.Field()
    subid = scrapy.Field()
    subname = scrapy.Field()
    spec = scrapy.Field()
    guide = scrapy.Field()
