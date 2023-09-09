"""
Instructions:
    tested on:
        Python 3.7.9
        Additional packages: None
        OS: Ubuntu 20.04

    data provided in:
        dagopoly-py/storage/exogenous

    python alz/alz16.py
"""

import os
import sys
import math
import random
from collections import namedtuple
import heapq
import hashlib
import json
import re
import time

_adir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                     "dagopoly-py")
sys.path.append(_adir)

from dagopoly.micro.basics import *
from dagopoly.micro.emit import emit, add_emit_listener

Dagopoly().setConf(Config(
        isDebug=True,
        adir=os.path.join(_adir, "storage")))
def emit_listener(msg):
    print(msg)
add_emit_listener(emit_listener)

""" *************************************************************
    BEGIN Generic utilities that illustrate how the Dagopoly API 
    can provide reusable building blocks for query plans. """

def reservoir(xs,k,rand=random.Random(123)):
    i=0
    sample=[None]*k
    for x in xs: 
        j = rand.randrange(0,i+1)
        if i > 0 and i < k:
            sample[i]=sample[j]
        if j < k:
            sample[j] = x
        i+=1
    return sample[0:i]

@block("v1.0")
def block_reservoir(xs,k):
    return reservoir(xs.get(), k, rand=random.Random(123))

@block("v1.0")
def block_hist(xs):
    h={}
    for x in xs.get():
        c = h[x]+1 if x in h else 1
        h[x]=c
    return h.items()

"""
PushCounter:
    Counts a generator as it is being demanded so that after its results have been
    consumed, the count remains. """
class PushCounter():
    def __init__(self) -> None:
        self._c=0
        self._t0=time.time()

    def f(self, xs):
        for x in xs:
            self._c += 1
            yield x
    
    def get(self):
        return self._c
    
    def getTime(self):
        return time.time()-self._t0

def clear_screen():
    for i in range(10):
        print()

def display(xs, n, format=lambda x:x):
    pc = PushCounter()
    xsSamp = reservoir(pc.f(xs.get()), n)
    clear_screen()
    print("\nSampling {} of {} results ({:.3f} sec) for {}\n".format(n, pc.get(), pc.getTime(), xs.sig()))
    for x in xsSamp:
        print(format(x))
    print()

"""
display_top
    Technicaly, this is display_bottom, because it sorts in increasing
    order according to key, like sorted().  But display_bottom just sounds
    wrong. """
def display_top(xs, n, key=None, format=lambda x:x):
    pc = PushCounter()
    # xsLargest = nametime(xs.sig(), lambda: heapq.nsmallest(n, pc.f(xs.get()), key=key))
    xsLargest = heapq.nsmallest(n, pc.f(xs.get()), key=key)
    clear_screen()
    print("\nTop {} of {} results ({:.3f} sec) for {}\n".format(n, pc.get(), pc.getTime(), xs.sig()))
    for x in xsLargest:
        print(format(x))
    print()

""" 
top_n
    Technicaly, this is bottom_n, because it sorts in increasing
    order according to key, like sorted(). """
@block("v0.0.0")
def top_n(xs, n, key=None):
    return heapq.nsmallest(n, xs.get(), key=key)

class BlockFlatmap(CachableBlock):
    def __init__(self, v, fn, xs):
        self._v = v
        self._fn = fn
        self._xs = xs
    def sig(self):
        return compute_sig([self.__class__.__name__, self._v, self._fn.__name__], [self._xs])
    def get(self):
        emit(["info", "computing", self.__class__.__name__, self.sig()])
        for x in self._xs.get():
            for y in self._fn(x):
                yield y

class Sha1Block(CachableBlock):
    def __init__(self, v, rfile, sha1Expected):
        self._v = v
        self._rfile = rfile
        self._sha1Expected = sha1Expected

    def sig(self):
        return compute_sig([self.__class__.__name__, self._v, self._sha1Expected], [])
    
    def get(self):
        afile = os.path.join(Dagopoly().conf.adir, "exogenous", self._rfile)
        proc = subprocess.run(["sha1sum", afile], capture_output=True, encoding='utf-8')
        sha1 = proc.stdout[0:40]
        if sha1==self._sha1Expected:
            return ["dummy value"]
        else:
            raise Exception("{}:\nexpected {} but got sha1sum {}".format(self._rfile, self._sha1Expected, sha1))

class GuardBlock(Block):
    def __init__(self, blocks):
        if len(blocks)==1:
            raise Exception("GuardBlock: at least one block is required")
        self._blocks = blocks
    
    def sig(self):
        return compute_sig([self.__class__.__name__], self._blocks)

    def get(self):
        for block in self._blocks[0:-1]:
            sum(1 for _ in block.get())
        return self._blocks[-1].get()

def Sha1ExogenousTextBlock(v, relf, sha1):
    return GuardBlock([
        Sha1Block(v, relf, sha1).cached(),
        ExogenousTextBlock(v, relf)
    ])

""" ****************************************************************
    BEGIN - ostensible implementation of RTX-KG2c (KGX over TSV) """
class Node(namedtuple('Node', [
        'id',                # 0:UniProtKB:P49247
        'category',          # 1:biolink:NucleicAcidEntity|biolink:Gene|biolink:Polypeptide|biolink:Protein|biolink:MolecularEntity
        'name',              # 2:RPIA
        'iri',               # 3:https://identifiers.org/uniprot:P49247
        'description',       # 4:A protein that is a translation product of the human RPIA gene or a 1:1 ortholog thereof. // COMMENTS: Category=gene.
        'publications',      # 5:PMID:13373810|PMID:21269460|PMID:13295229|PMID:15489334|PMID:14988808|DOI:10.1074/mcp.o113.027870|DOI:10.1016/0378-1119(94)00901-4|PMID:14907726|DOI:10.1021/pr300630k|PMID:7758956
        'specific_category', # 6:biolink:Protein
        'equivalent_curies', # 7:NCBIGene:22934|PR:P49247|PathWhiz.ProteinComplex:4402|PathWhiz.ProteinComplex:8688|PathWhiz.ProteinComplex:9774|REACT:R-HSA-5660009|OMIM:180430|LOINC:MTHU054500|REACT:R-HSA-71304|UniProtKB:P49247|PR:000014186|ENSEMBL:ENSG00000153574|MGI:103254|UMLS:C1419625|HGNC:10297|KEGG.ENZYME:5.3.1.6|LOINC:LP201784-8|PathWhiz.ProteinComplex:483|PathWhiz.ProteinComplex:6704|PathWhiz.ProteinComplex:5545|UMLS:C0073262|PathWhiz.ProteinComplex:9341|PathWhiz.ProteinComplex:10212
        'all_names'          # 8:Rpia (mouse)|RPIA|RPIA gene|Genetic locus associated with RPIA|Ribose-5-phosphate isomerase|RPIA [cytosol]|RPIA A61V [cytosol]|RPIA (human)|ribose-5-phosphate isomerase|ribose-5-phosphate isomerase (human)
        ])):
    def ids(self):
        yield self.id
        for id in self.equivalent_curies.split("|"):
            yield id
    def categories(self):
        yield self.specific_category
        for c in self.category.split("|"):
            yield c
    def names(self):
        for c in self.all_names.split("|"):
            yield c
    @classmethod
    def parsable(cls, F):
        return isinstance(F,list) and len(F) == 9
    @classmethod
    def from_line(cls, line):
        F = line.split("\t")
        if Node.parsable(F):
            return [Node._make(F)]
        else:
            return []

class Edge(namedtuple('Edge', [
        'subject',           # 0:ORPHANET:444921
        'object',            # 1:UniProtKB:P49247
        'predicate',         # 2:biolink:close_match
        'knowledge_source',  # 3:infores:ordo
        'publications',      # 4:PMID:24894379
        'publications_info', # 5:{}
        'kg2_ids',           # 6:HGNC:10297---JensenLab:associated_with---DOID:0080699---JensenLab:
        'id'                 # 7:39012077
        #'isrev'              # Default false. Set to true to indicate that the biolink subject and object are reversed.
        ])):
    @classmethod
    def parsable(cls, F):
        return isinstance(F,list) and len(F) == 8
    @classmethod
    def from_line(cls, line):
        F = line.split("\t")
        if Edge.parsable(F):
            return [Edge._make(F)]
        else:
            return []

lines_rtxKg2cNodes = ExogenousTgzTextBlock("v7.6", "rtx-kg2c_7.6.tar.gz", 'nodes.tsv')
lines_rtxKg2cEdges = ExogenousTgzTextBlock("v7.6", "rtx-kg2c_7.6.tar.gz", 'edges.tsv')


""" *************************************************************
    BEGIN - graph sampling """

def hash_select(frac):
    (n,m) = frac
    hashfrac = "{:0>40}".format(hex(int((2**160-1)*n/m))[2:])  # [2:] - discard prefix "0x"
    def f(st):
        h = hashlib.sha1()
        h.update(st.encode("latin-1"))
        return h.hexdigest() <= hashfrac
    return f

@block("v0.0.1")
def edges_sampled_impl(es, fnSubj, fnObj, frac):
    f = hash_select(frac)
    for e in es.get():
        if f(fnSubj(e)) or f(fnObj(e)):
            yield e

@block("v0.0.1")
def nodeids_sampled(es, fnSubj, fnObj, frac):
    for e in edges_sampled_impl(es, fnSubj, fnObj, frac).get():
        yield fnSubj(e)
        yield fnObj(e)

@block("v0.0.1")
def nodes_sampled_impl(es, ns, fnNid, fnSubj, fnObj, frac):
    h=set()
    for id in nodeids_sampled(es, fnSubj, fnObj, frac).get():
        h.add(id)
    for n in ns.get():
        if fnNid(n) in h:
            yield n

def rat_gte(x,y):
    (a,b)=x
    (c,d)=y
    if b<0:
        (a,b)=(-a,-b)
    if d<0:
        (c,d)=(-c,-d)
    return a*d >= b*c

assert(rat_gte((1,1),(1,1))==True)
assert(rat_gte((1,-1),(1,1))==False)
assert(rat_gte((-1,1),(1,1))==False)
assert(rat_gte((-1,1),(-1,1))==True)
assert(rat_gte((-1,1),(1,-1))==True)
assert(rat_gte((-1,1),(-1,-1))==False)

def graph_sampled(ns, es, fnNid, fnSubj, fnObj, frac):
    if rat_gte(frac, (1,1)):  # >= 1/1
        return (ns, es)
    else:
        return (nodes_sampled_impl(es, ns, fnNid, fnSubj, fnObj, frac).cached(),
                edges_sampled_impl(es, fnSubj, fnObj, frac).cached())

frac=(1,10)  # 1/10 expressed as a ratio
frac=(1,1)
(kg2cNodes, kg2cEdges) = \
    graph_sampled(BlockFlatmap("v7.6.0.2", Node.from_line, lines_rtxKg2cNodes),
                  BlockFlatmap("v7.6.0.2", Edge.from_line, lines_rtxKg2cEdges),
                  lambda n: n.id, lambda e: e.subject, lambda e: e.object,
                  frac)

""" *************************************************************
    BEGIN - Alzheimer's Disease query """

predicates_up = set([
    'biolink:entity_positively_regulates_entity',
    'biolink:process_positively_regulates_process',
])
predicates_down = set([
    'biolink:entity_negatively_regulates_entity',
    'biolink:process_negatively_regulates_process',
])
predicates_other = set([
    'biolink:entity_regulates_entity',
    'biolink:process_regulates_process',
    'biolink:directly_interacts_with',
    'biolink:physically_interacts_with',
])
predicates_molecular = predicates_up.union(predicates_down).union(predicates_other)
@block("v0.0.2")
def interacts_molecularly(es):
    for e in es.get():
        if e.predicate in predicates_molecular:
            yield e

def intersects(xs, ys):
    for x in xs:
        if x in ys:
            return True
    return False

@block("v0.0.4")
def genes(ns):
    return (n for n in ns.get() if intersects(
        n.categories(), {'biolink:Gene'}))

def is_drug(n):
    if n is None:
        return False
    return intersects(n.categories(), 
        {'biolink:Drug', 'biolink:Vitamin'})

@block("v0.0.5")
def drugs(ns):
    return (n for n in ns.get() if is_drug(n))

# field-generic inner join,
# hashing the right side
@block("v0.0.0")
def inner_longleft(xs, keyX, ys, keyY):
    hY={}
    for y in ys.get():
        hY[keyY(y)] = y
    for x in xs.get():
        k = keyX(x)
        if k in hY:
            y = hY[k]
            yield (x,y)

# field-generic left outer join,
# hashing the right side
@block("v0.0.2")
def outer_longleft(xs, keyX, ys, keyY):
    hY={}
    for y in ys.get():
        hY[keyY(y)] = y
    for x in xs.get():
        k = keyX(x)
        y = hY[k] if k in hY else None
        yield (x,y)

# field-generic cogroup.  left side exactly once, right hand side zero or more.
@block("v0.0.0")
def cogroup_left(xs, keyX, valX, ys, keyY, valY):
    hXYS={}
    for x in xs.get():
        k = keyX(x)
        if not (k in hXYS):
            hXYS[k] = (valX(x), [])
    for y in ys.get():
        k = keyY(y)
        if k in hXYS:
            xys = hXYS[k]
            xys[1].append(valY(y))
            hXYS[k] = xys
    return ((k, x, ys) for (k, (x, ys)) in hXYS.items())

""" The stream of (edge, node) pairs targeting genes. """
drug2gene = inner_longleft(
               interacts_molecularly(kg2cEdges).cached(),
               lambda e: e.object,
               genes(kg2cNodes).cached(),
               lambda n: n.id)


# https://adsp.niagads.org/gvc-top-hits-list/
adspgeneLines = ExogenousTextBlock("v0", 'ADSP_table1_2023-06-22.tsv')
# adspgeneLines = Sha1ExogenousTextBlock("v0", 'ADSP_table1_2023-06-22.tsv',
#                                        '9e450ecd08d224e8ad7d07f003a0134fd5e59d91')

@block("v0.0.0")
def adspgeneFromLine(gvc):
    for (i,line) in enumerate(gvc.get()):
        if i>=2:
            F=line.split("\t")
            if len(F)==5:
                (num,chr,loc,snv,genename) = F
                yield genename

adspgene = adspgeneFromLine(adspgeneLines)

reHumanName=re.compile("([A-Z0-9\-]+) \(human\)")
def ncbi_id_name_from_gene(node):
    (ncbiid, gname) = (None,  None)
    for name2 in node.names():
        m = reHumanName.match(name2)
        if m:
            gname = m.group(1)
    for id2 in node.ids():
        if id2.startswith("NCBIGene:"):
            ncbiid = id2
    return [(node.id, ncbiid, gname)] \
        if ncbiid is not None and gname is not None \
        else []

ncbi_id_name = BlockFlatmap("v0.0.1", ncbi_id_name_from_gene, genes(kg2cNodes).cached())

gvcRich = outer_longleft(
    adspgene,
    lambda g: g,
    ncbi_id_name,
    lambda x: x[2]
)

gvcAsNcbi = BlockFlatmap("v0.0.1", 
                lambda r: [r[1][0]] if r[1] is not None else [],
                gvcRich)

# Identify Alzheimer's genes
drug2geneAlz = outer_longleft(
    drug2gene,
    lambda en: en[1].id,
    gvcAsNcbi,
    lambda x: x
)

def alzTfKey(en_y):
    ((e, n2), y) = en_y
    return [(e.subject, y is not None)]

""" 
Histogram for each substance, how many genes are and how many genes are not Alzheimer's related. """
alzhist = block_hist(BlockFlatmap("v0.0.3", alzTfKey, drug2geneAlz))

"""
Put the on-target and off-target counts side by side, as in a full outer join. """
@block("v0.0.0")
def align_histtf(xpn):
    hTrue = {}
    for ((x,p),n) in xpn.get():
        if p and n is not None:
            hTrue[x]=n
    for ((x,p),nFalse) in xpn.get():
        if not p and nFalse is not None:
            nTrue = hTrue[x] if x in hTrue else 0
            yield (x, nTrue, nFalse)

# alzhist with complete nodes
report1 = outer_longleft(
    align_histtf(alzhist),
    lambda x: x[0],
    kg2cNodes,
    lambda n: n.id
).cached()

# Name beautification - lower is better
def name_score(name):
    if len(name)<=2:                # protect against degenerate names
        return 100                  # 100 is bad
    cDigits = 0
    for i in range(len(name)):
        ch=name[i]
        if ch >= '0' and ch <= '9':
            cDigits += 1
    cNondigits = len(name)-cDigits  # "CANDOXATRIL" is preferred to "Uk 79300"
    return cNondigits+8*cDigits     # "Delta-Tocopherol" is preferred to "E309"

def best_name(n):
    if n is None:
        return None
    nameSm = n.name
    scoreSm = name_score(nameSm)
    for name in n.names():
        if name_score(name) < scoreSm:
            nameSm = name
            scoreSm = name_score(name)
    return nameSm

def best_name_or_empty(n):
    name = best_name(n)
    return name if name is not None else ''

@block("v0.0.0")
def just_drugs(xs):
    for ((id, i, j), n) in xs.get():
        if is_drug(n):
            yield (best_name_or_empty(n), id, i,j, n.specific_category)

def keyJustdrugs(x):
    (name, id, i, j, cat) = x
    return id

kLaplace=0.01  # Laplace Smoothing

kCv=0.1
def ordJustdrugs(row):
    (name, id, i, j, cat) = row[0:5]
    y = (i+kLaplace)/(j+kLaplace)
    cv = 1/math.sqrt(j+kLaplace)   # cv of the average of j coin flips
    #print("y={} i={} j={} cv={} kcvcv={} x={}".format(y,i,j,cv,kCv*cv, row))
    return -y*(1-kCv*cv)

numJustdrugs=20

reScrubTable = re.compile("CHEMBL.COMPOUND:") # too much space for table
def fmtLatexJustDrugs(row):
    (name, id, i, j, cat) = row
    id = reScrubTable.sub("",id)
    i_j = "{}/{}".format(i,j)
    return "{} \\\\".format(" & ".join([name, id, i_j]))

def alzEvidenceId(en_y):
    ((e, n2), y) = en_y
    return e.subject

def alzEvidenceValue(en_y):
    ((e, n2), y) = en_y
    return (e.predicate, e.object, y is not None, e.knowledge_source, e.publications, e.publications_info)

with_evidence = \
    cogroup_left(
        top_n(just_drugs(report1),
            numJustdrugs,
            ordJustdrugs),
        keyJustdrugs,
        lambda niijc: niijc,
        drug2geneAlz,
        alzEvidenceId,
        alzEvidenceValue
    )

def keyWithev(x):
    (id, (name, id, i, j, cat), es) = x
    return -(i+kLaplace)/(j+kLaplace)

display(adspgene, 3)

display(genes(kg2cNodes).cached(), 3)

display(drugs(kg2cNodes).cached(), 3)

display(interacts_molecularly(kg2cEdges).cached(), 3)

display_top(just_drugs(report1),
            10,
            key=ordJustdrugs,
            format=fmtLatexJustDrugs)

display_top(with_evidence, 
            1,
            key=keyWithev,
            format=json.dumps
)

