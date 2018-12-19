# -*- coding: utf-8 -*-

from scrapy import signals
from scrapy.exporters import CsvItemExporter

import time


class AutohomePipeline(object):
    def __init__(self):
        self.files = {}

    @classmethod
    def from_crawler(cls, crawler):
        pipeline = cls()
        crawler.signals.connect(pipeline.spider_opened, signals.spider_opened)
        crawler.signals.connect(pipeline.spider_closed, signals.spider_closed)
        return pipeline

    def spider_opened(self, spider):
        fp = open('{}.{}.csv'.format(spider.tag, time.strftime('%Y-%m-%d.%H%M%S', time.localtime())), 'w+b')
        self.files[spider] = fp
        self.exporter = CsvItemExporter(fp)
        self.exporter.start_exporting()

    def spider_closed(self, spider):
        self.exporter.finish_exporting()
        fp = self.files.pop(spider)
        fp.close()

    def process_item(self, item, spider):
        self.exporter.export_item(item)
        return item
