# -*- coding: utf-8 -*-
import re
import scrapy
from autohome.items import AutohomeItem


class ElectroSpider(scrapy.Spider):
    name = 'electro'
    allowed_domains = ['autohome.com.cn']
    start_urls = ['https://car.autohome.com.cn/diandongche/list-0-0-0-1-0-0-0-0-1.html']

    def __init__(self):
        self.tag = "electro"
        self._idx = 0
        self._base = 'https://car.autohome.com.cn'
        self._ctype = re.compile('级\xa0\xa0别：')
        self._cmiles = re.compile('续航里程：')
        self._cpower = re.compile('电 动 机：')
        self._ccharge = re.compile('充电时间：')
        self._cprice = re.compile('指导价：')
        self._curate = re.compile('用户评分：')
        self._cpic = re.compile('图片')
        self._ccfg = re.compile('配置')

    def parse(self, response):
        i = 0
        dlist = response.css("div.intervalcont")
        for item in response.css("div.list-cont-main"):
            title = item.css("div.main-title a")
            lever = item.css("div.main-lever")
            leverl = lever.css("div.main-lever-left")
            leverr = lever.css("div.main-lever-right div")
            links = lever.css("div.main-lever-link a")
            einfo = AutohomeItem()
            einfo["id"] = self._idx
            einfo["name"] = title.css("::text").extract_first()
            einfo["landing"] = self._base + title.css("::attr(href)").extract_first()
            for t in leverl.css("ul.lever-ul li"):
                key = t.css("::text").extract_first()
                if self._ctype.search(key) is not None:
                    einfo["type"] = t.css("span::text").extract_first()
                elif self._cmiles.search(key) is not None:
                    einfo["miles"] = t.css("span::text").extract_first()
                elif self._cpower.search(key) is not None:
                    einfo["power"] = t.css("span::text").extract_first()
                elif self._ccharge.search(key) is not None:
                    einfo["charge"] = t.css("span::text").extract_first()
            for t in leverr:
                key = t.css("::text").extract_first()
                if self._cprice.search(key) is not None:
                    einfo["price"] = t.css("span span::text").extract_first()
                elif self._curate.search(key) is not None:
                    a = t.css("span a::attr(href)").extract_first()
                    if a is not None:
                        einfo["urate"] = "https:" + a
                    else:
                        einfo["urate"] = t.css("span::text").extract_first()
            for t in links:
                key = t.css("::text").extract_first()
                if self._cpic.search(key) is not None:
                    einfo["pic"] = self._base + t.css("::attr(href)").extract_first()
                elif self._ccfg.search(key) is not None:
                    einfo["detail"] = self._base + t.css("::attr(href)").extract_first()
            details = dlist[i].css("ul.interval01-list")
            sid = 0
            for t in details:
                t1 = t.css("div.interval01-list-cars")
                t2 = t.css("div.interval01-list-guidance")
                j = 0
                for tt in t1.css("div.interval01-list-cars-infor"):
                    einfo["subid"] = sid
                    einfo["subname"] = tt.css("a::text").extract_first()
                    einfo["spec"] = 'https:' + tt.css("a::attr(href)").extract_first()
                    tt2 = t2[j].css("div::text")
                    if tt2 is not None:
                        einfo["guide"] = ''.join(tt2.extract()).strip()
                        if einfo["guide"] is None or len(einfo["guide"]) == 0:
                            einfo["guide"] = t2[j].css("div span.guidance-price::text").extract_first()
                    yield einfo
                    sid += 1
                    j += 1
            i += 1
            self._idx += 1
        nextpage = response.css("a.page-item-next::attr(href)")
        if nextpage is not None:
            yield scrapy.Request(self._base + nextpage.extract_first(), callback = self.parse)

    def parse_detail(self, response):
        pass
