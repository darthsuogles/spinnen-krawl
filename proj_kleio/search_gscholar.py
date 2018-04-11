#!/usr/bin/env python3
"""
This module provides classes for querying Google Scholar and parsing
returned results.  It currently *only* processes the first results
page.  It is not a recursive crawler.
"""

# citeulike crawler
# https://github.com/mikexstudios/citeulike-parser

import optparse
import sys
import re
import requests
from bs4 import BeautifulSoup
import logging

from research_article import Article

class ScholarParser():
    """
    ScholarParser can parse HTML document strings obtained from Google
    Scholar. It invokes the handle_article() callback on each article
    that was parsed successfully.
    """
    SCHOLAR_SITE = 'http://scholar.google.com'

    def __init__(self, site=None):
        self.soup = None
        self.article = None
        self.site = site or self.SCHOLAR_SITE
        self.year_re = re.compile(r'\b(?:20|19)\d{2}\b')
        self.author_re = re.compile(r'\b(?:20|19)\d{2}\b')
        self.logger = logging.getLogger('ScholarParser')

    def handle_article(self, article):
        """ In this base class, the callback does nothing.
        """
        raise NotImplementedError

    def parse(self, html):
        """ Initiates parsing HTML content.
        Then each specific part will be parsed accordingly
        """
        self.soup = BeautifulSoup(html, "html.parser")
        for div in self.soup.find_all(
                lambda tag: tag.has_attr('class') and 'gs_r' in tag['class']):
            self._parse_article(div)

    def _parse_article(self, div):
        """ The function must be implemented by a derived class
        """
        raise NotImplementedError

    def _parse_links(self, span):
        for tag in span:
            if hasattr(tag, 'name'):
                continue
            if tag.name != 'a' or tag.get('href') == None:
                continue

            if tag.get('href').startswith('/scholar?cites'):
                if tag.has_attr('string') and tag.string.startswith('Cited by'):
                    self.article['num_citations'] = \
                        self._as_int(tag.string.split()[-1])
                self.article['url_citations'] = self._path2url(tag.get('href'))

            if tag.get('href').startswith('/scholar?cluster'):
                if tag.has_attr('string') and tag.string.startswith('All '):
                    self.article['num_versions'] = \
                        self._as_int(tag.string.split()[1])
                self.article['url_versions'] = self._path2url(tag.get('href'))

    def _as_int(self, obj):
        try:
            return int(obj)
        except ValueError:
            return None

    def _path2url(self, path):
        if path.startswith('http://'):
            return path
        if not path.startswith('/'):
            path = '/' + path
        return self.site + path


###########################################################################
# BEGIN of specific parser implementations
#   Google might occasionally change the page design.

class ScholarParser160307(ScholarParser):
    """
    Nothing really changed, yet we are looking for a more refined way
    to store all the information

    Structure of an paper entry
    <div class="gs_r">
      <div class="gs_ggs gs_fl"> actual links to the pdf (Find It @ ...)
      <div class="gs_ri">
        <div class="gs_rt"> title and (usually publisher) url
        <div class="gs_a"> year, author and google author link (h-index and so)
        <div class="gs_rs"> summary of the paper (shorter than the abstract)
        <div class="gs_fl"> "cited by #", related article, versions, web of science
      </div>
    </div>

    BibTex citation
    <a class="gs_citi" onclick="return gs_mrcf(this)" href="/scholar.bib?q=info:8mo784Vvp9YJ:scholar.google.com/&amp;output=citation&amp;scisig=AAGBfm0AAAAAUn1dLSUKQCyTNCLZeUPupKN0b_rQJtCY&amp;scisf=4&amp;hl=en">Import into BibTeX</a>
    """
    def _parse_article(self, div):
        self.article = Article()

        for tag in div:
            if not hasattr(tag, 'name'):
                continue

            # Everything is under this div
            if tag.name == 'div':
                self.logger.debug(tag.get('class'))
                if tag.get('class') == ['gs_ggs', 'gs_fl']:
                    self.logger.debug("parsing: div gs_ggs gs_fl")
                    self._parse_gs_ggs_gs_fl(tag)

                if 'gs_ri' in tag.get('class'):
                    if tag.a:
                        self.article['title'] = ''.join(tag.a.findAll(text=True))
                        self.article['url'] = self._path2url(tag.a['href'])

                    # Author and year
                    if tag.find('div', {'class': 'gs_a'}):
                        text = tag.find('div', {'class': 'gs_a'}).text
                        self.logger.debug(text)
                        author = list(map(str.strip,
                                          text
                                          .split("&")[0]
                                          .split("-")[0]
                                          .split(";")[0]
                                          .split(",")))
                        self.article['author'] = author if len(author) > 0 else "unknown"
                        year = self.year_re.findall(text)
                        self.article['year'] = year[0] if len(year) > 0 else "0000"

                    # "Where to find it" urls
                    if tag.find('div', {'class': 'gs_fl'}):
                        self._parse_links(tag.find('div', {'class': 'gs_fl'}))

        if self.article['title']:
            self.handle_article(self.article)

    def _parse_gs_ggs_gs_fl(self, div):
        """
        <div class="gs_ggs gs_fl"> actual links to the pdf (Find It @ ...)

        Retrieve a valid link with pdf

        Warning:
          1. This tag might not exist
          2. Even if it exists, a valid pdf link might not exist
        """
        assert div.get('class') == ['gs_ggs', 'gs_fl'], "class must be gs_ggs + gs_fl"
        self.logger.debug(div.findAll())
        return div
        for tag in div:
            if tag.name == 'div':
                self.logger.debug(tag)
                text = tag.findAll(text = True)
                self.logger.debug(text)
        return div

    def _parse_gs_a(self, div):
        """" <div class="gs_a"> year, author and google author link (h-index and so)
        """
        return div

    def _parse_gs_rt(self, div):
        """ <div class="gs_rt"> title and (usually publisher) url
        """
        return div

    def _parse_gs_fl(self, div):
        """ <div class="gs_fl"> "cited by #", related article, versions, web of science
        """
        return div

    def _parse_gs_rs(self, div):
        """ <div class="gs_rs"> summary of the paper (shorter than the abstract)
        """
        return div

# END of specific parser definitions
###########################################################################

# Use the latest parser
ScholarParserLatest = ScholarParser160307

class ScholarQuerier():
    """
    ScholarQuerier instances can conduct a search on Google Scholar
    with subsequent parsing of the resulting HTML content.  The
    articles found are collected in the articles member, a list of
    Article instances.
    """

    url_pref = 'http://scholar.google.com/scholar?q='

    UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/601.4.4 (KHTML, like Gecko) Version/9.0.3 Safari/601.4.4"

    url_params = {
        'btnG': 'Search',
        'as_subj': 'eng',
        'as_sdt': '1%2C31',
        'hl': 'en',
        'as_sdtp': '',
    }
    option_id = {'year_lo': 'as_ylo',
                 'year_hi': 'as_yhi',
                 'count': 'num',
                 'query': 'q',
                 'author': 'as_sauthors',
                 'where_published': 'as_publication'}

    class Parser(ScholarParserLatest):
        """
        A subclass of the latest parser implementation
        """
        def __init__(self, querier):
            super().__init__()
            self.querier = querier

        def handle_article(self, article):
            self.querier.articles.append(article)

    def __init__(self, options = []):
        self.articles = []
        self.parser = self.Parser(self)

        op_list = {}
        for op, val in options.items():
            if op not in self.option_id:
                print('Warning: unknown options {} ignored'.format(op))
                continue
            if op == 'count':
                val = min(val, 100) # cap the number of returned result

            val = str(val)
            if val:
                op_list[ self.option_id[op] ] = requests.utils.quote(val)

        print(op_list)
        self.url_params.update(op_list)

    def request(self, search_title):
        """ Issue a request to Google Scholar
        """
        url = self.url_pref + requests.utils.quote(search_title)
        self.req = requests.get(url,
                                params=self.url_params,
                                headers={'user-agent': self.UA})
        print('Query url: {url} => {stat}'.format(url=self.req.url, stat=self.req.status_code))

    def query(self, search_title):
        """
        This method initiates a query with subsequent parsing of the
        response.
        """
        self.request(search_title)
        self.parser.parse(self.req.content)
        return self.articles

def search_gscholar():
    usage_str = """
        scholar.py [options] <query string>

          A command-line interface to Google Scholar.
          Text output will show on the terminal screen.
        """

    fmt = optparse.IndentedHelpFormatter(max_help_position=50,
                                         width=100)
    parser = optparse.OptionParser(usage=usage_str, formatter=fmt)
    parser.add_option('-a', '--author',
                      help='Author name')
    parser.add_option('--csv', action='store_true',
                      help='Print article data in CSV format (separator is "|")')
    parser.add_option('--csv-header', action='store_true',
                      help='Like --csv, but print header line with column names')
    parser.add_option('--txt', action='store_true',
                      help='Print article data in text format')
    parser.add_option('-c', '--count', type='int',
                      help='Maximum number of results')
    parser.add_option('-y', '--year', type='int',
                      help = 'Search for articles published since year xxxx')
    parser.set_defaults(count=0, author='')
    options, args = parser.parse_args()

    if len(args) == 0:
        print('Usage: ' + usage_str)
        sys.exit(1)

    query = ' '.join(args)
    params = {'author': options.author,
              'count': options.count,
              'year_lo': options.year}
    querier = ScholarQuerier(params)
    articles = querier.query(query)

    if options.count > 0:
        articles = articles[:options.count]

    print('Number of articles retrieved: {}'.format(len(articles)))
    for art in articles:
        print("---------------------------------------")
        #art.as_org_print()
        art.as_org_concise_print()
        print("----------------------------\n")


# Testing
# test_search_title = "Short Text Understanding Through Lexical Semantic Analysis"
# qr = ScholarQuerier({'author': '', 'count': 0, 'year_lo':2010})
# qr.query(test_search_title)
# #soup = BeautifulSoup(qr.req.content, 'html.parser')
# #ss = soup.find_all(lambda tag: tag.has_attr('class') and 'gs_r' in tag['class'])
# qr.parser.parse(qr.req.content)

if __name__ == "__main__":
    search_gscholar()
