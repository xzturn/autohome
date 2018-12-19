# -*- coding: utf-8 -*-
import copy
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
        self._ceng = re.compile('能源类型：')
        self._cslow = re.compile('慢充时间：')
        self._cfast = re.compile('快充时间：')
        self._cbattary = re.compile('电池容量：')
        self._cfperc = re.compile('快充百分比：')
        self._cinsur = re.compile('整车质保：')
        self._csize = re.compile('车身尺寸：')

    def parse(self, response):
        clist = response.css("div.list-cont-main")
        dlist = response.css("div.intervalcont")
        for i in range(len(clist)):
            title = clist[i].css("div.main-title a")
            lever = clist[i].css("div.main-lever")
            leverl = lever.css("div.main-lever-left")
            leverr = lever.css("div.main-lever-right div")
            links = lever.css("div.main-lever-link a")
            einfo = AutohomeItem()
            einfo["id"] = self._idx
            self._idx += 1
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
            n = len(details)
            for k in range(n):
                t1 = details[k].css("div.interval01-list-cars")
                t2 = details[k].css("div.interval01-list-guidance")
                tt1 = t1.css("div.interval01-list-cars-infor")
                for j in range(len(tt1)):
                    einfo["subid"] = k * n + j
                    einfo["subname"] = tt1[j].css("a::text").extract_first()
                    einfo["spec"] = 'https:' + tt1[j].css("a::attr(href)").extract_first()
                    tt2 = t2[j].css("div::text")
                    if tt2 is not None:
                        einfo["guide"] = ''.join(tt2.extract()).strip()
                        if einfo["guide"] is None or len(einfo["guide"]) == 0:
                            einfo["guide"] = t2[j].css("div span.guidance-price::text").extract_first()
                    param = copy.deepcopy(einfo)
                    yield scrapy.Request(param["spec"], meta = {'item': param}, callback = self.parse_spec)
        nextpage = response.css("a.page-item-next::attr(href)")
        if nextpage is not None:
            yield scrapy.Request(self._base + nextpage.extract_first(), callback = self.parse)

    def parse_spec(self, response):
        einfo = copy.deepcopy(response.meta['item'])
        basic = response.css("div.spec-baseinfo ul.baseinfo-list li")
        for t in basic:
            key = t.css("::text").extract_first()
            if self._ceng.search(key) is not None:
                einfo["energy"] = t.css("span::text").extract_first()
            elif self._cmiles.search(key) is not None:
                einfo["endurance"] = t.css("span::text").extract_first()
            elif self._cslow.search(key) is not None:
                einfo["slow"] = t.css("span::text").extract_first()
            elif self._cfast.search(key) is not None:
                einfo["fast"] = t.css("span::text").extract_first()
            elif self._cbattary.search(key) is not None:
                einfo["battary"] = t.css("span::text").extract_first()
            elif self._cfperc.search(key) is not None:
                einfo["fastperc"] = t.css("span::text").extract_first()
            elif self._cinsur.search(key) is not None:
                einfo["insurance"] = t.css("span::text").extract_first()
            elif self._csize.search(key) is not None:
                einfo["size"] = t.css("span::text").extract_first()
        yield einfo
