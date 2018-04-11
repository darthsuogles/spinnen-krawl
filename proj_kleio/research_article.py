
import logging

class Article():
    """
    A class representing articles listed on Google Scholar.  The class
    provides basic dictionary-like behavior.
    """
    mandatory_fields = set(['title', 'author', 'id', 'year'])

    def __init__(self):
        self.attrs = {}

        ## Setup logging options
        FORMAT = '%(asctime)-15s %(message)s'
        logging.basicConfig(format=FORMAT)
        #logger = logging.getLogger('tcpserver')
        #logger.warning('Protocol problem: %s', 'connection reset', extra=d)
        self.logger = logging.getLogger('Article');


    def validate(self):
        #key_set = [k for (k,v) in self.attrs.iteritems() if v[0] != None]
        #key_set = set(key_set)
        return Article.mandatory_fields.issubset(self.attrs.keys())

    def __getitem__(self, key):
        if key in self.attrs:
            return self.attrs[key]
        return None

    def __setitem__(self, key, item):
        self.attrs[key] = item

    def __delitem__(self, key):
        if key in self.attrs:
            del self.attrs[key]

    def gen_custom_id(self, meta_fields):
        """
        Construct a CUSTOM_ID for the bibliography entry

        CUSTOM_ID := <SomeAuthor>_<Journal>_<Year>_<Titlet>
        """
        if 'id' in self.attrs:
            return self.attrs['id']

        title = meta_fields['title']
        authors = meta_fields['author']
        year = meta_fields['year']
        pub = None if 'publication' not in meta_fields else meta_fields['publication']

        end_words = set(['if', 'and', 'for', 'or', 'on', 'method'])

        author_rep = authors[0].split()[-1] # last name of the first author
        if type(title) == 'unicode':
            title = title.translate({ord(u':'): None}) # remove the colon
        elif type(title) == 'str':
            title = title.translate(None, ':')
        titlet = ''.join([wd[0].upper() for wd in title.split() if wd.lower() not in end_words])

        if not pub:
            custom_id = '_'.join([author_rep, year, titlet])
        else:
            custom_id = '_'.join([author_rep, pub, year, titlet])

        return custom_id


    def as_org_print(self):
        """
        Print in orgmode (>8.0) style

        Example:

        :PROPERTIES:
        :TITLE:    Expander graphs and their applications
        :BTYPE:    article
        :CUSTOM_ID: Hoory_BAMS2006_EGTASV
        :AUTHOR:   Hoory, Shlomo and Linial, Nathan and Wigderson, Avi
        :CITEULIKE-ARTICLE-ID: 1540252
        :CITEULIKE-LINKOUT-0: http://www.ams.org/bull/2006-43-04/S0273-0979-06-01126-8/home.html
        :DATE-ADDED: 2012-11-21 19:12:21 +0000
        :DATE-MODIFIED: 2012-11-21 19:12:50 +0000
        :JOURNAL:  Bull. Amer. Math. Soc.
        :KEYWORDS: algorithms, graph
        :PAGES:    439--561
        :POSTED-AT: 2007-08-07 13:02:09
        :YEAR:     2006
        :END:

        """
        # We will have to work with unicode here
        # In light of the bibtex support of orgmode in 8.2,
        # we modified some export options
        meta_fields = self.attrs # the paper
        title = meta_fields['title']
        custom_id = self.gen_custom_id( meta_fields )

        print("*** {}".format(title))
        print('    :PROPERTIES:')
        # Begin printing in orgmode conforming format
        print('    :TITLE: {}'.format(title))
        print('    :CUSTOM_ID: {}'.format(custom_id))
        print("    :AUTHOR: {}".format(', '.join(meta_fields['author'])))
        print("    :YEAR: {}".format(meta_fields['year']))

        for (k, v) in self.attrs.items():
            if k in Article.mandatory_fields:
                continue
            print("    :{key}: {val}".format(key=k.upper(), val=v))

        # Preset a local pdf link (orgmode)
        print('    :PDF: file:papers/' + custom_id + '.pdf')
        print('    :END:')

    def as_org_concise_print(self):
        """
        Print in orgmode (>8.0) style, with a more concise presentation.
        We ignore most unrelated fields. Focusing on a rendition of the article
        in orgmode setting, instead of bibtex relation.
        """
        # We will have to work with unicode here
        # In light of the bibtex support of orgmode in 8.2,
        # we modified some export options
        meta_fields = self.attrs # the paper
        title = meta_fields['title']
        custom_id = self.gen_custom_id(meta_fields)

        local_pdf_path = 'file:papers/{}.pdf'.format(custom_id)
        print("*** [[{}][{}]]".format(local_pdf_path, title))
        print('    :PROPERTIES:')
        # Begin printing in orgmode conforming format
        print('    :CUSTOM_ID: {}'.format(custom_id))
        print("    :AUTHOR: {}".format(', '.join(meta_fields['author'])))
        print("    :YEAR: {}".format(meta_fields['year']))

        # Preset a local pdf link (orgmode)
        print('    :END:')
